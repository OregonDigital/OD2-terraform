
resource "aws_security_group" "web" {
  name = "vpc web"
  ingress { # Custom port for the application, maybe.
    from_port = "${var.app_port}"
    to_port = "${var.app_port}"
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
  egress { # MySQL
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["${var.private_subnet_cidr}"]
  }
  tags {
    Name = "web-security-group"
  }
}

resource "aws_instance" "web" {
  ami = "${lookup(var.amis, var.aws_region)}"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  user_data = <<-EOF
              #!/bin/bash
              sudo yum install -y busybox
              echo "ETS Terraformed shizniz" > index.html
              sudo nohup busybox httpd -f -p "${var.app_port}" &
              EOF
  tags {
    Name = "web-server"
  }
}

output "public_ip" {
  value = "${aws_instance.web.public_ip}"
}
