resource "aws_iam_role" "kubernetes_master_node" {
  name = "KubernetesMasterNode"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

data "aws_iam_policy_document" "kubernetes_master_node_document" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:UpdateAutoScalingGroup"
    ]

    resources = ["*"]
    
  }
}

resource "aws_iam_policy" "kubernetes_master_node_policy" {
  name   = "KubernetesMasterNodePolicy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.kubernetes_master_node_document.json}"
}

resource "aws_iam_role_policy_attachment" "kubernetes_master_attachment" {
  policy_arn = "${aws_iam_policy.kubernetes_master_node_policy.arn}"
  role       = "${aws_iam_role.kubernetes_master_node.name}"
}

resource "aws_iam_instance_profile" "kubernetes_master_node" {
  name = "KubernetesMasterNodeNodeIamProfile"
  role = "${aws_iam_role.kubernetes_master_node.name}"
}

# Master node security group
resource "aws_security_group" "master_node_sg" {
  name        = "MasterNodeSecurityGroup"
  description = "Security group for master nodes in the cluster"
  vpc_id      = "${var.vpc_id}"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${aws_elb.master_internal_elb.source_security_group_id}"]
  }

  # TODO: Tighten internal rules
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "MasterClusterSecurityGroup"
  }

}

resource "aws_security_group" "master_elb_sg" {
  name = "MasterNodeELBSecurityGroup"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 6443
    to_port = 6443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_elb" "master_internal_elb" {
  name = "MasterNodeInternalELB"
  security_groups = ["${aws_security_group.master_elb_sg.id}"]
  subnets = ["${var.master_node_subnet}"]
  internal = true

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 10
    interval = 45
    target = "HTTPS:6443/healthz"
  }

  listener {
    lb_port = 6443
    lb_protocol = "tcp"
    instance_port = "6443"
    instance_protocol = "tcp"
  }
}

resource "aws_elb" "master_elb" {
  name = "MasterNodeELB"
  security_groups = ["${aws_security_group.master_elb_sg.id}"]
  subnets = ["${var.master_node_subnet}"]
  internal = false

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 10
    interval = 45
    target = "HTTPS:6443/healthz"
  }

  listener {
    lb_port = 6443
    lb_protocol = "tcp"
    instance_port = "6443"
    instance_protocol = "tcp"
  }
}

data "template_file" "init" {
  template = "${file("user-data/${var.user_data_file}")}"

  vars {
    bootstrapToken = "${var.bootstrap_token}"
    internalDNS    = "${lower(aws_elb.master_internal_elb.dns_name)}"
    externalDNS    = "${lower(aws_elb.master_elb.dns_name)}"
  }
}

# Master node spot ASG
resource "aws_launch_configuration" "master_launch_configuration" {
  image_id                    = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  name_prefix                 = "master"
  security_groups             = ["${aws_security_group.master_node_sg.id}"]
  user_data                   = "${data.template_file.init.rendered}"
  spot_price                  = "${var.spot_price}"
  iam_instance_profile        = "${aws_iam_instance_profile.kubernetes_master_node.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "master_autoscaling_group" {
  desired_capacity      = "${var.target_capacity}"
  launch_configuration  = "${aws_launch_configuration.master_launch_configuration.id}"
  max_size              = "${var.max_target_capacity}"
  min_size              = 1
  name                  = "master-asg"
  vpc_zone_identifier   = ["${var.master_node_subnet}"]
  load_balancers        = ["${aws_elb.master_internal_elb.name}","${aws_elb.master_elb.name}"]
  health_check_type     = "ELB"

  tag {
    key                 = "Name"
    value               = "master-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

}

