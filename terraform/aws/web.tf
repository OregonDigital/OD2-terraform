
resource "aws_security_group" "web" {
  name = "${var.application_name} web server"
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
    Name = "${var.application_name} web server"
  }
}

# File must be a text/* content-type, see/update metadata for object in S3
data "aws_s3_bucket_object" "local_env" {
  bucket = "${var.aws_s3_bucket_name}"
  key    = "data0/hydra/shared/config/local_env.yml"
}

resource "aws_instance" "web" {
  ami = "${lookup(var.web_amis, var.aws_region)}"
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
              echo "${data.aws_s3_bucket_object.local_env.body}" >> /data0/hydra/shared/config/local_env.yml
              EOF
  tags {
    Name = "${var.application_name} web server"
  }
}

resource "aws_eip" "web" {
  instance = "${aws_instance.web.id}"
  vpc = true
}

resource "aws_route53_record" "web" {
  zone_id = "${aws_route53_zone.prod.zone_id}"
  name = "web.${aws_route53_zone.prod.name}"
  type = "A"
  ttl = "300"
  records = ["${aws_eip.web.private_ip}"]
}

output "web_public_http" {
  value = "http://${aws_eip.web.public_ip}"
}

output "web_public_ssh" {
  value = "ssh -i ${var.aws_key_path} -A ec2-user@${aws_eip.web.public_ip}"
}

output "web_route53_internal_hostname" {
  value = "${aws_route53_record.web.name}"
}
