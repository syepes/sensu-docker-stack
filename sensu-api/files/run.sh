#!/bin/sh

if [ -z "$RABBITMQ_HOST" ]; then
  echo "> \$RABBITMQ_HOST must be provided" 
  exit 1
fi

if [ -z "$REDIS_HOST" ]; then
  echo "> \$REDIS_HOST must be provided" 
  exit 1
fi

RABBITMQ=(`echo $RABBITMQ_HOST | cut -d ","  --output-delimiter=" " -f 1-`)

if [ ${#RABBITMQ[@]} != 3 ]; then
  echo "> \$CLIENT_SUBSCRIPTIONS (${RABBITMQ[@]}) must have 3 RabbitMQ servers: rmq1,rmq2,irmq3"
  exit 1
fi

cat << EOF > /etc/sensu/config.json
{
  "rabbitmq": [
    {
      "host": "${RABBITMQ[0]}",
      "port": $RABBITMQ_PORT,
      "vhost": "$RABBITMQ_VHOST",
      "user": "$RABBITMQ_USER",
      "password": "$RABBITMQ_PASS",
      "heartbeat": 30,
      "prefetch": 100,
      "ssl": {
        "cert_chain_file": "/etc/sensu/ssl/cert.pem",
        "private_key_file": "/etc/sensu/ssl/key.pem"
      }
    },
    {
      "host": "${RABBITMQ[1]}",
      "port": $RABBITMQ_PORT,
      "vhost": "$RABBITMQ_VHOST",
      "user": "$RABBITMQ_USER",
      "password": "$RABBITMQ_PASS",
      "heartbeat": 30,
      "prefetch": 100,
      "ssl": {
        "cert_chain_file": "/etc/sensu/ssl/cert.pem",
        "private_key_file": "/etc/sensu/ssl/key.pem"
      }
    },
    {
      "host": "${RABBITMQ[2]}",
      "port": $RABBITMQ_PORT,
      "vhost": "$RABBITMQ_VHOST",
      "user": "$RABBITMQ_USER",
      "password": "$RABBITMQ_PASS",
      "heartbeat": 30,
      "prefetch": 100,
      "ssl": {
        "cert_chain_file": "/etc/sensu/ssl/cert.pem",
        "private_key_file": "/etc/sensu/ssl/key.pem"
      }
    }
  ],
  "redis": {
    "host": "$REDIS_HOST",
    "port": $REDIS_PORT
  },
  "api": {
    "host": "localhost",
    "bind": "0.0.0.0",
    "port": 4567
  }
}
EOF
echo EMBEDDED_RUBY=true >/etc/default/sensu
echo LOG_LEVEL=warn >>/etc/default/sensu
chown -R sensu /etc/sensu/


__stop() {
echo "> SIGTERM signal received, try to gracefully shutdown all services..."
/etc/init.d/sensu-api stop
/etc/init.d/uchiwa stop
}

trap "__stop; exit 0" SIGTERM SIGINT

echo "> Starting: Sensu API"
/etc/init.d/sensu-api start
/etc/init.d/uchiwa start

tail -f /var/log/sensu/sensu-api.log 2> /dev/null &

while true; do
 sleep 15s & wait $!;
 ps -eo pid |egrep "^\s+$(cat /var/run/sensu/sensu-api.pid)\$" 1>/dev/null || exit 1;
 ps -eo pid |egrep "^\s+$(cat /var/run/uchiwa.pid)\$" 1>/dev/null || exit 1;
done

