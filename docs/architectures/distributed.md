![Architecture](https://raw.githubusercontent.com/aws-samples/aws-gateway-load-balancer-code-samples/main/aws-cloudformation/distributed_architecture/images/gwlb_distributed_architecture.jpg)

To setup suricata in a distributed inspection architecture using AWS Gateway Load Balancer (GWLB) AWS Gateway Load Balancer Endpoints you can follow this guide: https://github.com/aws-samples/aws-gateway-load-balancer-code-samples/tree/main/aws-cloudformation/distributed_architecture. 

Change the `GWLB Appliance VPC Sample` in the guide to your Suricata template, for example [base-vpc.yaml](/cloudformation/base-vpc.yaml). 

You don't have to do any modifications in the [base-vpc.yaml](/cloudformation/base-vpc.yaml) to setup this architecture. When you want to create a Spoke VPC you can use the Cloudformation output of A`pplianceVpcEndpointServiceName` from the suricata cluster cloudformation stack as the input to the ServiceName parameter when launching the Distributed architecture `GWLB Spoke VPC Sample` Cloudformation template.




