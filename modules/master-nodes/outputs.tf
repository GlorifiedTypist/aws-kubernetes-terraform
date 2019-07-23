output "master_elb_dns" {
  value = "${aws_elb.master_internal_elb.dns_name}"
}

output "master_node_sg" {
  value = "${aws_security_group.master_node_sg.id}"
}