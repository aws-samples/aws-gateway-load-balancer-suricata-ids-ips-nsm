
FROM public.ecr.aws/amazonlinux/amazonlinux:2.0.20210326.0-amd64

RUN amazon-linux-extras install -y epel && \
  yum -y install shadow-utils python-pip awscli supervisor cronie tar && \
  yum clean all && \
  rm -rf /var/cache/yum /etc/cron.*/* && \
  pip install --upgrade suricata-update

COPY docker-entrypoint.sh maxmind-geodb-fetcher.sh rules-fetcher.sh supervisord.conf /

RUN groupadd --gid 1000 suricata && \
  useradd --gid 1000 --uid 1000 --create-home suricata && \
  mkdir -p /var/lib/suricata/rules /tmp/maxmind/ /usr/local/share/GeoLite2/ && \
  chown -R suricata:suricata /var/lib/suricata /tmp/maxmind/ /usr/local/share/GeoLite2/ && \
  chmod +x /docker-entrypoint.sh /maxmind-geodb-fetcher.sh /rules-fetcher.sh

VOLUME /var/lib/suricata/rules
VOLUME /usr/local/share/GeoLite2/

ENTRYPOINT ["/docker-entrypoint.sh"]
