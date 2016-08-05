#!/bin/sh
set -e

# When this exits, exit all back ground process also.
trap 'kill $(jobs -p) 2> /dev/null' SIGTERM SIGINT EXIT


RABBITMQ_NODENAME=${RABBITMQ_NODENAME:-rabbit}

# Set ERLANG_COOKIE
if [ "$ERLANG_COOKIE" ]; then
    cookieFile='/root/.erlang.cookie'
    echo "$ERLANG_COOKIE" > "$cookieFile"
    chmod 600 "$cookieFile"
    chown root "$cookieFile"
fi


# If long & short hostnames are not the same, use long hostnames
if ! [[ "$(hostname)" == "$(hostname -s)" ]]; then
    export RABBITMQ_USE_LONGNAME=true
fi

if [[ -f ${RABBITMQ_HOME}/etc/rabbitmq/cert.pem ]]; then
    use_ssl="yes"
    SSL_CERT_FILE=${RABBITMQ_HOME}/etc/rabbitmq/cert.pem
    sed -i "s,CERTFILE,$SSL_CERT_FILE,g" ${RABBITMQ_HOME}/etc/rabbitmq/ssl.config
fi

if [[ -f ${RABBITMQ_HOME}/etc/rabbitmq/key.pem ]]; then
    use_ssl="yes"
    SSL_KEY_FILE=${RABBITMQ_HOME}/etc/rabbitmq/key.pem
    sed -i "s,KEYFILE,$SSL_KEY_FILE,g" ${RABBITMQ_HOME}/etc/rabbitmq/ssl.config
fi

if [[ -f ${RABBITMQ_HOME}/etc/rabbitmq/cacert.pem ]]; then
    use_ssl="yes"
    SSL_CA_FILE=${RABBITMQ_HOME}/etc/rabbitmq/cacert.pem
    sed -i "s,CAFILE,$SSL_CA_FILE,g" ${RABBITMQ_HOME}/etc/rabbitmq/ssl.config
fi

if [[ "${use_ssl}" == "yes" ]]; then
    echo "> Setup RabbitMQ+SSL"
    echo -e " - SSL_CERT_FILE: $SSL_CERT_FILE\n - SSL_KEY_FILE: $SSL_KEY_FILE\n - SSL_CA_FILE: $SSL_CA_FILE"
    cp -f ${RABBITMQ_HOME}/etc/rabbitmq/ssl.config ${RABBITMQ_HOME}/etc/rabbitmq/rabbitmq.config
else
    echo "> Setup RabbitMQ"
    cp -f ${RABBITMQ_HOME}/etc/rabbitmq/standard.config ${RABBITMQ_HOME}/etc/rabbitmq/rabbitmq.config
fi

echo "> Launching server"
rabbitmq-server &

# Capture the PID
rmq_pid=$!

# Tail the logs, but continue on to the wait command
echo "> Tailing log output:"
tail -F ${RABBITMQ_HOME}/var/log/rabbitmq/rabbit@${HOSTNAME}.log \
     -F ${RABBITMQ_HOME}/var/log/rabbitmq/rabbit@${HOSTNAME}-sasl.log 2> /dev/null &

# If RMQ dies, this script dies
wait $rmq_pid 2> /dev/null
