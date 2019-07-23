variable "spot_price" {
  description = "The maximum bid price per unit hour."
}
variable "target_capacity" {
  description = "The number of units to request."
}
variable "instance_type" {
  description = "The type of instance to start. Updates to this field will trigger a stop/start of the EC2 instance."
}
variable "key_name" {
  description = "The key name of the Key Pair to use for the instance."
}
variable "root_ebs_size" {
  description = "The size of the volume in gigabytes."
}
variable "user_data_file" {
  description = "The user data to provide when launching the instance."
}
variable "fleet_role_arn" {
  description = "Grants the Spot fleet permission to terminate Spot instances on your behalf."
}

variable "ami_id" {
  description = "The AMI to use for the instance."
}

variable "cluster_name" {
  description = "Cluster name."
}

variable "vpc_id" {
  description = "CIDR to be used for VPC"
}

variable "worker_node_subnet" {
  type = "list"
  description = "Private subnet to launch worker nodes"
}

variable "master_elb_dns" {
  description = "Internal ELB DNS for master node(s) communication"
}

variable "bootstrap_token" {
  description = "Secret token used to bootstrap the cluster"
}

variable "master_node_sg" {
  description = "Master security group to attach to worker securituy groups"
}

variable "max_target_capacity" {
  description = "Maximum allow instanced in the autoscaling group"
}