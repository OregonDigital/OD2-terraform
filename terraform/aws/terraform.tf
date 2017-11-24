terraform {
  backend "s3" {
    bucket = "od2-terraform-state"
    encrypt = true
    key = "terraform_state/terraform.tfstate"
    region = "us-west-2"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config {
    bucket = "od2-terraform-state"
    key = "terraform_state/terraform.tfstate"
    region = "us-west-2"
  }
}
