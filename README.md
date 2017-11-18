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

### Run Packer to create a new AMI
```
$cd packer/web

# Validate the build is going to work
$packer validate -var-file ../variables.json web.json

# Build the AMI
$packer build -var-file ../variables.json web.json

# Wait for awhile and capture the AMI after a successful build
```

### Update Terraform variables
Open variables.tf and update the AMI located in the *web_amis* hash for the appropriate AWS region.

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