variable "associate" {
  type    = "string"
  default = "0"
}

variable "domain" {
  type    = "string"
}

variable "key_name" {
  type    = "string"
}

variable "region" {
  type    = "string"
  default = "us-east-1"
}

provider "aws" {
  region = "${var.region}"
}

data "aws_ami" "centos7" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }
}

resource "aws_default_vpc" "test" {}

resource "aws_default_subnet" "test" {
  availability_zone = "${var.region}a"
}

resource "aws_route53_zone" "test" {
  comment = "test"
  name    = "${var.domain}"

  vpc {
    vpc_id = "${aws_default_vpc.test.id}"
  }

  tags = {
    Name        = "test"
    Environment = "test"
  }
}

resource "aws_security_group" "test" {
  name   = "test"
  vpc_id = "${aws_default_vpc.test.id}"

  tags = {
    Name        = "test"
    Environment = "test"
  }
}

resource "aws_instance" "test" {
  ami                         = "${data.aws_ami.centos7.id}"
  associate_public_ip_address = true
  key_name                    = "${var.key_name}"
  instance_type               = "t2.nano"
  monitoring                  = false
  subnet_id                   = "${aws_default_subnet.test.id}"

  vpc_security_group_ids = [
    "${aws_security_group.test.id}",
  ]

  tags = {
    Name        = "test"
    Environment = "test"
  }
}

resource "aws_eip" "test" {
  instance = "${aws_instance.test.id}"
  vpc      = true
}

resource "aws_route53_record" "test" {
  zone_id = "${aws_route53_zone.test.zone_id}"
  name    = "test"
  type    = "A"
  ttl     = "3600"
  records = ["${aws_eip.test.private_ip}"]
}

resource "aws_eip_association" "test" {
  count = "${var.associate ? 1 : 0}"

  instance_id   = "${aws_instance.test.id}"
  allocation_id = "${aws_eip.test.id}"
}
