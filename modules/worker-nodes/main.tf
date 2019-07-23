resource "aws_iam_role" "kubernetes_worker_node" {
  name = "KubernetesWorkerNode"

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

# Worker IAM policy
data "aws_iam_policy_document" "kubernetes_worker_node_document" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:DescribeVolumes",
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:DescribeSubnets",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateTags",
      "ec2:DescribeRouteTables"
    ]

    resources = ["*"]
    
  }
}

resource "aws_iam_policy" "kubernetes_worker_node_policy" {
  name   = "KubernetesWorkerNodePolicy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.kubernetes_worker_node_document.json}"
}

resource "aws_iam_role_policy_attachment" "kubernetes_worker_attachment" {
  policy_arn = "${aws_iam_policy.kubernetes_worker_node_policy.arn}"
  role       = "${aws_iam_role.kubernetes_worker_node.name}"
}

resource "aws_iam_role_policy_attachment" "kubernetes_route53_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  role       = "${aws_iam_role.kubernetes_worker_node.name}"
}

resource "aws_iam_role_policy_attachment" "kubernetes_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.kubernetes_worker_node.name}"
}

resource "aws_iam_role_policy_attachment" "kubernetes_ec2_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role       = "${aws_iam_role.kubernetes_worker_node.name}"
}

resource "aws_iam_instance_profile" "kubernetes_worker_node" {
  name = "KubernetesWorkerNodeNodeIamProfile"
  role = "${aws_iam_role.kubernetes_worker_node.name}"
}


# Worker node security group
resource "aws_security_group" "worker_node_sg" {
  name        = "WorkerNodeSecurityGroup"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "WorkerNodeSecurityGroup",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "worker_node_ingress_self" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.worker_node_sg.id}"
  source_security_group_id = "${aws_security_group.worker_node_sg.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "master_to_worker_node_ingress" {
  description              = "Allow master nodes to communicate with worker nondes"
  from_port                = 1025
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.worker_node_sg.id}"
  source_security_group_id = "${var.master_node_sg}"
  to_port                  = 65535
  type                     = "ingress"
}

# Worker node spot ASG
resource "aws_launch_configuration" "worker_launch_configuration" {
  image_id                    = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  name_prefix                 = "worker"
  security_groups             = ["${aws_security_group.worker_node_sg.id}"]
  user_data                   = "${data.template_file.init.rendered}"
  spot_price                  = "${var.spot_price}"
  key_name                    = "${var.key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.kubernetes_worker_node.name}"
  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "init" {
  template = "${file("user-data/${var.user_data_file}")}"

  vars {
    bootstrap_token = "${var.bootstrap_token}"
    masterIP        = "${var.master_elb_dns}"
  }
}

resource "aws_autoscaling_group" "kubernetes_autoscaling_group" {
  desired_capacity      = "${var.target_capacity}"
  launch_configuration  = "${aws_launch_configuration.worker_launch_configuration.id}"
  max_size              = "${var.max_target_capacity}"
  min_size              = 1
  name                  = "worker-asg"
  vpc_zone_identifier   = ["${var.worker_node_subnet}"]

  tag {
    key                 = "Name"
    value               = "worker-node"
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
