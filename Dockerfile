# syntax=docker/dockerfile:1.4

FROM --platform=$TARGETPLATFORM debian:bookworm-slim AS builder

RUN \
  export DPKG_FRONTEND=noninteractive \
  && apt update \
  && apt install -y \
    g++ \
    gcc \
    libffi-dev \
    libssl-dev \
    pkg-config \
    python3-dev \
    python3-pip \
  && python3 -m pip install \
    --break-system-packages \
    --no-binary=:all: \
    --no-build-isolation \
    --no-cache-dir \
    --root-user-action=ignore \
    --upgrade \
    ansible


FROM --platform=$TARGETPLATFORM debian:bookworm-slim

ARG repo_name

ENV GITHUB_REPO="${repo_name}"

RUN \
  export DPKG_FRONTEND=noninteractive \
  && apt update \
  && apt install -y \
    cron \
    git \
    python3 \
    tini \
  && apt clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/python3.11/dist-packages /usr/local/lib/python3.11/dist-packages

COPY --from=builder /usr/local/bin/ansible* /usr/local/bin/

COPY ./etc/crontab /etc/crontabs/root

COPY --chmod=0755 ./bin/git_askpass /bin/

ENV GIT_ASKPASS='/bin/git_askpass'

ENV GIT_TERMINAL_PROMPT='0'

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["crond", "-f", "-L", "/dev/stdout"]
