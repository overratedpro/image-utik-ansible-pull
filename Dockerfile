# syntax=docker/dockerfile:1.4

FROM --platform=$TARGETPLATFORM alpine:3.23

ARG repo_name

ENV GITHUB_REPO="${repo_name}"

RUN \
  apk add --update --no-cache \
    git \
    py3-pip \
    tini \
  && python3 -m pip install --upgrade --break-system-packages --root-user-action=ignore \
    ansible-core

COPY ./etc/crontab /etc/crontabs/root

COPY --chmod=0755 ./bin/git_askpass /bin/

ENV GITHUB_USER=git

ENV GIT_ASKPASS='/bin/git_askpass'

ENV GIT_TERMINAL_PROMPT='0'

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["crond", "-f", "-L", "/dev/stdout"]
