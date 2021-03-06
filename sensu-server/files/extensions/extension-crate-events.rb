#!/usr/bin/env ruby
#
# extension-crate-events
#
# DESCRIPTION:
#   Crate.IO Sensu extension that stores Sensu Events in Crate using the REST-API
#   Events will be buffered until they reach the configured buffer size or maximum age (buffer_size & buffer_max_age)
#
# OUTPUT:
#   event data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   0) Crate.IO destination table:
#      curl -vXPOST 127.0.0.1:4200/_sql?pretty -d '{"stmt":"CREATE TABLE IF NOT EXISTS sensu_events (source string, id string, ts timestamp, month timestamp GENERATED ALWAYS AS date_trunc('month', ts), action string, status string, occurrences integer, client object, check object, primary key(id,ts,month)) CLUSTERED BY (id) PARTITIONED BY (month) WITH(number_of_replicas = '2-4')"}'
#
#   1) Add the extension-crate-events.rb to the Sensu extensions folder (/etc/sensu/extensions)
#
#   2) Create the Sensu configuration for the extention inside the sensu config folder (/etc/sensu/conf.d)
#      echo '{ "crate-events": { "hostname": "127.0.0.1", "port": "4200", "table": "sensu_events" } }' >/etc/sensu/conf.d/crate_cfg.json
#      echo '{ "handlers": { "default": { "type": "set", "handlers": ["crate-events"] } } }' >/etc/sensu/conf.d/crate_handler.json
#
#
# NOTES:
#
# LICENSE:
#   Copyright 2016 Sebastian YEPES <syepes@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE for details.
#

require 'net/http'
require 'timeout'
require 'json'

