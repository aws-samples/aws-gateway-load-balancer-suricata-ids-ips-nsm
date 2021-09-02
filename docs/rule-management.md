#### Ruleset Management

This solution provides three levels of Ruleset management. 

1. The first is via the `cluster-template-configuration.json` file. In here you can specify additional rulesets to be downloaded by the RulesFetcher-container periodically ( 60 seconds by default ) and loaded into the engine. These rulesets are applied on-the-fly without the need to rebuild or redeploy the Suricata container. [suricata-update](https://github.com/OISF/suricata-update) is used to handle the download and update of the rulesets and you can specify any source from [The Open Information Security Foundation rulesets list](https://www.openinfosecfoundation.org/rules/index.yaml) in a comma seperated list, example below:

```
    {
        "Parameters" : {
            "PcapLogRententionS3": "5",
            "DefaultLogRententionCloudWatch": "3",
            "EveLogRententionCloudWatch": "30",
            "SuricataRulesets": "et/open, et/pro secret-code=mysecret, tgreen/hunting",
            "SuricataInstanceType": "t3.large"
        }
    }
```

2. The second location is within the [/dynamic.rules](/dynamic.rules) file within the code repo base directory. Rules in `/dynamic.rules` are applied and read on-the-fly by the suricata engine. `/dynamic.rules` should be used when you want to deploy and apply rules on-the-fly and don't want, or need to to keep your rules versioned, together with the suricata config and suricata version. The `/dynamic.rules` file is deployed to S3 and picked up by the RulesFetcher-container which periodically checks the S3 location ( 60 seconds by default ). These rules are applied without the need to rebuild or redeploy the Suricata container

3. The third location for rule entry is within the [/Dockerfiles/suricata/static.rules](/Dockerfiles/suricata/static.rules) file. This rule file does not update dynamically and is built into the container image as part of the image creation process by CodeBuild. `static.rules` should be used when you want to keep your rules versioned together with the suricata config and suricata version or for rules that shall always be enforced and should not be removed. Rules in `static.rules` are NOT applied on-the-fly and you need to rebuild and redeploy the Suricata container with the updated rules.
 
**NOTICE:** When you edit `static.rules` and build a new container, a new task definition version in ECS is created and automatically deployed to your ECS cluster. This means that the cluster will deploy your new task definition using blue/green deployment. When this happens, existing flows need to be reset by client or timed out. New flows are distributed to the new EC2s/Suricata containers.