FROM golang:1-alpine AS build

ARG VERSION="1.0.0"
ARG CHECKSUM="c735f70119f492e1ae8e5438aff2de4c61a60fe3d1ab3dd3d35692fb2ccbfeaa"

ADD https://github.com/nginxinc/nginx-prometheus-exporter/archive/refs/tags/v$VERSION.tar.gz /tmp/nginx-prometheus-exporter.tar.gz

RUN [ "$(sha256sum /tmp/nginx-prometheus-exporter.tar.gz | awk '{print $1}')" = "$CHECKSUM" ] && \
    apk add ca-certificates curl make && \
    tar -C /tmp -xf /tmp/nginx-prometheus-exporter.tar.gz && \
    mkdir -p /go/src/github.com/nginxinc && \
    mv /tmp/nginx-prometheus-exporter-$VERSION /go/src/github.com/nginxinc/nginx-prometheus-exporter && \
    cd /go/src/github.com/nginxinc/nginx-prometheus-exporter && \
      make nginx-prometheus-exporter

RUN mkdir -p /rootfs/bin && \
      cp /go/src/github.com/nginxinc/nginx-prometheus-exporter/nginx-prometheus-exporter /rootfs/bin/ && \
    mkdir -p /rootfs/etc && \
      echo "nogroup:*:10000:nobody" > /rootfs/etc/group && \
      echo "nobody:*:10000:10000:::" > /rootfs/etc/passwd && \
    mkdir -p /rootfs/etc/ssl/certs && \
      cp /etc/ssl/certs/ca-certificates.crt /rootfs/etc/ssl/certs/


FROM scratch

COPY --from=build --chown=10000:10000 /rootfs /

USER 10000:10000
EXPOSE 9113/tcp
ENTRYPOINT ["/bin/nginx-prometheus-exporter"]
