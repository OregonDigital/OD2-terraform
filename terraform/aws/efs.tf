resource "aws_security_group" "efs" {
  name = "${var.application_name} EFS"
  description = "Allow EFS connections."

  ingress { # NFS4 mount for EFS
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    cidr_blocks = ["${var.private_subnet_cidr}"]
  }

  egress { # NFS4 mount for EFS
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    cidr_blocks = ["${var.private_subnet_cidr}"]
  }

  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "${var.application_name} efs mounts"
  }
}

resource "aws_efs_file_system" "efs" {
  creation_token = "od2-efs"
  tags {
    Name = "${var.application_name} efs"
  }
}

resource "aws_efs_mount_target" "efs" {
  file_system_id = "${aws_efs_file_system.efs.id}"
  subnet_id      = "${aws_subnet.us-west-2a-private.id}"
  security_groups = ["${aws_security_group.efs.id}"]
}

output "efs_mount_dns_name" {
  value = "${aws_efs_mount_target.efs.dns_name}"
}

output "efs_mount_subnet_id" {
  value = "${aws_efs_mount_target.efs.subnet_id}"
}
