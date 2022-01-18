# Building an open-source IPS/IDS Service on Gateway Load Balancer 
<img  width="120" height="180" align="right" src=img/meerkat.png>
This repository has deployment, installation and clean up instructions on how to deploy and manage Suricata in AWS with Elastic Container Services and Gateway Load balancer. The main use-case for this repo is to provide a baseline from which you can build on. The solution will deploy Suricata on ECS and provides an opportunity to adjust the Suricata configuration and rulesets using a GitOps workflow.

This Suricata deployment can then be used as a target for Gateway Load Balancer in a [distributed](https://aws.amazon.com/blogs/networking-and-content-delivery/scaling-network-traffic-inspection-using-aws-gateway-load-balancer/) or [centralized](https://aws.amazon.com/blogs/networking-and-content-delivery/centralized-inspection-architecture-with-aws-gateway-load-balancer-and-aws-transit-gateway/) architecture to be able to have suricata as a scalable network security appliance.

## How to deploy
### Quickstart
The quickest way to deploy the full solution that consists of Suricata running on ECS and the GitOps CI/CD pipeline used for Suricata configuration is to deploy the solution using any of the `base`-clouformation templates. These templates will setup the GitOps pipeline and will copy this GitHub Repo into AWS CodeCommit which will be the Git repo you work against to setup Suricata rules, suricata configuration etc.

The [base-vpc.yaml](/cloudformation/base-vpc.yaml) template will setup a new environment from scratch, including a VPC where Suricata will be deployed.

For deployment documentation and walkthrough, see:
[/docs/deployment/base-templates/base-vpc.md](/docs/deployment/base-templates/base-vpc.md)

### Other Suricata deployment configurations
[docs/deployment](/docs/deployment) contains various deployment configurations for Suricata. 

### Use Suricata for network inspection
After you have deployed Suricata you would need to create and setup Gateway Load balancer VPC Endpoints so Suricata can be used to Inspect your networking traffic. 
[docs/architectures](/docs/architectures) contains a number of architectures where Suricata can be used as a scalable network security appliance.

## Commmon questions:

**How can I add my own rules?**

You have three options to configure rules:
1. Specify a ruleset from the [The Open Information Security Foundation rulesets list](https://www.openinfosecfoundation.org/rules/index.yaml) in `/cloudformation/suricata/cluster-template-configuration.json`. The rulesets specified are updated once every minute and you can delete and add rulesets on the fly.
2. Specifying your own rules in `/dynamic.rules`. Rules in `/dynamic.rules` are deployed to s3 and read on-the-fly by the suricata engine.
3. Specifying your own rules in `/Dockerfiles/suricata/static.rules` and rebuild, upload and deploy your new docker image. The thought here is to keep your rules versionized together with the suricata config and suricata version.

For more information about rules: [rule-management.md](/docs/rule-management.md)

**How can I make changes to the suricata config?**

In the current setup, you need to make changes in the `suricata.yaml` in `Dockerfiles/suricata/etc/suricata/suricata.yaml` and rebuild, upload and deploy your new docker image. The thought here is to keep your config versioned together with the your `static.rules` and Suricata version.

**What logs are automatically ingested to CloudWatch Logs / S3?**

In the default suricata configuration provided in this repo, suricata will use the following logging modules: fast.log, eve-log.json and pcap. These logs are tailed and rotated automatically.

* `fast.log` is ingested into CloudWatch Logs: `/suricata/fast/` and is  saved for 3 days (Configured in [Cloudformation parameter file](/cloudformation/suricata/cluster-template-configuration.json))
* `eve-log.json` is ingested into CloudWatch Logs: `/suricata/eve/` and is saved for 30 days (Configured in [Cloudformation parameter file](/cloudformation/suricata/cluster-template-configuration.json))
* `pcap` is ingested into a S3 bucket created by the Suricata Cluster Configuration stack and is saved for 30 days (Configured in [Cloudformation parameter file](/cloudformation/suricata/cluster-template-configuration.json)).

You can disable these logs or enable other logs by editing the suricata config: `/Dockerfiles/suricata/etc/suricata/suricata.yml`. You don't need to configure the Cloudwatch Agent to puckup new enabled logs. The Cloudwatch Agent is configured to automatically tail and stream Suricata logs from their default location to CloudWatch Logs. 

The stdout from the Suricata and RuleFetcher container is also logging to CloudWatch Logs per default. 

**Does Suricata scale automatically?**

ECS Autoscaling is enabled for CPU. When the clusters average CPU goes over 80% (configurable) a new ECS task (a suricata container) is started. Scale-in is enabled, so if your traffic pattern is changing alot you will see ECS tasks (suricata containers) come and go.
Gateway Load Balancer will add the new ECS tasks as targets, however existing flows will still go to their old targets so we recommend that you tweak the scaling parameters, configuration and metrics to fit your environment. For example, if you have lots of long-lasting flows, you might want to disable automatic scale-in.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

This product can be configured to use GeoLite2 data created by MaxMind and licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/), available from [https://www.maxmind.com](https://www.maxmind.com).