module Sensu::Extension
  class CrateEvents < Handler

    @@extension_name = 'crate-events'

    def name
      @@extension_name
    end

    def description
      'Historization of Sensu Event in Crate.IO'
    end

    def post_init
      crate_config = settings[@@extension_name]
      validate_config(crate_config)

      hostname               = crate_config['hostname']
      port                   = crate_config['port'] || 4200
      @TABLE                 = crate_config['table']
      ssl                    = crate_config['ssl'] || false
      ssl_cert               = crate_config['ssl_cert']
      protocol               = if ssl then 'https' else 'http' end
      @SOURCE                = crate_config['source'] || 'sensu'
      @HTTP_COMPRESSION      = crate_config['http_compression'] || true
      @HTTP_TIMEOUT          = crate_config['http_timeout'] || 10 # seconds
      @BUFFER_SIZE           = crate_config['buffer_size'] || 1024
      @BUFFER_MAX_AGE        = crate_config['buffer_max_age'] || 300 # seconds
      @BUFFER_MAX_TRY        = crate_config['buffer_max_try'] || 6
      @BUFFER_MAX_TRY_DELAY  = crate_config['buffer_max_try_delay'] || 120 # seconds

      @URI = URI("#{protocol}://#{hostname}:#{port}/_sql")
      @HTTP = Net::HTTP::new(@URI.host, @URI.port)

      # To be implemented in Crate.IO
      if ssl
        @HTTP.ssl_version = :TLSv1
        @HTTP.use_ssl = true
        @HTTP.verify_mode = OpenSSL::SSL::VERIFY_PEER
        @HTTP.ca_file = ssl_cert
      end

      @BUFFER = []
      @BUFFER_TRY = 0
      @BUFFER_TRY_SENT = 0
      @BUFFER_FLUSHED = Time.now.to_i

      @logger.info("#{@@extension_name}: Successfully initialized: hostname: #{hostname}, port: #{port}, table: #{@TABLE}, uri: #{@URI.to_s}, http_compression: #{@HTTP_COMPRESSION}, http_timeout: #{@HTTP_TIMEOUT}:s, buffer_size: #{@BUFFER_SIZE}, buffer_max_age: #{@BUFFER_MAX_AGE}:s, buffer_max_try: #{@BUFFER_MAX_TRY}, buffer_max_try_delay: #{@BUFFER_MAX_TRY_DELAY}:s")
    end

    def run(event)
      begin
        event = JSON.parse(event)

        # Convert timestamps to ms as they are directly supported by Crate (https://crate.io/docs/reference/sql/data_types.html#timestamp)
        event['timestamp'] *= 1000
        event['client']['timestamp'] *= 1000 if event['client'].key?('timestamp')
        event['check']['issued'] *= 1000 if event['check'].key?('issued')
        event['check']['executed'] *= 1000 if event['check'].key?('executed')

        evt = {
          :source => @SOURCE,
          :id => event['id'],
          :ts => event['timestamp'],
          :action => event['action'],
          :status => event_status(event['check']['status']),
          :occurrences => event['occurrences'],
          :client => event['client'],
          :check => event['check']
        }
        @logger.debug("#{@@extension_name}: Event: #{evt[:action]} -> #{evt[:status]} - #{evt[:check]['output']})")

        @BUFFER.push(evt)
        @logger.info("#{@@extension_name}: Stored Event in buffer (#{@BUFFER.length}/#{@BUFFER_SIZE})")

        if buffer_try_delay? and (buffer_too_old? or buffer_too_big?)
          flush_buffer
        end

      rescue => e
        @logger.error("#{@@extension_name}: Unable to buffer Event: #{event} - #{e.message} - #{e.backtrace.to_s}")
      end

      yield("#{@@extension_name}: handler finished", 0)
    end

    def stop
      if !@BUFFER.nil? and @BUFFER.length > 0
        @logger.info("#{@@extension_name}: Flushing Event buffer before shutdown (#{@BUFFER.length}/#{@BUFFER_SIZE})")
        flush_buffer
      end
    end

    private
    def flush_buffer
      begin
        send_to_crate(@BUFFER)
        @BUFFER = []
        @BUFFER_TRY = 0
        @BUFFER_TRY_SENT = 0
        @BUFFER_FLUSHED = Time.now.to_i

      rescue Exception => e
        @BUFFER_TRY_SENT = Time.now.to_i
        if @BUFFER_TRY >= @BUFFER_MAX_TRY
          @BUFFER = []
          @logger.error("#{@@extension_name}: Maximum retries reached (#{@BUFFER_TRY}/#{@BUFFER_MAX_TRY}), All buffered Events have been lost!, #{e.message}")

        else
          @BUFFER_TRY +=1
          @logger.warn("#{@@extension_name}: Writing Event to Crate Failed (#{@BUFFER_TRY}/#{@BUFFER_MAX_TRY}), #{e.message}")
        end
      end
    end

    def send_to_crate(events)
      # TODO Refactor Ugly JSON workaround
      bulk = events.collect { |e|
        [e[:source], e[:id], e[:ts], e[:action], e[:status], e[:occurrences], e[:client].to_json.to_s.gsub(/"(\w+)"\s*:/, "\\1:").gsub(/[\\]/,""), e[:check].to_json.to_s.gsub(/"(\w+)"\s*:/, "\\1:").gsub(/[\\]/,"")]
      }

      data = {
        :stmt => "INSERT INTO #{@TABLE} (source, id, ts, action, status, occurrences, client, check) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        :bulk_args => bulk
      }

      headers = {'Content-Type' => 'application/json; charset=utf-8'}
      headers['Content-Encoding'] = 'gzip' if @HTTP_COMPRESSION

      request = Net::HTTP::Post.new(@URI.request_uri, headers)

      # Gzip compress
      if @HTTP_COMPRESSION
        compressed = StringIO.new
        gz_writer = Zlib::GzipWriter.new(compressed)
        gz_writer.write(data.to_json.to_s.gsub(/"(\w+)"\s*:/, "\\1:").gsub(/[\\]/,"").gsub(/"\{/, "{").gsub(/\}"/, "}"))
        gz_writer.close
        request.body = compressed.string
      else
        # TODO Refactor Ugly JSON workaround
        request.body = data.to_json.to_s.gsub(/"(\w+)"\s*:/, "\\1:").gsub(/[\\]/,"").gsub(/"\{/, "{").gsub(/\}"/, "}")
      end

      @logger.debug("#{@@extension_name}: Writing Event: #{request.body} to Crate: #{@URI.to_s}")

      Timeout::timeout(@HTTP_TIMEOUT) do
        ts_s = Time.now.to_i
        response = @HTTP.request(request)
        ts_e = Time.now.to_i
        if response.code.to_i != 200
          @logger.error("#{@@extension_name}: Writing Event to Crate: response code = #{response.code}, body = #{response.body}")
          raise "response code = #{response.code}"

        else
          @logger.info("#{@@extension_name}: Sent #{events.length} Events to Crate in (#{ts_e - ts_s}:s)")
          @logger.debug("#{@@extension_name}: Writing Event to Crate: response code = #{response.code}, body = #{response.body}")
        end
      end
    end


    # Establish a delay between retrie failures
    def buffer_try_delay?
      seconds = (Time.now.to_i - @BUFFER_TRY_SENT)
      if seconds < @BUFFER_MAX_TRY_DELAY
        @logger.warn("#{@@extension_name}: Waiting for (#{seconds}/#{@BUFFER_MAX_TRY_DELAY}) seconds before next retry") if ( ((@BUFFER_MAX_TRY_DELAY - seconds) % @BUFFER_MAX_TRY+1) == 0 )
        false

      else
        true
      end
    end

    # Send Event if buffer is to old
    def buffer_too_old?
      buffer_age = Time.now.to_i - @BUFFER_FLUSHED
      buffer_age >= @BUFFER_MAX_AGE
    end

    # Send Event if buffer is full
    def buffer_too_big?
      @BUFFER.length >= @BUFFER_SIZE
    end

    def event_status(status)
      case status
      when 0
        'Ok'
      when 1
        'Warning'
      when 2
        'Critical'
      else
        'Unknown'
      end
    end

    def validate_config(config)
      if config.nil?
        raise ArgumentError, "No configuration for #{@@extension_name} provided. exiting..."
      end

      ["hostname", "port", "table"].each do |required_setting|
        if config[required_setting].nil?
          raise ArgumentError, "Required setting #{required_setting} not provided to extension. this should be provided as json element with key '#{@@extension_name}'. exiting..."
        end
      end
    end

  end
end
