# Usage:
#
# docker build --force-rm -t sensu-api .
# docker run -d --name sensu-api -h sensu-api -e RABBITMQ_HOST=172.17.0.1,172.17.0.1,172.17.0.1 -e REDIS_HOST=172.17.0.1 sensu-api
# docker run \
#  -v ~/cert.pem:/etc/sensu/ssl/cert.pem (Optional) \
#  -v ~/key.pem:/etc/sensu/ssl/key.pem (Optional) \
#  -e RABBITMQ_HOST=rabbitmq \
#  -e RABBITMQ_PORT=5671 \
#  -e RABBITMQ_VHOST="/sensu" \
#  -e RABBITMQ_USER=sensu \
#  -e RABBITMQ_PASS=sensu \
#  sensu-api
#

FROM        centos:latest
MAINTAINER  Sebastian YEPES <syepes@gmail.com>


ENV         DOCKERIZE_VERSION=v0.2.0 \
            RABBITMQ_PORT=5671 \
            RABBITMQ_VHOST=/sensu \
            RABBITMQ_USER=sensu \
            RABBITMQ_PASS=sensu \
            REDIS_PORT=6379

# Basic packages & Locals & Create user
RUN         yum -y install epel-release.noarch initscripts \
            && localedef --no-archive -i en_US -f UTF-8 en_US.UTF-8 \
            && rm -f /etc/localtime && ln -s /usr/share/zoneinfo/UTC /etc/localtime \
            && echo 'ZONE="UTC"' > /etc/sysconfig/clock && echo 'UTC=True' >> /etc/sysconfig/clock \
            && yum -y update \
            && curl -sSL https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz | tar -xzv -C /usr/local/bin

# Sensu API & Uchiwa
COPY        files/sensu.repo /etc/yum.repos.d/

RUN         yum install -y sensu uchiwa \
            && mkdir -p /etc/sensu/ssl \
            && rm -rf /tmp/* \
            && yum clean all

COPY        files/uchiwa.json /etc/sensu/
COPY        files/ssl/* /etc/sensu/ssl/
COPY        files/*.sh /
RUN         chmod 755 /*.sh

EXPOSE      3000 4567
CMD         ["/run.sh"]

HEALTHCHECK --interval=10s --timeout=5s --retries=3 CMD curl --noproxy 127.0.0.1 -A Docker-HealthCheck -m 3 -w " - %{http_code}" -sS http://127.0.0.1:4567/info || exit 1

