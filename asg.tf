data "aws_ami" "ubuntu-2004" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}
data "aws_ami" "ubuntu-2004-arm" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-*"]
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

  statement {
    actions = [
      "ec2:DescribeTags",
      "cloudwatch:PutMetricData",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroup"
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

module "autoscale_group" {
  source                                 = "cloudposse/ec2-autoscale-group/aws"
  name                                   = var.launch_configuration_name_prefix
  image_id                               = length(regexall("[g]+", var.asg_instance_type)) > 0 ? data.aws_ami.ubuntu-2004-arm.id : data.aws_ami.ubuntu-2004.id
  instance_type                          = var.asg_instance_type
  security_group_ids                     = [aws_security_group.asg_outboud.id, aws_security_group.outbound.id, aws_security_group.asg.id]
  subnet_ids                             = module.subnets.private_subnet_ids
  min_size                               = var.asg_min_size
  max_size                               = var.asg_max_size
  target_group_arns                      = [aws_alb_target_group.group.arn]
  associate_public_ip_address            = true
  user_data_base64                       = data.template_cloudinit_config.config.rendered
  enabled_metrics                        = ["GroupTerminatingInstances", "GroupMaxSize", "GroupDesiredCapacity", "GroupPendingInstances", "GroupInServiceInstances", "GroupMinSize", "GroupTotalInstances"]
  iam_instance_profile_name              = aws_iam_instance_profile.asg.name
  ebs_optimized                          = true
  autoscaling_policies_enabled           = true
  cpu_utilization_high_threshold_percent = 70
  cpu_utilization_low_threshold_percent  = 20
  tags = {
    Name = "${var.app_name}-autoscaling-group"
  }
}
