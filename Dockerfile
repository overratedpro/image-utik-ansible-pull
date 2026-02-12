# syntax=docker/dockerfile:1.4

FROM debian:bookworm-slim

ARG TARGETARCH
ARG TARGETVARIANT

ARG repo_name

ENV GITHUB_REPO="${repo_name}"

RUN \
  echo "**** build on ${TARGETARCH}/${TARGETVARIANT} ****" \
  && export DPKG_FRONTEND=noninteractive \
  && apt update \
  && apt install -y \
    g++ \
    gcc \
    git \
    $([ $TARGETARCH = "arm" ] && [ $TARGETVARIANT = "v5" ] && echo "libc6") \
    libffi-dev \
    python3-dev \
    python3-pip \
    tini \
  && _PYTHON_HOST_PLATFORM="linux-$(dpkg --print-architecture)" \
  python3 -m pip install --upgrade --break-system-packages --root-user-action=ignore \
    ansible

COPY ./etc/crontab /etc/crontabs/root

COPY --chmod=0755 ./bin/git_askpass /bin/

ENV GIT_ASKPASS='/bin/git_askpass'

ENV GIT_TERMINAL_PROMPT='0'

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["crond", "-f", "-L", "/dev/stdout"]
