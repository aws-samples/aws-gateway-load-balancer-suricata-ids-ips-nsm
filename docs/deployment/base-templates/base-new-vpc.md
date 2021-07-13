##### 1. Deploy the base template
Deploy the base template [base-new-vpc.yaml in your account](/cloudformation/base-new-vpc.yaml)

If you need help deploying the stack using Cloudforamtion, please see the [Official Cloudformation Documentation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacks.html): Creating Stacks using the [AWS Console](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) or the [CLI](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-cli-creating-stack.html)


###### Template Parameters
The base template have the following configurable stack parameters:
| Parameter | Default Value | Description |
|-|-|-|
|VpcName|ips-service-vpc|Inspection VPC Name
|VpcCidr|192.168.1.0/25|Inspection VPC CIDR
|PublicSubnet1Cidr|192.168.1.0/28|Inspection VPC Public Subnet 1 CIDR
|PublicSubnet2Cidr|192.168.1.16/28|Inspection VPC Public Subnet 2 CIDR
|PublicSubnet3Cidr|192.168.1.32/28|Inspection VPC Public Subnet 3 CIDR
|PrivateSubnet1Cidr|192.168.1.48/28|Inspection VPC Private Subnet 1 CIDR
|PrivateSubnet2Cidr|192.168.1.64/28|Inspection VPC Private Subnet 2 CIDR
|PrivateSubnet3Cidr|192.168.1.80/28|Inspection VPC Private Subnet 3 CIDR

The Base template creates the GitOps Pipeline and VPC where the Suricata environment will be deployed.
![Solution Overview](/img/suricata-ecs-base.png)

##### 2. Configure and Deploy Suricata using the GitOps Pipeline (AWS CodePipeline)
After the stack is created in Step 1 you go to AWS CodeCommit where you will see a repository which looks identical to this repository. Suricata has not been built nor deployed yet, so if you want you can now make changes to the Suricata config, Rulesets, Cloudformation Parameters etc. For now  we won't do any changes such as adding rules, enabling logs or similar to the Suricata Deployment.
Let's go ahead and deploy Suricata:

Go to AWS CodePipeline and select "Enable Transition". The pipeline will now start to build a docker image and after that deploy your suricata cluster using the Cloudformation template [cluster.yaml](/cloudformation/suricata/cluster.yaml).

