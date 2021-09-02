This folder contains `base`-cloudformation templates. These templates will setup the GitOps pipeline and will copy this GitHub Repo into AWS CodeCommit which will be the Git repo you work against.
The [base-new-vpc.yaml](/cloudformation/base-new-vpc.yaml) template will setup a new environment from scratch, including a VPC where Suricata will be deployed. 
The [base-existing-vpc.yaml](/cloudformation/base-existing-vpc.yaml) template (TODO) will deploy Suricata in an already existing VPC. You need to make sure your existing VPC supports the minimum requirments.

The `base`-cloudformation templates will setup an environment which contains the GitOps pipeline.
![Solution Overview](/img/suricata-ecs-base.png)

When Suricata is later deployed using the GitOps Pipeline the full environment will look like the following:
![Solution Overview](/img/suricata-ecs-cluster.png).

For deployment documentation and walkthrough, see:
[/docs/deployment/base-new-vpc.md](/docs/deployment/base-new-vpc.md)
[/docs/deployment/base-existing-vpc.md](/docs/deployment/base-existing-vpc.md) (TODO)