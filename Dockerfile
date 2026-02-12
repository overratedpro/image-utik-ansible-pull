# syntax=docker/dockerfile:1.4

FROM debian:bookworm-slim

ARG TARGETARCH

ARG repo_name

ENV GITHUB_REPO="${repo_name}"

RUN \
  echo "**** build on ${TARGETARCH} ****" \
  && export DPKG_FRONTEND=noninteractive \
  && apt update \
  && apt install -y \
    g++ \
    gcc \
    git \
    $([[ $TARGETARCH -eq "arm" ]] && echo "libc") \
    libffi-dev \
    python3-dev \
    python3-pip \
    tini \
  && python3 -m pip install --upgrade --break-system-packages --root-user-action=ignore \
    ansible

COPY ./etc/crontab /etc/crontabs/root

COPY --chmod=0755 ./bin/git_askpass /bin/

ENV GIT_ASKPASS='/bin/git_askpass'

ENV GIT_TERMINAL_PROMPT='0'

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["crond", "-f", "-L", "/dev/stdout"]
