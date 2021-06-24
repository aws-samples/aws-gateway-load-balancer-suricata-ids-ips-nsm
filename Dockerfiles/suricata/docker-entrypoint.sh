#!/bin/sh
echo "Suricata container started"
exec /bin/supervisord -c /supervisord.conf --nodaemon