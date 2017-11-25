resource "aws_security_group" "efs" {
  name = "${var.application_name} EFS"
  description = "Allow EFS connections."

  ingress { # NFS4 mount for EFS
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    cidr_blocks = ["${var.private_subnet_cidr}","${var.public_subnet_cidr}"]
  }

  egress { # NFS4 mount for EFS
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    cidr_blocks = ["${var.private_subnet_cidr}","${var.public_subnet_cidr}"]
  }

  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "${var.application_name} efs mounts"
  }
}

/*
 * BEWARE: (You could lose data if you're not careful making changes to this resource.)
 * Changes to this resource's properties can be destructive..
 * Terraform may identify the previous configuration as having to be destroyed before
 * creating the newly configured instance.
 */
resource "aws_efs_file_system" "efs_private" {
  creation_token = "od2-efs-private"
  tags {
    Name = "${var.application_name} efs private"
  }
}

/*
 * BEWARE: (You could lose data if you're not careful making changes to this resource.)
 * Changes to this resource's properties can be destructive..
 * Terraform may identify the previous configuration as having to be destroyed before
 * creating the newly configured instance.
 */
resource "aws_efs_file_system" "efs_public" {
  creation_token = "od2-efs-public"
  tags {
    Name = "${var.application_name} efs public"
  }
}

/*
 * BEWARE: (You could lose data if you're not careful making changes to this resource.)
 * Changes to this resource's properties can be destructive..
 * Terraform may identify the previous configuration as having to be destroyed before
 * creating the newly configured instance.
 */
resource "aws_efs_mount_target" "efs_private" {
  file_system_id = "${aws_efs_file_system.efs_private.id}"
  subnet_id      = "${aws_subnet.us-west-2a-private.id}"
  security_groups = ["${aws_security_group.efs.id}"]
}

/*
 * BEWARE: (You could lose data if you're not careful making changes to this resource.)
 * Changes to this resource's properties can be destructive..
 * Terraform may identify the previous configuration as having to be destroyed before
 * creating the newly configured instance.
 */
resource "aws_efs_mount_target" "efs_public" {
  file_system_id = "${aws_efs_file_system.efs_public.id}"
  subnet_id      = "${aws_subnet.us-west-2a-public.id}"
  security_groups = ["${aws_security_group.efs.id}"]
}

output "efs_private_mount_dns_name" {
  value = "${aws_efs_mount_target.efs_private.dns_name}"
}

output "efs_private_mount_subnet_id" {
  value = "${aws_efs_mount_target.efs_private.subnet_id}"
}

output "efs_public_mount_dns_name" {
  value = "${aws_efs_mount_target.efs_public.dns_name}"
}

output "efs_public_mount_subnet_id" {
  value = "${aws_efs_mount_target.efs_public.subnet_id}"
}

