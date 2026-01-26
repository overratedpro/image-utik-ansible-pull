# syntax=docker/dockerfile:1.4

FROM alpine:3.23

RUN \
  apk add --update --no-cache \
    py3-pip \
    tini \
  && python3 -m pip install --upgrade --break-system-packages --root-user-action=ignore \
    ansible

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["crond", "-f", "-L", "/dev/stdout"]
