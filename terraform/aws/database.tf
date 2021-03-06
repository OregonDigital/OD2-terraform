resource "aws_security_group" "db" {
  name = "${var.application_name} databases"
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
    Name = "${var.application_name} databases"
  }
}

data "aws_ami" "db" {
  most_recent = true
  filter {
    name   = "name"
    values = ["od2-database-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["608942788372"] # ETS-Dev
}

resource "aws_instance" "db" {
  ami = "${data.aws_ami.db.id}"
  availability_zone = "us-west-2a"
  instance_type = "t2.micro"
  key_name = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.db.id}", "${aws_security_group.efs.id}"]
  subnet_id = "${aws_subnet.us-west-2a-private.id}"
  source_dest_check = false
  tags {
    Name = "${var.application_name} database"
  }
}

resource "aws_route53_record" "db" {
  zone_id = "${aws_route53_zone.prod.zone_id}"
  name = "db.${aws_route53_zone.prod.name}"
  type = "A"
  ttl = "300"
  records = ["${aws_instance.db.private_ip}"]
}

output "db_private_ip" {
  value = "${aws_instance.db.private_ip}"
}

output "db_route53_internal_hostname" {
  value = "${aws_route53_record.db.name}"
}

output "db_security_group_id" {
  value = "${aws_security_group.db.id}"
}
