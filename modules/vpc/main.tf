locals {
  cluster_tags = "${map(
    "kubernetes.io/cluster/${var.cluster_name}", "shared"
  )}"
}

data "aws_caller_identity" "current" {}

resource "aws_vpc" "this" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "${var.cluster_name}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = "${aws_vpc.this.id}"

  tags {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_subnet" "private" {
  count             = "${length(var.private_az_subnet_mapping)}"
  vpc_id            = "${aws_vpc.this.id}"
  cidr_block        = "${lookup(var.private_az_subnet_mapping[count.index], "cidr")}"
  availability_zone = "${lookup(var.private_az_subnet_mapping[count.index], "az")}"

  tags = "${merge(
    local.cluster_tags,
    map(
      "Name", "${lookup(var.private_az_subnet_mapping[count.index], "name")}",
      "Tier", "private"
    )
  )}"
}

resource "aws_subnet" "public" {
  count                   = "${length(var.public_az_subnet_mapping)}"
  vpc_id                  = "${aws_vpc.this.id}"
  cidr_block              = "${lookup(var.public_az_subnet_mapping[count.index], "cidr")}"
  availability_zone       = "${lookup(var.public_az_subnet_mapping[count.index], "az")}"
  map_public_ip_on_launch = true

  tags = "${merge(
    local.cluster_tags,
    map(
      "Name", "${lookup(var.public_az_subnet_mapping[count.index], "name")}",
      "Tier", "public"
    )
  )}"
}

resource "aws_route" "public_internet_access" {
  route_table_id         = "${aws_vpc.this.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.this.id}"
}
