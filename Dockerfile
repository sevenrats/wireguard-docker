# syntax=docker/dockerfile:1

FROM alpine:3.16 as rootfs-stage

# environment
ENV REL=v3.17
ENV ARCH=x86_64
ENV MIRROR=http://dl-cdn.alpinelinux.org/alpine
ENV PACKAGES=alpine-baselayout,\
alpine-keys,\
apk-tools,\
busybox,\
libc-utils,\
xz

RUN \
# install packages
apk --no-cache add \
    bash \
    curl \
    curl-dev \
    gcc \
    git \
    make \
    musl-dev \
    patch \
    tar \
    tzdata \
    xz && \
# fetch builder script from gliderlabs
  curl -o \
  /mkimage-alpine.bash -L \
    https://raw.githubusercontent.com/gliderlabs/docker-alpine/master/builder/scripts/mkimage-alpine.bash && \
  chmod +x \
    /mkimage-alpine.bash && \
  ./mkimage-alpine.bash  && \
  mkdir /root-out && \
  tar xf \
    /rootfs.tar.xz -C \
    /root-out && \
  sed -i -e 's/^root::/root:!:/' /root-out/etc/shadow && \
# build ip checker
  git clone https://github.com/sevenrats/fastip-c.git && \
  cd fastip-c && \
  make && \
  mv fastip /root-out/usr/bin && \
  cd .. && \
  rm -r fastip-c

# Runtime stage
FROM scratch
COPY --from=rootfs-stage /root-out/ /
ARG BUILD_DATE
ARG VERSION
LABEL	maintainer="sevenrats" \
		build-date=$BUILD_DATE \
		name="Electrum-NMC" \
		description="Electrum-NMC with JSON-RPC enabled" \
		version=$VERSION \
		license="MIT"


# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
HOME="/root" \
TERM="xterm"

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    alpine-release \
    bash \
    ca-certificates \
    catatonit \
    coreutils \
    curl \
    jq \
    procps \
    shadow \
    tzdata \
    ifupdown \
    iproute2 \
    iptables \
    iputils \
    net-tools \
    openresolv \
    ldns-tools \
    tinyproxy \
	  wireguard-tools && \
  echo "**** create abc user and make our folders ****" && \
  groupmod -g 1000 users && \
  useradd -u 911 -U -d /data -s /bin/false abc && \
  usermod -G users abc && \
  mkdir -p \
    /app \
    /config \
    /defaults \
    /run/tinyproxy/ && \
  touch /run/tinyproxy/tinyproxy.pid && \
  echo "**** patching wg-quick for alpine ****" && \
  sed -i '/\[\[ $proto == -4 \]\] && cmd sysctl -q net\.ipv4\.conf\.all\.src_valid_mark=1/d' /usr/bin/wg-quick && \
  cd / && \
	wget https://raw.githubusercontent.com/sevenrats/signalproxy.sh/main/signalproxy.sh && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/*

# add local files
COPY root/ /

EXPOSE 8888/udp

ENTRYPOINT ["catatonit", "/entrypoint.sh"]