##### 3. Use Suricata in a Centralized or Distributed architecture
For quick testing: Create a Cloudformation stack using this [template](https://github.com/aws-samples/aws-gateway-load-balancer-code-samples/blob/main/aws-cloudformation/distributed_architecture/DistributedArchitectureSpokeVpc2Az.yaml) and use the Cloudformation output of `ApplianceVpcEndpointServiceName` from the suricata cluster cloudforamtion stack as the input to the `ServiceName` parameter.


### Solution Components
#### Automation

The CloudFormation template that the pipeline calls, will instantiate several services and define various parameters that will be referenced by the constituent parts of the solution. The description of what these services and parameters are, is given below.

#### VPC

An appliance VPC is created for you, consisting of three private subnets that have access to the ECS service APIs and external code repositories, care of a Nat Gateway and Internet Gateway. You can specify suitable CIDR ranges within the ‘base-vpc.yaml’ template within the code repository – defaults have been provided for you.

![VPC](img/vpc.png)

#### GWLB

This service is created automatically and outputs are provided as part of the stack outputs. The solution doesn’t automatically create endpoints for use with this appliance VPC; you can choose to integrate this service as you see fit – a great resource for reference implementation can be found within this public BLOG. The CloudFormation stack outputs the ‘com’ object that you need to reference when creating your endpoints:

```
    {
        “ApplianceVpcEndpointServiceName” : “com.amazonaws.vpce.<region>.vpce….”
    }
```

#### ECS

The ECS cluster is built using the ‘cluster.yaml;’ file with parameter inputs from the ‘cluster-template-configuration.json’ file.

The configuration file allows convenient modification of logging and instance size settings, as well as configuration of third-party Suricata Rulesets:

```
    {
        "Parameters" : {
            "PcapLogRententionS3": "5",
            "DefaultLogRententionCloudWatch": "3",
            "EveLogRententionCloudWatch": "30",
            "SuricataRulesets": "",
            "MaxMindApiKey": "",
            "SuricataInstanceType": "t3.large"
        }
    }
```

The ECS cluster uses a host networking model for tasks that it launches and therefore creates a 1:1 mapping between a running task and a running ECS host. The ECS hosts are launched by an Autoscaling Group and have their low-level networking parameters configured to support GWLB integration – they are added to the cluster as part of the bootstrap process. The ECS Service creates 3 Tasks, and each task launches a Suricata container and a Rulesfetcher container on each host. The hosts pass networking traffic to the Suricata container using a Queue configuration as outlined later in this BLOG. The RulesFetcher container is responsible for pulling rule files updates from S3 that are placed there by the pipeline and from external sources via direct internet connection. External rules are checked every 60 seconds by the RulesFetcher container, rule file updates that are placed in S3 are checked and aupdated approximately every 10-20 seconds.

### MaxMind GeoIP

To make use of the MaxMind GeoIP2 database, you must first [register](https://www.maxmind.com/en/geolite2/signup?lang=en) with MaxMind. Once registered, you can populate your registration key <span style=color:Aquamarine>"MaxMindApiKey": *"%keyhere%"*</span> within the <span style=color:Aquamarine>cluster-template-configuration.json</span> file. The solution will automatically download and enable your database, ready for use with your Suricata GeoIP rules.


#### Amazon Elastic File System

Both the Suricata and RulesFetcher containers use a [BindMount](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bind-mounts.html) in their task definitions. The 'SuricataLogs' volume is attached to each container and mounted at '/var/log/suricata/'. Each ECS host, mounts a shared EFS volume at bootstrap and this is linked to the '/var/log/' directory. Logs are therefore saved in EFS. 

#### Simple Systems Manager Parameters

Various parameters are used by the solution, these are listed below:

1. '/ipsautomation-pipelinestack-suricata-cluster/suricata/cloudwatchconfig'

    >This parameter is used to hold the CloudWatch Agent configuration that is used by the ECS hosts as they boot

2. '/ipsautomation-pipelinestack-suricata-cluster/suricata/rulesets'

    >This parameter is read by the RulesFetcher container periodically. Modifications to this parameter will cause a ruleset download or potentially a removal to take place.

3. '/ipsautomation-pipelinestack/codebuild/container/rulesFetcher/md5sum'

    >This parameter is used by CodeBuild to determine whether the computed Dockerfile MD5 checksum differs from the Dockerfile in the code repository

4. '/ipsautomation-pipelinestack/codebuild/container/rulesFetcher/uri'

    >This parameter is used by CodeBuild to locate the ECR repository and image for the RulesFetcher container

5. '/ipsautomation-pipelinestack/codebuild/container/suricata/md5sum'

    >This parameter is used by CodeBuild to determine whether the computed Dockerfile MD5 checksum differs from the Dockerfile in the code repository

6. '/ipsautomation-pipelinestack/codebuild/container/suricata/uri'

    >This parameter is used by CodeBuild to locate the ECR repository and image for the Suricata container
#### Amazon S3

Two S3 buckets are created as part of the overall solution. The first is created as part of the pipeline setup, and this is used to hold the pipeline artefacts, GitHub clone and subsequent pipeline runs that are read by the RulesFetcher.

![VPC](/img/s3_buckets_1.png)

The second bucket is created as part of the pipeline release and this holds the network pcap files that will be generated by Suricata. These pcap files are raw packet level dumps from the instances and can be used for further inspection or processing.

![VPC](/img/s3_buckets_2.png)


#### CloudWatch Logging

In the default configuration, Suricata will use the following logging modules: 
* fast
* eve-log
* pcap-log

The logs that are generated by the fast and eve-log modules are loaded into CloudWatch logs and then tailed and rotated automatically on each host. Pcap logs are saved into S3. Cloudwatch Log Groups are created in anticipation of additional logging modules being enabled. You can disable these default log modules or enable other log modules by editing the ‘suricata.yaml’ configuration file. Enabled log files will automatically be loaded into CloudWatchLogs using the agent in the containers, into their respective Cloudwatch Log Groups.

* fast.log is ingested into CloudWatch Logs: /%stackname%/suricata/fast/ and is saved for 3 days (Configured in /deployment/suricata/cluster-template-configuration.json)
* eve-log.json is ingested into CloudWatch Logs: /%stackname%/suricata/eve/ and is saved for 30 days (Configured in /deployment/suricata/cluster-template-configuration.json)
* pcap is ingested into an S3 bucket created by the Suricata Cluster Configuration stack and is saved for 5 days (Configured in /deployment/suricata/cluster-template-configuration.json)


### Manual deployment / Using existing CI/CD pipeline
If you already have an existing CI/CD pipeline, a Git repository or similar that you want to use instead, this is also possible.

You can find the CloudFormation template which is deploying the Suricata cluster in: /deployment/suricata/ and the various steps to build the Container images in `/Dockerfiles/*/buildspec.yml`.

You need to build the suricata Dockerfiles and provide the built Suricata Container image together with an existing VPC which need to have three private subnets with a default route to NAT to the Cloudforamtion suricata cluster template.

## How to cleanup

### Pipeline Deployed Artefact

The pipeline deploys a child stack from the code in the CodeCommit repository. To remove this, you can simply delete the stack that the pipeline created. You may need to empty S3 buckets of content before you do this!

### Pipeline Base Stack

The pipeline stack was deployed from a initiation template ( this is also present in the code in the CodeCommit repository ). To remove this, you can simply delete the stack that defined the pipeline. You may need to empty S3 buckets of content before you do this!