variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {}
variable "aws_key_name" {}
variable "aws_s3_bucket_name" {}

variable "aws_region" {
  description = "EC2 Region for VPC"
  default = "us-west-2"
}

variable "web_amis" {
  description = "AMIs by region"
  default = {
    us-west-2 = "ami-f1459689" # OD2 Web
  }
}

variable "db_amis" {
  description = "AMIs by region"
  default = {
    us-west-2 = "ami-30ce1148" # Postgres db
  }
}

variable "vpc_amis" {
  description = "VPC AMIs by region"
  default = {
    us-west-2 = "ami-0b707a72"
  }
}

variable "application_name" {
  description = "Application name used to help with names of related resources or tags"
  default = "od2"
}

variable "app_port" {
  description = "The port the server will use for HTTP requests"
  default = 80
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
    description = "CIDR for the Public Subnet"
    default = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
    description = "CIDR for the Private Subnet"
    default = "10.0.1.0/24"
}
