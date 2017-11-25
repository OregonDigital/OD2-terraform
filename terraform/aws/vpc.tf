resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags {
    Name = "${var.application_name} vpc"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

/*
 * Packer security group for builds needing EFS mount automation
 */
resource "aws_security_group" "packer_builder" {
  name = "${var.application_name} packer"
  description = "Allow traffic necessary for packer builder"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    cidr_blocks = ["${var.private_subnet_cidr}"]
  }
  egress {
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    cidr_blocks = ["${var.private_subnet_cidr}"]
  }
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "${var.application_name} packer"
  }
}

/*
 * NAT Instance
 */
resource "aws_security_group" "nat" {
  name = "${var.application_name} vpc nat"
  description = "Allow traffic to pass from the private subnet to the internet"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.private_subnet_cidr}"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.private_subnet_cidr}"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  egress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "${var.application_name} vpc nat"
  }
}

resource "aws_instance" "nat" {
  ami = "${lookup(var.vpc_amis, var.aws_region)}" # this is a special ami preconfigured to do NAT
  availability_zone = "us-west-2a"
  instance_type = "t2.micro"
  key_name = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.nat.id}"]
  subnet_id = "${aws_subnet.us-west-2a-public.id}"
  associate_public_ip_address = true
  source_dest_check = false
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              EOF
  tags {
    Name = "${var.application_name} vpc nat"
  }
}

resource "aws_eip" "nat" {
  instance = "${aws_instance.nat.id}"
  vpc = true
}

/*
  Public Subnet
*/
resource "aws_subnet" "us-west-2a-public" {
  vpc_id = "${aws_vpc.default.id}"

  cidr_block = "${var.public_subnet_cidr}"
  availability_zone = "us-west-2a"

  tags {
    Name = "${var.application_name} public subnet"
  }
}

resource "aws_route_table" "us-west-2a-public" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "${var.application_name} public subnet"
  }
}

resource "aws_route_table_association" "us-west-2a-public" {
  subnet_id = "${aws_subnet.us-west-2a-public.id}"
  route_table_id = "${aws_route_table.us-west-2a-public.id}"
}

/*
  Private Subnet
*/
resource "aws_subnet" "us-west-2a-private" {
  vpc_id = "${aws_vpc.default.id}"

  cidr_block = "${var.private_subnet_cidr}"
  availability_zone = "us-west-2a"

  tags {
    Name = "${var.application_name} private subnet"
  }
}

resource "aws_route_table" "us-west-2a-private" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.nat.id}"
  }

  tags {
    Name = "${var.application_name} private subnet"
  }
}

resource "aws_route_table_association" "us-west-2a-private" {
  subnet_id = "${aws_subnet.us-west-2a-private.id}"
  route_table_id = "${aws_route_table.us-west-2a-private.id}"
}

output "bastion_public_ssh" {
  value = "ssh -i ${var.aws_key_path} -A ec2-user@${aws_eip.nat.public_ip}"
}

output "bastion_copy_ssh_key" {
  value = "scp -i ${var.aws_key_path} ${var.aws_key_path} ec2-user@${aws_eip.nat.public_ip}:~/.ssh/"
}

output "subnet_us_west_2a_private_id" {
  value = "${aws_subnet.us-west-2a-private.id}"
}

output "subnet_us_west_2a_public_id" {
  value = "${aws_subnet.us-west-2a-public.id}"
}

output "security_group_packer_id" {
  value = "${aws_security_group.packer_builder.id}"
}
