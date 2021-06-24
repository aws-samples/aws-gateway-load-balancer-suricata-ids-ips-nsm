#!/bin/sh

echo "fetcher container started"
su - suricata -s /bin/sh -c "/maxmind-geodb-fetcher.sh"

echo "0 0 * * WED su - suricata -s /bin/sh -c \"/maxmind-geodb-fetcher.sh\" >/proc/1/fd/1 2>/proc/1/fd/2" > /etc/cron.d/rules-updater.sh
crontab /etc/cron.d/rules-updater.sh

exec /bin/supervisord -c /supervisord.conf --nodaemon