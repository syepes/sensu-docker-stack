# Usage:
#
# docker build --force-rm -t influxdb .
# docker run -d --name influxdb -h influxdb -p 8083:8083 -p 8086:8086 influxdb
#

FROM       alpine:latest
MAINTAINER Sebastian YEPES <syepes@gmail.com>


ENV        LANG=en_US.UTF-8 \
           INFLUXDB_VERSION=1.0.0-beta3

RUN        apk add --no-cache --virtual build-deps curl tar tzdata \
           #&& curl -#SL https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}-static_linux_amd64.tar.gz | tar -xz -C / --strip-components 2 \
           && curl -#SL https://dl.influxdata.com/influxdb/nightlies/influxdb-static-nightly_linux_amd64.tar.gz | tar -xz -C / --strip-components 2 \
           && mkdir /etc/influxdb/ && mv /influxdb.conf /etc/influxdb/influxdb.conf.orig \
           && mv influx* /usr/bin/ \
           && rm -f /etc/localtime && ln -s /usr/share/zoneinfo/UTC /etc/localtime \
           && apk del build-deps \
           && rm -rf /var/cache/apk/*

COPY       files/influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE     8083 8086
VOLUME     ["/var/lib/influxdb"]
CMD        ["influxd"]

HEALTHCHECK --interval=15s --timeout=3s --retries=3 CMD wget -U Docker-HealthCheck -Y off -O /dev/null http://localhost:8086/ping || exit 1
