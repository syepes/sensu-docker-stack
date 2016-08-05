# Usage:
#
# docker build --force-rm -t rmq .
# docker run \
#  -e ERLANG_COOKIE=12345 \
#  -e CLUSTER_WITH=rmq1 (Optional) \
#  -e RAM_NODE=true (Optional) \
#  rmq
#

FROM       alpine:latest
MAINTAINER Sebastian YEPES <syepes@gmail.com>


ENV        LANG=en_US.UTF-8 \
           RABBITMQ_VERSION=3.6.4 \
           RABBITMQ_HOME=/rabbitmq \
           PLUGINS_DIR=/rabbitmq/plugins \
           ENABLED_PLUGINS_FILE=/rabbitmq/etc/rabbitmq/enabled_plugins \
           RABBITMQ_MNESIA_BASE=/var/lib/rabbitmq
ENV        PATH=$PATH:$RABBITMQ_HOME/sbin

RUN        apk add --no-cache --virtual build-deps curl tar xz tzdata \
           && rm -f /etc/localtime && ln -s /usr/share/zoneinfo/UTC /etc/localtime \
#           && echo "http://dl-4.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
#           && echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
           && apk add --no-cache openssl erlang erlang-mnesia erlang-public-key erlang-crypto erlang-ssl erlang-sasl erlang-asn1 \
                  erlang-inets erlang-os-mon erlang-xmerl erlang-eldap erlang-syntax-tools \
           && mkdir /rabbitmq \
           && curl -#SL https://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz | tar -xJ -C /rabbitmq --strip-components 1 \
           && rm -rf /share/**/rabbitmq*.xz \
           && rabbitmq-plugins enable --offline rabbitmq_management \
           && rabbitmq-plugins enable --offline rabbitmq_management_visualiser \
           && rabbitmq-plugins enable --offline rabbitmq_top \
           && apk del build-deps && rm -Rf /var/cache/apk/* && rm -f /root/.erlang.cookie

COPY       files/ssl.config /rabbitmq/etc/rabbitmq/
COPY       files/standard.config /rabbitmq/etc/rabbitmq/
COPY       files/rabbitmq_definitions.json /rabbitmq/etc/rabbitmq/
COPY       files/ssl/* /rabbitmq/etc/rabbitmq/
COPY       files/*.sh /
RUN        chmod 755 /*.sh

EXPOSE     5671/tcp 5672/tcp 15671/tcp 15672/tcp
VOLUME     ["/var/lib/rabbitmq"]
CMD        ["/run.sh"]

HEALTHCHECK --interval=1m --timeout=6s --retries=3 CMD rabbitmqctl -q -t 5 node_health_check || exit 1

