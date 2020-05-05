data "aws_ami" "ubuntu-1804" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical
}

# Allows s3 actions on the challenge bucket, also ssm as per https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-quick-setup.html#quick-setup-instance-profile
data "aws_iam_policy_document" "asg" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.challenge_bucket.arn
    ]
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.challenge_bucket.arn}/*"
    ]
  }

  statement {
    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]

    resources = [
      "*"
    ]
  }
}
resource "aws_iam_role" "asg" {

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "asg" {
  role = aws_iam_role.asg.name
}

resource "aws_iam_role_policy" "asg" {
  role   = aws_iam_role.asg.id
  policy = data.aws_iam_policy_document.asg.json
}

# Create a new EC2 launch configuration to be used with the autoscaling group.
resource "aws_launch_configuration" "lc" {
  name_prefix                 = var.launch_configuration_name_prefix
  image_id                    = data.aws_ami.ubuntu-1804.id
  instance_type               = var.asg_instance_type
  user_data_base64            = data.template_cloudinit_config.config.rendered
  associate_public_ip_address = true
  security_groups             = [aws_security_group.asg_outboud.id, aws_security_group.outbound.id, aws_security_group.asg.id]
  iam_instance_profile        = aws_iam_instance_profile.asg.name

  lifecycle {
    # do this because we use aws_launch_configuration with autoscaling group
    create_before_destroy = true
  }
}

# Create the autoscaling group.
resource "aws_autoscaling_group" "asg" {
  launch_configuration = aws_launch_configuration.lc.name
  vpc_zone_identifier  = module.subnets.private_subnet_ids
  name                 = "${var.app_name}-${aws_launch_configuration.lc.name}"
  min_size             = var.asg_min_size
  max_size             = var.asg_max_size
  target_group_arns    = [aws_alb_target_group.group.arn]
  enabled_metrics      = ["GroupTerminatingInstances", "GroupMaxSize", "GroupDesiredCapacity", "GroupPendingInstances", "GroupInServiceInstances", "GroupMinSize", "GroupTotalInstances"]

  tag {
    key                 = "Name"
    value               = "${var.app_name}-autoscaling-group"
    propagate_at_launch = "true"
  }

  lifecycle {
    # do this because we use aws_launch_configuration
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "default" {
  alb_target_group_arn   = aws_alb_target_group.group.arn
  autoscaling_group_name = aws_autoscaling_group.asg.id
}
