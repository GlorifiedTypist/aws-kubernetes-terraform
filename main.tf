provider "aws" {
  region = "eu-west-1"
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["spotfleet.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance-role" {
  name               = "SpotInstanceRole"
  assume_role_policy = "${data.aws_iam_policy_document.instance-assume-role-policy.json}"
}

resource "aws_iam_role_policy_attachment" "spotfleet-policy-attachment" {
  role = "${aws_iam_role.instance-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

module "vpc" {
  source                    = "./modules/vpc"
  
  vpc_cidr                  = "${var.vpc_cidr}"
  cluster_name              = "${var.cluster_name}"
  private_az_subnet_mapping = "${var.private_az_subnet_mapping}"
  public_az_subnet_mapping  = "${var.public_az_subnet_mapping}"
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}

module "master_nodes" {
  source              = "./modules/master-nodes/"
  
  spot_price          = "0.0138"
  target_capacity     = 1
  max_target_capacity = 1
  instance_type       = "t3.medium"
  ami_id              = "${data.aws_ami.ubuntu.id}"
  key_name            = "bootstrap_pem"
  root_ebs_size       = 12
  user_data_file      = "master-user-data.sh"
  fleet_role_arn      = "${aws_iam_role.instance-role.arn}"
  vpc_id              = "${module.vpc.vpc_id}"
  vpc_cidr            = "${module.vpc.vpc_cidr_block}"
  cluster_name        = "${var.cluster_name}"
  master_node_subnet  = "${module.vpc.vpc_public_subnets}"
  bootstrap_token     = "000000.0000000000000000"
}

module "worker_nodes" {
  source              = "./modules/worker-nodes"
  
  spot_price          = "0.0079"
  target_capacity     = 2
  max_target_capacity = 2
  instance_type       = "m3.medium"
  ami_id              = "${data.aws_ami.ubuntu.id}"
  key_name            = "bootstrap_pem"
  root_ebs_size       = 12
  user_data_file      = "worker-user-data.sh"
  fleet_role_arn      = "${aws_iam_role.instance-role.arn}"
  vpc_id              = "${module.vpc.vpc_id}"
  cluster_name        = "${var.cluster_name}"
  worker_node_subnet  = "${module.vpc.vpc_public_subnets}"
  master_elb_dns      = "${module.master_nodes.master_elb_dns}"
  master_node_sg      = "${module.master_nodes.master_node_sg}"
  bootstrap_token     = "000000.0000000000000000"
}

