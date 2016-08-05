# Usage:
#
# docker build --force-rm -t sensu-client .
# docker run -d --name sensu-client1 -h sensu-client1 -e CLIENT_SUBSCRIPTIONS=metrics_os -e RABBITMQ_HOST=172.17.0.1 sensu-client
# docker run \
#  -v ~/cert.pem:/etc/sensu/ssl/cert.pem (Optional) \
#  -v ~/key.pem:/etc/sensu/ssl/key.pem (Optional) \
#  -e CLIENT_NAME=sensu-client (Optional) \
#  -e CLIENT_ADDRESS=10.0.0.1 (Optional) \
#  -e CLIENT_SUBSCRIPTIONS=os,metrics \
#  -e RABBITMQ_HOST=rabbitmq \
#  -e RABBITMQ_PORT=5671 \
#  -e RABBITMQ_VHOST="/sensu" \
#  -e RABBITMQ_USER=sensu \
#  -e RABBITMQ_PASS=sensu \
#  sensu-client

FROM       centos:latest
MAINTAINER Sebastian YEPES <syepes@gmail.com>


ENV        DOCKERIZE_VERSION=v0.2.0 \
           RABBITMQ_PORT=5671 \
           RABBITMQ_VHOST=/sensu \
           RABBITMQ_USER=sensu \
           RABBITMQ_PASS=sensu

# Basic packages & Locals & Create user
RUN        yum -y install epel-release.noarch initscripts make gcc-c++ \
           && localedef --no-archive -i en_US -f UTF-8 en_US.UTF-8 \
           && rm -f /etc/localtime && ln -s /usr/share/zoneinfo/UTC /etc/localtime \
           && echo 'ZONE="UTC"' > /etc/sysconfig/clock && echo 'UTC=True' >> /etc/sysconfig/clock \
           && yum -y update \
           && curl -sSL https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz | tar -xzv -C /usr/local/bin

# Sensu client
COPY       files/sensu.repo /etc/yum.repos.d/

RUN        yum install -y sensu \
           && mkdir -p /etc/sensu/ssl/ \
           && sensu-install -P cpu-checks,load-checks,disk-checks,filesystem-checks,process-checks,memory-checks,network-checks,docker,rabbitmq,redis,elasticsearch \
           && /opt/sensu/embedded/bin/gem install rest-client \
           && rm -rf /tmp/* \
           && yum clean all

COPY       files/ssl/* /etc/sensu/ssl/
COPY       files/*.sh /
RUN        chmod 755 /*.sh

EXPOSE     3030
ENTRYPOINT ["/run.sh"]

HEALTHCHECK --interval=1m --timeout=3s --retries=3 CMD ps -e |grep sensu-client || exit 1
