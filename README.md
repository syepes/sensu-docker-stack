# Sensu Full Stack Docker Environment

## Setup
- Create and install the SSL certs and build images

  `ssl_certs.sh` Auto Generate Self-Signed the certs

  `ssl_certs_install.sh` Copy the certs to the corresponding containers

  `docker-compose build` Build images

## Usage

### Full Stack (InfluxDB and Crate)

- Start Docker containers

  `docker-compose up -d`

- Config InfluxDB

  `docker exec sensu-server sh -c "curl -vXPOST influxdb:8086/query?pretty=true --data-urlencode 'q=CREATE DATABASE sensu_metrics'"`

  `docker exec sensu-server sh -c "curl -vXPOST influxdb:8086/query?pretty=true --data-urlencode 'q=CREATE RETENTION POLICY raw ON sensu_metrics DURATION 1w REPLICATION 1 DEFAULT'"`

  `docker exec sensu-server sh -c "curl -vXPOST influxdb:8086/query?pretty=true --data-urlencode 'q=CREATE RETENTION POLICY h5m ON sensu_metrics DURATION 106w REPLICATION 1'"`

  `docker exec sensu-server sh -c "curl -vXPOST influxdb:8086/query?pretty=true --data-urlencode 'q=CREATE CONTINUOUS QUERY metrics_5m ON sensu_metrics BEGIN SELECT max(value) AS "max", min(value) AS "min", mean(value) AS "mean", median(value) AS "median", sum(value) AS "sum", percentile(value, 90.000) AS "pct90", percentile(value, 95.000) AS "pct95", stddev(value) AS "stddev", count(value) AS "cnt" INTO "h5m".:MEASUREMENT FROM "raw"./.*/ GROUP BY time(5m), "host" END'"`

  `docker exec sensu-server sh -c "curl -vXPOST influxdb:8086/query?pretty=true --data-urlencode 'q=CREATE DATABASE sensu_events'"`

  `docker exec sensu-server sh -c "curl -vXPOST influxdb:8086/query?pretty=true --data-urlencode 'q=CREATE RETENTION POLICY raw ON sensu_events DURATION 8w REPLICATION 1 DEFAULT'"`


- Config Crate

  `docker exec sensu-server sh -c "curl -vXPOST crate1:4200/_sql?pretty -d '{"stmt":"CREATE TABLE IF NOT EXISTS sensu_events (source string, id string, ts timestamp, month timestamp GENERATED ALWAYS AS date_trunc('month', ts), action string, status string, occurrences integer, client object, check object, primary key(id,ts,month)) CLUSTERED BY (id) PARTITIONED BY (month) WITH(number_of_replicas = '2-4')"}'"`

  `docker exec sensu-server sh -c "curl -vXPOST crate1:4200/_sql?pretty -d '{"stmt":"CREATE TABLE IF NOT EXISTS sensu_metrics (source string, client string, client_info object, interval int, issued timestamp, executed timestamp, received timestamp, duration float, metric string, key string, val float, ts timestamp, day timestamp GENERATED ALWAYS AS date_trunc('day', ts), primary key(client,key,ts,day)) CLUSTERED BY (key) PARTITIONED BY (day) WITH(number_of_replicas = '2-4')"}'"`



### Minimal Stack (Only Sensu)

- Start Docker containers

  `docker-compose -f docker-compose_min.yml up -d`


### Management URLs:

  Sensu Uchiwa: [http://localhost:3000](http://localhost:3000)

  RabbitMQ: [http://localhost:15672](http://localhost:15672), [http://localhost:15673](http://localhost:15673), [http://localhost:15674](http://localhost:15674)

  Crate.IO: [http://localhost:4200/admin](http://localhost:4200/admin)

  InfluxDB: [http://localhost:8083](http://localhost:8083)

