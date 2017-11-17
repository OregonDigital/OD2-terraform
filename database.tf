resource "aws_security_group" "db" {
  name = "vpc_db"
  description = "Allow incoming database connections."

  ingress { # Postgres
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = ["${aws_security_group.web.id}"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["${var.vpc_cidr}"]
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
    Name = "database-security-group"
  }
}

resource "aws_instance" "db" {
  ami = "${lookup(var.amis, var.aws_region)}"
  availability_zone = "us-west-2a"
  instance_type = "t2.micro"
  key_name = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.db.id}"]
  subnet_id = "${aws_subnet.us-west-2a-private.id}"
  source_dest_check = false
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              EOF
  tags {
    Name = "db-server"
  }
}

output "db_private_ip" {
  value = "${aws_instance.db.private_ip}"
}

output "db_ssh_login" {
  value = "'ssh -i ${var.aws_key_path} -A ec2-user@${aws_eip.nat.public_ip}' ... then on the NAT server run 'ssh -i ${var.aws_key_path} ec2-user@${aws_instance.db.private_ip}'"
}
