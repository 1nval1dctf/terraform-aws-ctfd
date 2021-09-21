terraform {
  required_version = ">= 1.0.0"
}

locals {
  cache_behavior = {
    viewer_protocol_policy      = "redirect-to-https"
    cached_methods              = ["GET", "HEAD"]
    allowed_methods             = ["GET", "HEAD"]
    default_ttl                 = 15
    min_ttl                     = 0
    max_ttl                     = 86400
    compress                    = true
    target_origin_id            = var.app_name
    forward_cookies             = "none"
    forward_header_values       = [] # will cache everything
    lambda_function_association = []
    cache_policy_id             = ""
    origin_request_policy_id    = ""
  }
}

module "cdn" {
  source                          = "cloudposse/cloudfront-cdn/aws"
  version                         = "0.21.3"
  attributes                      = [var.app_name]
  aliases                         = var.ctf_domain != "" ? [var.ctf_domain] : []
  origin_domain_name              = var.origin_domain_name
  origin_protocol_policy          = "http-only"
  viewer_protocol_policy          = "redirect-to-https"
  parent_zone_id                  = var.ctf_domain_zone_id
  default_root_object             = "/"
  acm_certificate_arn             = var.https_certificate_arn
  forward_cookies                 = "all"
  forward_headers                 = ["*"] # default don't cache
  forward_query_string            = true
  default_ttl                     = 15
  min_ttl                         = 0
  max_ttl                         = 86400
  compress                        = true
  cached_methods                  = ["GET", "HEAD"]
  price_class                     = "PriceClass_All"
  log_bucket_fqdn                 = var.log_bucket
  logging_enabled                 = true
  viewer_minimum_protocol_version = "TLSv1.2_2021"

  ordered_cache = [
    # cache themes, dont forward query params
    merge(local.cache_behavior, { path_pattern = "themes/*" }, { forward_query_string = false }),
    # cache files, do forward query params (needed for protected file requests)
    merge(local.cache_behavior, { path_pattern = "files/*" }, { forward_query_string = true }),
  ]
}