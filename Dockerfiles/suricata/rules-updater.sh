#!/bin/bash
while :
do
	fetched_rules_md5sum=$(find /var/lib/suricata/rules/ -type f -exec md5sum {} + | awk '{print $1}' | LC_ALL=C sort | md5sum | awk '{print $1}')
	deployed_rules_md5sum=$(cat /tmp/rules.md5)
	if [[ "$fetched_rules_md5sum" != "$deployed_rules_md5sum" ]] ; then 
		echo "New rules found. Updating rules"
		suricatasc -c reload-rules
		echo "$fetched_rules_md5sum" > /tmp/rules.md5
	fi
	sleep 10
done
