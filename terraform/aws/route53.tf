resource "aws_route53_zone" "prod" {
  name = "od2.aws"
  vpc_id = "${aws_vpc.default.id}"
  vpc_region = "${var.aws_region}"
  tags = {
    Environment = "prod"
    Name = "od2 route53"
  }
}
