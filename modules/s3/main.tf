terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
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
      identifiers = ["ecs.amazonaws.com", "s3.amazonaws.com", "ec2.amazonaws.com"]
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
      identifiers = ["ecs.amazonaws.com", "s3.amazonaws.com", "ec2.amazonaws.com"]
    }
  }
}

#tfsec:ignore:AWS017
#tfsec:ignore:AWS002
resource "aws_s3_bucket" "challenge_bucket" {
  force_destroy = var.force_destroy_challenge_bucket

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
}

resource "aws_s3_bucket_ownership_controls" "challenge_bucket" {
  bucket = aws_s3_bucket.challenge_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "challenge_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.challenge_bucket]
  bucket     = aws_s3_bucket.challenge_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_versioning" "challenge_bucket" {
  bucket = aws_s3_bucket.challenge_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "challenge_bucket" {
  bucket     = aws_s3_bucket.challenge_bucket.id
  policy     = data.aws_iam_policy_document.s3_full_access.json
  depends_on = [aws_s3_bucket.challenge_bucket]
}

resource "aws_s3_bucket_public_access_block" "challenge_bucket" {
  bucket                  = aws_s3_bucket.challenge_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket_policy.challenge_bucket]
}
