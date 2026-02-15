# syntax=docker/dockerfile:1.4

FROM --platform=$TARGETPLATFORM debian:bookworm-slim AS builder

ARG TARGETARCH

RUN \
  set -e -u \
  && export DPKG_FRONTEND=noninteractive \
  && apt update \
  && apt install -y \
    curl \
    g++ \
    gcc \
    libffi-dev \
    libssl-dev \
    pkg-config \
    python3-dev \
    python3-pip \
    python3-wheel \
  && if [ $TARGETARCH = "arm" ]; then \
    curl -sSf --tlsv1.2 \
      https://static.rust-lang.org/rustup/dist/arm-unknown-linux-gnueabi/rustup-init \
      >/tmp/rustup-init; \
    chmod +x /tmp/rustup-init; \
    /tmp/rustup-init \
      -y \
      --profile minimal \
      --default-host arm-unknown-linux-gnueabi \
      --default-toolchain \
      1.88.0; \
    . /root/.cargo/env; \
    python3 -m pip install \
      --break-system-packages \
      --no-cache-dir \
      --root-user-action=ignore \
      --upgrade \
      setuptools \
      setuptools-rust \
      packaging \
      pip \
      wheel; \
    python3 -m pip install \
      --break-system-packages \
      --no-binary=:all: \
      --no-cache-dir \
      --root-user-action=ignore \
      --upgrade \
      cffi \
      flit-core \
      maturin \
      puccinialin; \
  fi \
  && python3 -m pip install \
    --break-system-packages \
    $([ $TARGETARCH = "arm" ] && echo '--no-binary=:all:') \
    --no-build-isolation \
    --no-cache-dir \
    --root-user-action=ignore \
    --upgrade \
    ansible-core


FROM --platform=$TARGETPLATFORM debian:bookworm-slim

ARG repo_name

ENV GITHUB_REPO="${repo_name}"

ENV GITHUB_USER=git

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
