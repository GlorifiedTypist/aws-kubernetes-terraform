variable "vpc_cidr" {
  description = "CIDR to be used for VPC"
}

variable "private_az_subnet_mapping" {
  type        = "list"
  description = "Lists the private subnets to be created in their respective AZ."
}

variable "public_az_subnet_mapping" {
  type        = "list"
  description = "Lists the public subnets to be created in their respective AZ."
}

variable "cluster_name" {
  description = "Cluster name."
}
