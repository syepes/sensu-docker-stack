# Usage:
#
# docker build --force-rm -t rmq .
# docker run -d --name rmq1 -h rmq1 -p 5671:5671 -p 15672:15672 -e ERLANG_COOKIE=12345 rmq
#

FROM       alpine:latest
MAINTAINER Sebastian YEPES <syepes@gmail.com>


ENV        LANG=en_US.UTF-8 \
           RABBITMQ_VERSION=3.6.4 \
           RABBITMQ_CLUSTERER_VERSION=3.6.x-667f92b0 \
           RABBITMQ_MGMT_VERSION=3.6.x-4c38c777 \
           RABBITMQ_HOME=/rabbitmq \
           RABBITMQ_PLUGINS_DIR=/rabbitmq/plugins \
           RABBITMQ_ENABLED_PLUGINS_FILE=/rabbitmq/etc/rabbitmq/enabled_plugins \
           RABBITMQ_MNESIA_BASE=/var/lib/rabbitmq \
           RABBITMQ_BOOT_MODULE=rabbit_clusterer
ENV        PATH=$PATH:$RABBITMQ_HOME/sbin \
           RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="-pa ${RABBITMQ_PLUGINS_DIR}/rabbitmq_clusterer.ez/rabbitmq_clusterer-${RABBITMQ_CLUSTERER_VERSION}/ebin"

RUN        apk add --no-cache --virtual build-deps curl tar xz tzdata \
           && rm -f /etc/localtime && ln -s /usr/share/zoneinfo/UTC /etc/localtime \
#           && echo "http://dl-4.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
#           && echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
           && apk add --no-cache openssl erlang erlang-mnesia erlang-public-key erlang-crypto erlang-ssl erlang-sasl erlang-asn1 \
                  erlang-inets erlang-os-mon erlang-xmerl erlang-eldap erlang-syntax-tools \
           && mkdir -p ${RABBITMQ_PLUGINS_DIR} \
           && curl -#SL -o ${RABBITMQ_PLUGINS_DIR}/rabbitmq_management_themes.ez https://www.rabbitmq.com/community-plugins/v3.6.x/rabbitmq_management_themes-${RABBITMQ_MGMT_VERSION}.ez \
           && curl -#SL -o ${RABBITMQ_PLUGINS_DIR}/rabbitmq_clusterer.ez https://www.rabbitmq.com/community-plugins/v3.6.x/rabbitmq_clusterer-${RABBITMQ_CLUSTERER_VERSION}.ez \
           && curl -#SL https://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz | tar -xJ -C /rabbitmq --strip-components 1 \
           && rm -rf /share/**/rabbitmq*.xz \
           && rabbitmq-plugins enable --offline rabbitmq_clusterer rabbitmq_management rabbitmq_management_visualiser rabbitmq_top rabbitmq_management_themes \
           && apk del build-deps && rm -Rf /var/cache/apk/* && rm -f /root/.erlang.cookie

COPY       files/ssl.config /rabbitmq/etc/rabbitmq/
COPY       files/standard.config /rabbitmq/etc/rabbitmq/
COPY       files/rabbitmq_definitions.json /rabbitmq/etc/rabbitmq/
COPY       files/cluster.config /rabbitmq/etc/rabbitmq/
COPY       files/ssl/* /rabbitmq/etc/rabbitmq/
COPY       files/*.sh /
RUN        chmod 755 /*.sh

EXPOSE     5671/tcp 5672/tcp 15671/tcp 15672/tcp
VOLUME     ["/var/lib/rabbitmq"]
CMD        ["/run.sh"]

HEALTHCHECK --interval=15s --timeout=6s --retries=3 CMD rabbitmqctl -q -t 4 node_health_check || exit 1

