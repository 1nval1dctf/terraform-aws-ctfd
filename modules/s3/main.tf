terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.46"
    }
  }
}

data "aws_iam_policy_document" "s3_full_access" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.challenge_bucket.arn
    ]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com", "ec2.amazonaws.com"]
    }
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

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com", "ec2.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket" "challenge_bucket" {
  force_destroy = var.force_destroy_challenge_bucket
  acl           = "private"

  versioning {
    enabled = true
  }

  #tfsec:ignore:AWS017
  dynamic "server_side_encryption_configuration" {
    for_each = var.s3_encryption_key_arn != "" ? [1] : []
    content {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = var.s3_encryption_key_arn
          sse_algorithm     = "aws:kms"
        }
      }
    }
  }

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "logs/"
  }
}

resource "aws_s3_bucket_policy" "s3_full_access" {
  bucket = aws_s3_bucket.challenge_bucket.id
  policy = data.aws_iam_policy_document.s3_full_access.json
}

resource "aws_s3_bucket" "log_bucket" {
  force_destroy = var.force_destroy_log_bucket
  acl           = "log-delivery-write"

  versioning {
    enabled = true
  }

  #tfsec:ignore:AWS017
  dynamic "server_side_encryption_configuration" {
    for_each = var.s3_encryption_key_arn != "" ? [1] : []
    content {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = var.s3_encryption_key_arn
          sse_algorithm     = "aws:kms"
        }
      }
    }
  }
  #tfsec:ignore:AWS002
}
