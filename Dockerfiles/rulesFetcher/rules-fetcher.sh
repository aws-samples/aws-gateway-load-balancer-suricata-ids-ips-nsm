#!/bin/bash
shopt -s extglob
IFS=","

while :
do
    #Get new rules sources from SSM parameter
    rule_sources_to_be_used=$(aws ssm get-parameter --name "$RulesetsSsmParameter" --region "$REGION" --output text --query Parameter.Value 2> /dev/null)

    #If any rule sources are configured in the CloudFormation Parameter "SuricataRulesets", they will be added to suricata.
    if [[ "$rule_sources_to_be_used" ]]; then
        #Fetches and updates sources from https://www.openinfosecfoundation.org/rules/index.yaml
        suricata-update update-sources --suricata-version 6.0.2 --quiet
        #Enable new rule sources
        for I in $rule_sources_to_be_used; do 
            I="${I##*( )}"
            suricata-update enable-source -q --suricata-version 6.0.2 --quiet "$I"
        done
    fi
    
    #Cleanup of unused rule sources. If there are any rule sources in /var/lib/suricata/update/sources/ which is NOT configured in the CloudFormation Parameter "SuricataRulesets". We remove these rulesets from /var/lib/suricata/update/sources/ and update suricata.
    #The CloudFormation Parameter "SuricataRulesets" is always source of truth.
    if [[ -d "/var/lib/suricata/update/sources/" ]]; then    
        for I in /var/lib/suricata/update/sources/*; do
            source=$(grep "source:" "$I" | sed -e 's/source: //')
            if [[ ! "$rule_sources_to_be_used" = *$source* ]]; then
                echo "[INFO] Removing rule source: $source since the source wasn't found in CloudFormation Parameter: SuricataRulesets."
                suricata-update remove-source --suricata-version 6.0.2 --quiet "$source"
            fi
        done
    fi

    #et/open is enabled by default. This is a fix to remove et/open if it's not specified to be used in the CloudFormation Parameter "SuricataRulesets". https://forum.suricata.io/t/suricata-update-use-only-local-rules/399/3 
    if [[ ! "$rule_sources_to_be_used" = *et/open* ]]; then
        echo "[INFO] Removing rule source: et/open since the source wasn't found in CloudFormation Parameter: SuricataRulesets."
        suricata-update remove-source --suricata-version 6.0.2 --quiet et/open
    fi

    #Fetches the Dynamic rules from S3
    aws s3 cp s3://"$DynamicRulesS3Path" /var/lib/suricata/rules/dynamic.rules --quiet
    suricata-update -f --suricata-version 6.0.2 --no-reload --no-test --url file:///dev/null --quiet
    sleep 10
done

