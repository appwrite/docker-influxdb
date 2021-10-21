FROM alpine:3.12

LABEL maintainer="team@appwrite.io"

RUN echo 'hosts: files dns' >> /etc/nsswitch.conf

RUN apk add --no-cache \
        tzdata \
        bash \
        ca-certificates && \
    rm -rf /var/cache/apk/* && \
    update-ca-certificates 2>/dev/null

ENV INFLUXDB_VERSION 1.8.10

RUN set -ex && \
    mkdir ~/.gnupg; \
    echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf; \
    apk add --no-cache --virtual .build-deps wget gnupg tar && \
    for key in \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 ; \
    do \
        # gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
        # gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        # gpg --keyserver keyserver.pgp.com --recv-keys "$key" ; \
        gpg --keyserver pgp.mit.edu --recv-keys "$key"; \
    done && \
    [ "$(uname -m)" = x86_64 ] && suffix="-static_linux_amd64.tar.gz" || suffix="_linux_armhf.tar.gz"; \
    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}${suffix}.asc && \
    wget --no-verbose https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}${suffix} && \
    gpg --batch --verify influxdb-${INFLUXDB_VERSION}${suffix}.asc influxdb-${INFLUXDB_VERSION}${suffix} && \
    mkdir -p /usr/src && \
    tar -C /usr/src -xzf influxdb-${INFLUXDB_VERSION}${suffix} && \
    cd /usr/src/influxdb-${INFLUXDB_VERSION}*; \
    [ -d etc ] && cp -R etc/* /etc; \
    [ -d usr ] && cp -R usr/* /usr; \
    [ -d var ] && cp -R var/* /var; \
    [ -f influxdb.conf ] && rm influxdb.conf && mv influx* /usr/bin; \
    find /usr/bin -name "influx*" -exec chmod +x {} \; && \
    gpgconf --kill all && \
    rm -rf influxdb* /usr/src /root/.gnupg && \
    apk del .build-deps

COPY influxdb.conf /etc/influxdb/influxdb.conf

VOLUME ["/var/lib/influxdb"]

COPY entrypoint.sh /entrypoint.sh
COPY init-influxdb.sh /init-influxdb.sh

RUN chmod +x /entrypoint.sh /init-influxdb.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]

EXPOSE 8086
