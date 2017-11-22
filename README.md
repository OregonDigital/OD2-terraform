# OD2 Packer and Terraform

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

# Build the AMI
$packer build -var-file ../variables.json $BUILD_TYPE.json

# Wait for awhile and capture the AMI and output details after a successful build
```
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
