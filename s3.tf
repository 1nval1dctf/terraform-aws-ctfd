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
  acl           = "public-read"
  force_destroy = var.force_destroy_challenge_bucket
}

resource "aws_s3_bucket_policy" "s3_full_access" {
  bucket = aws_s3_bucket.challenge_bucket.id
  policy = data.aws_iam_policy_document.s3_full_access.json
}