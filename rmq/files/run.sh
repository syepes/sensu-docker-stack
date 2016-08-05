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
    #mkdir -p /opt || true
    # Create combined cert
    #cat ${SSL_CERT_FILE} ${SSL_KEY_FILE} > /opt/combined.pem
    #chmod 0400 /opt/combined.pem

    # More ENV vars for make clustering happiness we don't handle clustering in this script, but these args should ensure
    # clustered SSL-enabled members will talk nicely
    #export ERL_SSL_PATH="/usr/lib/erlang/lib/ssl-7.1/ebin"
    #export RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="-pa ${ERL_SSL_PATH} -proto_dist inet_tls -ssl_dist_opt server_certfile /opt/combined.pem -ssl_dist_opt server_secure_renegotiate true client_secure_renegotiate true"
    #export RABBITMQ_CTL_ERL_ARGS="-pa ${ERL_SSL_PATH} -proto_dist inet_tls -ssl_dist_opt server_certfile /opt/combined.pem -ssl_dist_opt server_secure_renegotiate true client_secure_renegotiate true"

    echo "> Launching RabbitMQ+SSL"
    echo -e " - SSL_CERT_FILE: $SSL_CERT_FILE\n - SSL_KEY_FILE: $SSL_KEY_FILE\n - SSL_CA_FILE: $SSL_CA_FILE"
    cp -f ${RABBITMQ_HOME}/etc/rabbitmq/ssl.config ${RABBITMQ_HOME}/etc/rabbitmq/rabbitmq.config
else
    echo "> Launching RabbitMQ"
    cp -f ${RABBITMQ_HOME}/etc/rabbitmq/standard.config ${RABBITMQ_HOME}/etc/rabbitmq/rabbitmq.config
fi


if [ -z "$CLUSTER_WITH" -o "$CLUSTER_WITH" = "$(hostname)" ]; then
  echo "> Running as single server"
  rabbitmq-server &
else
  echo "> Running as clustered server"
  rabbitmq-server -detached
  rabbitmqctl stop_app

  echo "> Joining cluster $CLUSTER_WITH"
  rabbitmqctl join_cluster ${RAM_NODE:+--ram} $RABBITMQ_NODENAME@$CLUSTER_WITH

  rabbitmqctl start_app
fi

# Capture the PID
rmq_pid=$!

# Tail the logs, but continue on to the wait command
echo "> Tailing log output:"
tail -F ${RABBITMQ_HOME}/var/log/rabbitmq/rabbit@${HOSTNAME}.log \
     -F ${RABBITMQ_HOME}/var/log/rabbitmq/rabbit@${HOSTNAME}-sasl.log 2> /dev/null &

# If RMQ dies, this script dies
wait $rmq_pid 2> /dev/null
