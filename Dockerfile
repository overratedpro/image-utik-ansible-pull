# syntax=docker/dockerfile:1.4

FROM alpine:3.23

RUN \
  apk add --update --no-cache --break-system-packages \
    py3-pip \
  && python3 -m pip install --upgrade \
    ansible

