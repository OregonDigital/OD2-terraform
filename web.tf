
resource "aws_security_group" "web" {
  name = "vpc web"
  ingress { # Custom port for the application, maybe.
    from_port = "${var.app_port}"
    to_port = "${var.app_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { # HTTP
    from_port = "80"
    to_port = "80"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { # HTTPS
    from_port = "443"
    to_port = "443"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { # SSH
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { # HTTP
    from_port = "80"
    to_port = "80"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { # HTTPS
    from_port = "443"
    to_port = "443"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { # Postgres
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["${var.private_subnet_cidr}"]
  }
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "web-security-group"
  }
}

resource "aws_instance" "web" {
  ami = "${lookup(var.amis, var.aws_region)}"
  instance_type = "t2.micro"
  availability_zone = "us-west-2a"
  subnet_id = "${aws_subnet.us-west-2a-public.id}"
  associate_public_ip_address = true
  source_dest_check = false
  key_name = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y busybox
              echo "ETS Terraformed shizniz" > index.html
              sudo nohup busybox httpd -f -p "${var.app_port}" &
              EOF
  tags {
    Name = "web-server"
  }
}

resource "aws_eip" "web" {
  instance = "${aws_instance.web.id}"
  vpc = true
}

output "web_public_http" {
  value = "http://${aws_eip.web.public_ip}"
}

output "web_public_ssh" {
  value = "ssh -i ${var.aws_key_path} -A ec2-user@${aws_eip.web.public_ip}"
}
