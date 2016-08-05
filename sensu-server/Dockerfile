# Usage:
#
# docker build --force-rm -t sensu-server .
# docker run -d --name sensu-server -h sensu-server -e CLIENT_SUBSCRIPTIONS=metrics_os -e RABBITMQ_HOST=172.17.0.1 -e REDIS_HOST=172.17.0.1 sensu-server
# docker run \
#  -v ~/cert.pem:/etc/sensu/ssl/cert.pem (Optional) \
#  -v ~/key.pem:/etc/sensu/ssl/key.pem (Optional) \
#  -e CLIENT_NAME=sensu-server (Optional) \
#  -e CLIENT_ADDRESS=10.0.0.1 (Optional) \
#  -e CLIENT_SUBSCRIPTIONS=metrics_os \
#  -e RABBITMQ_HOST=rabbitmq \
#  -e RABBITMQ_PORT=5671 \
#  -e RABBITMQ_VHOST="/sensu" \
#  -e RABBITMQ_USER=sensu \
#  -e RABBITMQ_PASS=sensu \
#  sensu-server
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
RUN         yum -y install epel-release.noarch initscripts make gcc-c++ \
            && localedef --no-archive -i en_US -f UTF-8 en_US.UTF-8 \
            && rm -f /etc/localtime && ln -s /usr/share/zoneinfo/UTC /etc/localtime \
            && echo 'ZONE="UTC"' > /etc/sysconfig/clock && echo 'UTC=True' >> /etc/sysconfig/clock \
            && yum -y update \
            && curl -sSL https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz | tar -xzv -C /usr/local/bin

# Sensu server
COPY        files/sensu.repo /etc/yum.repos.d/

RUN         yum install -y sensu \
            && mkdir -p /etc/sensu/ssl \
            && sensu-install -P cpu-checks,load-checks,disk-checks,filesystem-checks,process-checks,memory-checks,network-checks,docker,sensu,rabbitmq,redis,elasticsearch \
            && /opt/sensu/embedded/bin/gem install rest-client \
            && rm -rf /tmp/* \
            && yum clean all

COPY        files/ssl/* /etc/sensu/ssl/
COPY        files/conf.d/* /etc/sensu/conf.d/
COPY        files/extensions/* /etc/sensu/extensions/
COPY        files/*.sh /
RUN         chmod 755 /*.sh

CMD         ["/run.sh"]

HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ps -p $(cat /var/run/sensu/sensu-server.pid) || exit 1


