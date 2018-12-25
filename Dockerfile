FROM ubuntu:18.10

LABEL maintainer="Dmitry Kireev <dmitry@kireev.co>"

ENV OPENVPN_AS_VERSION="2.6.1"
ENV DEBIAN_FRONTEND="noninteractive"
ENV PATH=$PATH:/usr/local/openvpn_as/scripts

RUN groupadd -r openvpn_as && useradd -s /sbin/nologin -r -g openvpn_as openvpn_as
RUN groupadd -r openvpn && useradd -s /sbin/nologin -r -g openvpn openvpn

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
	  ca-certificates \
	  libncurses5 \
	  iptables \
    net-tools \
    rsync \
    wget \
    jq && \
  wget -q "https://swupdate.openvpn.org/as/openvpn-as-${OPENVPN_AS_VERSION}-Ubuntu18.amd_64.deb" && dpkg -i openvpn-as-${OPENVPN_AS_VERSION}-Ubuntu18.amd_64.deb && \
  \
  apt-get purge -y --auto-remove wget && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/openvpn_as/

COPY duo_openvpn_as.py /usr/local/openvpn_as/scripts
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 943/tcp 1194/udp 9443/tcp
