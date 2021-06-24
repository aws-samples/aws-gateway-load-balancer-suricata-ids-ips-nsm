#!/bin/bash
if [[ -n "$MaxMindApiKey" ]]; then 
    echo "Maxmind API key found, downloading GeoIp Database"
    cd /tmp/maxmind/
    curl "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=${MaxMindApiKey}&suffix=tar.gz" -o GeoLite2-Country.mmdb.tar.gz
    tar -zxvf GeoLite2-Country.mmdb.tar.gz || echo "ERROR: No GeoDB downloaded from MaxMind, is the API key correct?"
    mkdir -p /usr/local/share/GeoLite2/
    cp GeoLite2-Country*/GeoLite2-Country.mmdb /usr/local/share/GeoLite2/GeoLite2-Country.mmdb || echo "ERROR: Not able to copy the GeoDB to the right location"
    chown suricata:suricata /usr/local/share/GeoLite2/GeoLite2-Country.mmdb
    rm -rf /tmp/maxmind/*
fi