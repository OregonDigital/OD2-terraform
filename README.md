# OD2 Packer and Terraform

## Setup notes
- Create your AWS credentials file :  `mkdir ~/.aws && vim ~/.aws/credentials`
```
[default]
aws_access_key_id = "BOBROSS"
aws_secret_access_key = "BOBROSS"
```
- Set permissions to credentials file `chmod 600 ~/.aws/credentials`
- Copy the Terraform and Packer example variable files and populate them
```
$cp terraform.tfvars.example terraform.tfvars
$cp packer/variables.json.example packer/variables.json
```

## Release process
- Run Packer to create a new AMI
  - Capture the newly created AMI ID
- Update Terraform variables
- Run Terraform plan to confirm updates
- Run Terraform apply to deploy

## Packer
### Run Packer to create a new AMI
Packer is used to build several different images for the infrastructure. A description of each is as follows;
- packer/aws/**base** : Basic server build with application dependencies and user setup, all other builds should reference this as their starting AMI.
- packer/aws/**web** : OD2 Rails web server & application
- packer/aws/**database** : OD2 Postgresql database server

```
$export BUILD_TYPE=base
$cd packer/aws/$BUILD_TYPE

# Validate the build is going to work
$packer validate -var-file ../../variables.json $BUILD_TYPE.json
```
### Build the **base** AMI
```
$packer build -var-file ../../variables.json $BUILD_TYPE.json
```
### Build the **database** or **web** AMI (or any instance that lives on the private subnet of the VPC)
An instance that lives on the private subnet, and having an EFS nfs mount requires several pieces of information. Remote building on the private subnet requires using the bastion on the VPC to login through the public subnet. The bastions IP, username, and private key are all necessary to tunnel the connection to the private subnet. Mounting an EFS drive requires that both the EFS drive and instance both live on the same VPC, subnet, and have compatible security groups (allowing ingress and egress of port 2049). Finally, the EFS drive dns name is necessary for creating a mount point in the build process.

***All of the information necessary for this command can be found as outputs from the `terraform apply` command. (If there are no changes to the infrastructure, the command can be run and it will still show these outputs.)***
```
$packer build -var-file ../../variables.json \
  -var 'aws_region=$AWS_REGION' \
  -var 'aws_efs_mount_dns_name=$EFS_MOUNT_DNS_NAME' \
  -var 'aws_subnet_id=$VPC_PRIVATE_SUBNET_ID' \
  -var 'aws_security_group_id=$PACKER_SECURITY_GROUP_ID' \
  -var 'ssh_bastion_host=$VPC_BASTION_IP' \
  -var 'ssh_bastion_private_key_file=$SSH_PRIVATE_KEY_PATH' \
  -var 'ssh_bastion_username=$VPC_BASTION_USERNAME'  \
  $BUILD_TYPE.json
```
**Wait for awhile and capture the AMI and output details after a successful build**
## Terraform
Terraform files are found in the `terraform/aws` directory.
### Update Terraform variables
Open `terraform/aws/variables.tf` and update the AMI located in either **web_amis**, or **db_amis** hash for the appropriate AWS region.

### Run Terraform plan to confirm the updates
```
$terraform plan -var-file terraform.tfvars
```
Confirm that Terraform produces a plan that you are expecting to happen.. likely to destroy the web instance(s) and create new instance(s).

### Run Terraform apply to deploy
```
$terraform apply -var-file terraform.tfvars
```
Confirm that the expected infrastructure was deployed and is live.
