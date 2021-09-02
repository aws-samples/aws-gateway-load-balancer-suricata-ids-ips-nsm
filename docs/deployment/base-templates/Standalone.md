### Manual deployment / Using existing CI/CD pipeline
If you already have an existing CI/CD pipeline and/or a Git repo that you want to use to deploy and configure Suricata this is also possible.

You can find the CloudFormation template which is deploying the Suricata cluster in: [/cloudformation/suricata/](/cloudformation/suricata/) and the various steps to build the Container images in [/Dockerfiles/](/Dockerfiles/). 

You need to build the Suricata and RuleFetcher images from the Dockerfile and provide said images together with an existing VPC (which need to support the minimum VPC requirments) when deploying suricata manually using [/cloudformation/suricata/cluster.yaml](/cloudformation/suricata/cluster.yaml)