# AWS Meetup #15 - hosted by Nordcloud ( 3<sup>rd</sup> December 2019 )

## https://www.meetup.com/Amazon-Web-Services-AWS-Vienna/events/266041775/

## About me: http://mladen.trampic.info
Up to date - Data Lake Solution Arhitect @ Raiffeisen Bank International 

## What do my teammates do, together with me?
We are building up Analytical / Operational Data Lake for RBI. Fully in the cloud ( AWS ).
- Analytical DL - Support Data Scientists
- Operational DL - Well everything else ...

![Data Lake Team](content/rbi_data_lake_team.jpg)

## How does Nordcloud fits?
<table>
 <tr>
    <td><img src="content/Peter_Gergely_Marczis.jpg" width="200" height="200"></td>
    <td>Well, We have an Elf from Nordcloud clouds,<br> you can find him on linkedin @ https://www.linkedin.com/in/marczis/ <br> When he is not running linux that is behind the Clouds...</td>
 </tr>
</table>

## One line marketing - open Positions @ RBI
- https://jobs.rbinternational.com/Data-Lake-Engineer-fmd-eng-j3386.html?sid=994cbf85f8ffeea9ed5362449c075a52
( if you are interested to apply, drop me a mail @ mladen.trampic@rbinternational.com - so I can't interview you and i get day off )

![Reality](content/reality.png)

# What is cloudformation / terraform about?
It is all about infrastructure as a code, immutable as much as in order to have continuity and stabilty in releases / infrastructure changes. Allowing you to rollback, test, automate deployment. ( sleep at nights )

## Cloudformation
You can write templates in following forms:
- json
- yaml

AWS Native tool, With ease you can create create almost any AWS resource.

## YAML example
```yaml
AWSTemplateFormatVersion: "2010-09-09"
Parameters: 
  DevOpsAccountId: 
    Type: String
    Default: 'placeholder for valid account id'
Resources:
  TerraformDeployRole:
    Type: "AWS::IAM::Role"
    Properties:
      RoleName: 'aws-meetup-tf-apply'
      Policies:
      - PolicyName: "TerraformDeployRole"
        PolicyDocument:
          Version: '2012-10-17'
          Statement:
          - Effect: "Allow"
            Action: '*'
            Resource: '*'
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: "Allow"
            Principal:
              AWS:
                - !Ref DevOpsAccountId
            Action:
              - "sts:AssumeRole"
```

If you are repetetive, you can always put some jinja ( https://jinja.palletsprojects.com/en/2.10.x/ ) in front and make some magic... eg, template that build's a lot of VPC endpoints in Private zones...

```yaml
{%- macro sentence_case(text) %}{{text.split('.')|map('capitalize')|join('') }}{% endmacro %}
AWSTemplateFormatVersion: '2010-09-09'
Parameters:
  VpcId:
    Type: AWS::EC2::VPC::Id
    Default: {{VpcId}}
Resources:
  SGInterfaceVPCEndpoints:
    Type: 'AWS::EC2::SecurityGroup'
    Properties:
      GroupDescription: SG Attached to VPC Endpoint Interfaces to allow ingress traffic for VPC Resources.
      VpcId: !Ref VpcId
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 0
          ToPort: 65535
          CidrIp: {{VpcCidr}}
  {%- set GatewayVPCEndpoints = ['s3', 'dynamodb'] %}
  {%- for endpoint in GatewayVPCEndpoints %}
  Endpoint{{sentence_case(endpoint)}}:
    Type: 'AWS::EC2::VPCEndpoint'
    Properties:
      {%- set comma = joiner(",") %}
      RouteTableIds: [ {% for item in Subnets %}{{item['RouteTableId']}}{%if not loop.last %}, {% endif %}{% endfor %} ]
      ServiceName: !Sub 'com.amazonaws.${AWS::Region}.{{endpoint}}'
      VpcId: !Ref VpcId
  {%- endfor %}
  {%- set InterfaceVPCEndpoints = ['logs', 'ecr.dkr', 'kms', 'glue', 'ec2', 'ecr.api'] %}
  {%- for endpoint in InterfaceVPCEndpoints %}
  Endpoint{{sentence_case(endpoint)}}:
    Type: 'AWS::EC2::VPCEndpoint'
    Properties:
      VpcEndpointType: Interface
      PrivateDnsEnabled: True
      ServiceName: !Sub 'com.amazonaws.${AWS::Region}.{{endpoint}}'
      VpcId: !Ref VpcId
      SubnetIds: [ {%- for item in Subnets %}{% if 'Private' in item['ZoneName'] %} {{ item['SubnetId'] }}{%if not loop.last %}, {% endif %}{% endif %}{% endfor %} ]
  {%- endfor %}
Outputs:
  TemplateID:
    Value: 'vpc/rbi-dl-vpc-endpoints'
  StackName:
    Description: 'Stack name.'
    Value: !Sub '${AWS::StackName}'
  {%- for endpoint in GatewayVPCEndpoints %}
  Endpoint{{sentence_case(endpoint)}}:
    Description: 'The VPC endpoint to {{sentence_case(endpoint)}}.'
    Value: !Ref Endpoint{{sentence_case(endpoint)}}
    Export:
      Name: !Sub '${AWS::StackName}-Endpoint{{sentence_case(endpoint)}}'
  {%- endfor %}
  {%- for endpoint in InterfaceVPCEndpoints %}
  Endpoint{{sentence_case(endpoint)}}:
    Description: 'The VPC endpoint to {{sentence_case(endpoint)}}.'
    Value: !Ref Endpoint{{sentence_case(endpoint)}}
    Export:
      Name: !Sub '${AWS::StackName}-Endpoint{{sentence_case(endpoint)}}'
  {%- endfor %}
```
This is an example input file for before mentioned jinja template:
```json
{
	"Name": "ACCOUNT_ALIAS",
	"Id": "***ACC_ID***",
	"VpcId": "vpc-*****************",
	"VpcCidr": "172.31.0.0/16",
	"Subnets": [
		{
			"ZoneName": "Private",
			"SubnetId": "subnet-*****************",
			"RouteTableId": "rtb-*****************",
			"CidrBlock": "172.31.17.0/24"
		},
		{
			"ZoneName": "Public",
			"SubnetId": "subnet-*****************",
			"RouteTableId": "rtb-*****************",
			"CidrBlock": "172.31.18.0/20/24"
		}
	]
}
```
## Terraform
Terraform Hashi Conf. Language ( HCL)

- https://github.com/hashicorp/hcl/blob/hcl2/hclsyntax/spec.md
- https://aws.amazon.com/blogs/apn/terraform-beyond-the-basics-with-aws/
- https://learn.hashicorp.com/terraform/getting-started/install.html


# How do We @ RBI do Terraform & DevOps?
![Diagram](content/general_architecture.png)

Now some short intro here for attached TF project:

Requirement:
- Docker installed
- All accounts ID's and Roles preconfigured as per environments folder
- DevOps account IAM User should be able to assume all roles on all accounts for Deployment

Folder structure:
```
.
├── README.md
├── aws-meetup-tools # docker image used for TF for consistency
│   ├── README.md
│   ├── docker
│   │   └── Dockerfile
│   └── setup
├── content
│   └── *.png
├── environments
│   ├── aws-meetup-dev
│   │   └── aws-meetup-dev.tfvars.json # env name eg... account_alias
│   ├── aws-meetup-devops
│   │   └── aws-meetup-devops.tfvars.json # Central Deployment Account
│   ├── aws-meetup-prod
│   │   └── aws-meetup-prod.tfvars.json
│   ├── aws-meetup-test
│   │   └── aws-meetup-test.tfvars.json
│   └── provider.tfvars.json
└── templates
    ├── aws-meetup-tf-ec2
    │   ├── demo_instance.tf
    │   ├── environments
    │   │   ├── aws-meetup-dev
    │   │   │   └── aws-meetup-tf-ec2.tfvars.json
    │   │   ├── aws-meetup-devops
    │   │   │   └── aws-meetup-tf-ec2.tfvars.json
    │   │   ├── aws-meetup-prod
    │   │   │   └── aws-meetup-tf-ec2.tfvars.json
    │   │   └── aws-meetup-test
    │   │       └── aws-meetup-tf-ec2.tfvars.json
    │   └── variable.tf
    └── aws-meetup-tf-state # State File Deployment
        ├── environments
        │   └── aws-meetup-devops
        │       └── aws-meetup-tf-state.tfvars.json
        ├── state.tf #main state file TF template
        ├── variables.tf
        └── versions.tf
```

Get Started
```bash
git clone https://github.com/Mladen-Trampic-SRB-1989/meetup-aws-user-group-vienna.git

cd meetup-aws-user-group-vienna

source aws-meetup-tools/setup

#build docker image
tf_bi_build

#verify image exists
docker images -f "reference=tftools"

#if image is there, you are good to go
cd templates/aws-meetup-tf-state/

#note also that presence of ~/.aws/credentials / ~/.aws/config file is needed, where default profile is used to assume roles based on selected environment

#init
tf init

#switch to devops environment
tf env aws-meetup-devops

#plan
tf plan

#if all good apply ( local backend )
tf apply -auto-approve

#deploy ec2 in dev environment ( now it is s3 backend with DDB locking )
cd ../aws-meetup-tf-ec2
tf init
tf env aws-meetup-dev
tf plan
tf apply -auto-approve

```

