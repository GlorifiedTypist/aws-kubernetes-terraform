output "vpc_id" {
  value = "${aws_vpc.this.id}"
}

output "vpc_main_route_table_id" {
  value = "${aws_vpc.this.main_route_table_id}"
}

output "vpc_cidr_block" {
  value = "${var.vpc_cidr}"
}

output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

output "vpc_public_subnets" {
  value = ["${aws_subnet.public.*.id}"]
}

output "vpc_private_subnets" {
  value = ["${aws_subnet.private.*.id}"]
}
