FROM public.ecr.aws/amazonlinux/amazonlinux:2.0.20210326.0-amd64

RUN amazon-linux-extras install -y epel && \
  yum -y install gcc libpcap-devel pcre-devel libyaml-devel file-devel \
  zlib-devel jansson-devel nss-devel libcap-ng-devel libnet-devel tar make \
  libnetfilter_queue-devel lua-devel PyYAML libmaxminddb-devel supervisor \
  lz4-devel gzip && \
  curl https://sh.rustup.rs -sSf | sh -s -- --profile minimal --default-toolchain 1.52.1 --no-modify-path -y && \
  yum clean all && \
  rm -rf /var/cache/yum /var/lib/suricata/rules /etc/cron.*/*

WORKDIR /tmp
ENV PATH=/root/.cargo/bin:$PATH

RUN curl -s https://www.openinfosecfoundation.org/download/suricata-6.0.0.tar.gz -o suricata-6.0.0.tar.gz && \
  tar -zxvf suricata-6.0.0.tar.gz && \
  cd suricata-6.0.0 && \
  ./configure --disable-gccmarch-native --prefix=/ --sysconfdir=/etc/ --localstatedir=/var/ --enable-lua --enable-geoip --enable-nfqueue --enable-rust && \
  make install install-conf && \
  mkdir -p /var/lib/suricata/update/ && \
  rm -rf /tmp/*

COPY docker-entrypoint.sh rules-updater.sh supervisord.conf /

RUN  groupadd --gid 1000 suricata && \
  useradd --gid 1000 --uid 1000 --create-home suricata && \
  chown -R suricata:suricata /etc/suricata && \
  chown -R suricata:suricata /var/log/suricata && \
  chown -R suricata:suricata /var/lib/suricata && \
  chown -R suricata:suricata /var/run/suricata && \
  chmod +x /docker-entrypoint.sh /rules-updater.sh

COPY --chown=suricata:suricata ./etc/suricata/ /etc/suricata/
COPY --chown=suricata:suricata static.rules /var/lib/suricata/static/rules/static.rules

ENTRYPOINT ["/docker-entrypoint.sh"]
