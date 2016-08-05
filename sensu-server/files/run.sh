#!/bin/sh

if [ -z "$CLIENT_NAME" ]; then
  CLIENT_NAME=`hostname`
fi

if [ -z "$CLIENT_ADDRESS" ]; then
  CLIENT_ADDRESS=`hostname --ip-address`
fi

if [ -z "$CLIENT_SUBSCRIPTIONS" ]; then
  echo "> \$CLIENT_SUBSCRIPTIONS must be provided"
  exit 1
fi

if [ -z "$RABBITMQ_HOST" ]; then
  echo "> \$RABBITMQ_HOST must be provided"
  exit 1
fi

if [ -z "$REDIS_HOST" ]; then
  echo "> \$REDIS_HOST must be provided"
  exit 1
fi

SUBSCRIPTIONS="`echo $CLIENT_SUBSCRIPTIONS|sed s/,/\\",\\"/g`"
RABBITMQ=(`echo $RABBITMQ_HOST | cut -d ","  --output-delimiter=" " -f 1-`)

if [ ${#RABBITMQ[@]} != 3 ]; then
  echo "> \$CLIENT_SUBSCRIPTIONS (${RABBITMQ[@]}) must have 3 RabbitMQ servers: rmq1,rmq2,irmq3"
  exit 1
fi

cat << EOF > /etc/sensu/config.json
{
  "client": {
    "name": "$CLIENT_NAME",
    "address": "$CLIENT_ADDRESS",
    "deregister": true,
    "subscriptions": ["$SUBSCRIPTIONS"],
    "keepalive": {
      "thresholds": {
        "warning": 60,
        "critical": 100
      },
    "refresh": 300
    }
  },
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
  }
}
EOF
echo EMBEDDED_RUBY=true >/etc/default/sensu
echo LOG_LEVEL=warn >>/etc/default/sensu
chown -R sensu /etc/sensu/


__stop() {
echo "> SIGTERM signal received, try to gracefully shutdown all services..."
/etc/init.d/sensu-server stop
}

trap "__stop; exit 0" SIGTERM SIGINT

echo "> Starting: Sensu"
/etc/init.d/sensu-server start
tail -f /var/log/sensu/sensu-server.log 2> /dev/null &

while true; do sleep 1000 & wait $!; done
echo echo "wait loop aborted..." #should not happen

