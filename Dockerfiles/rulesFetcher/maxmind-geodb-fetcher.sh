#!/bin/bash

if [[ "$1" == "cron" ]]; then
    isCronJob="true"
fi

maxMindGeoDbFetcher () {
    if [[ "$MaxMindApiKey" ]]; then 
        echo "[INFO] MaxMind API key found, downloading GeoIp Database"
        cd /tmp/maxmind/
        curl -sS "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=${MaxMindApiKey}&suffix=tar.gz" -o GeoLite2-Country.mmdb.tar.gz
        tar -zxf GeoLite2-Country.mmdb.tar.gz || echo "ERROR: No GeoDB downloaded from MaxMind, is the API key correct?"
        cp GeoLite2-Country*/GeoLite2-Country.mmdb /usr/local/share/GeoLite2/GeoLite2-Country.mmdb || echo "ERROR: Not able to copy the GeoDB to the right location"
        chown suricata:suricata /usr/local/share/GeoLite2/GeoLite2-Country.mmdb
        rm -rf /tmp/maxmind/*
    fi
}

#Check if Crontab is the trigger. If so - skip loop and download the latest and greatest package from MaxMind and then exit.
if [[ "$isCronJob" == "true" ]]; then
    echo "[INFO] Running scheduled crontab for MaxMind GeoDB update"
    MaxMindApiKeySsmParameter=$2
    REGION=$3
    MaxMindApiKey=$(aws ssm get-parameter --name "$MaxMindApiKeySsmParameter" --region "$REGION" --output text --query Parameter.Value 2> /dev/null)
    maxMindGeoDbFetcher 
else
    #If the script is started outside of crontab (eg docker-entrypoint/supervisord) we loop to check if we should download the Maxmind DB. 
    while :
    do
        MaxMindApiKey=$(aws ssm get-parameter --name "$MaxMindApiKeySsmParameter" --region "$REGION" --output text --query Parameter.Value 2> /dev/null)
        #Won't download the GeoDB if the GeoDB already exist - we just need to updated the GeoDB once a week in that case (using crontab).
        #If no GeoDB exist in path: /usr/local/share/GeoLite2/GeoLite2-Country.mmdb. We check if API key is set and download the database.
        if [[ ! -f "/usr/local/share/GeoLite2/GeoLite2-Country.mmdb" ]]; then
            maxMindGeoDbFetcher
        else
        #If API key is not set but GeoDB exist we remove the GeoDB
            if [[ ! "$MaxMindApiKey" ]]; then
                echo "[INFO] Seems like Maxmind API key was removed. Deleting GeoDB. Please configure MaxMind API key to download the GeoDB again."
                rm -f /usr/local/share/GeoLite2/GeoLite2-Country.mmdb
            fi 
        fi
        sleep 10
    done
fi
