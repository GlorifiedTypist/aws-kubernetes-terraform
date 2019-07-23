/*
output "worker_nodes_private_ips" {
  value = ["${data.aws_instances.worker_node_ips.private_ips}"]
}

output "worker_nodes_public_ips" {
  value = ["${data.aws_instances.worker_node_ips.public_ips}"]
}
*/

output "worker_node_security_group" {
  value = "${aws_security_group.worker_node_sg.id}"
}