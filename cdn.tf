locals {
  nocache_behavior = {
    viewer_protocol_policy      = "redirect-to-https"
    cached_methods              = ["GET", "HEAD"]
    allowed_methods             = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    default_ttl                 = 60
    min_ttl                     = 0
    max_ttl                     = 86400
    compress                    = true
    target_origin_id            = var.app_name
    forward_cookies             = "all"
    forward_header_values       = ["*"] # wont cache.
    forward_query_string        = true
    lambda_function_association = []
  }
}

module "cdn" {
  source                          = "cloudposse/cloudfront-cdn/aws"
  version                         = "0.15.3"
  count                           = var.create_cdn ? 1 : 0
  attributes                      = [var.app_name]
  aliases                         = var.ctf_domain != "" ? [var.ctf_domain] : []
  origin_domain_name              = aws_lb.lb.dns_name
  origin_protocol_policy          = "http-only"
  viewer_protocol_policy          = "redirect-to-https"
  parent_zone_name                = var.ctf_domain_zone_id
  default_root_object             = "/"
  acm_certificate_arn             = var.https_certificate_arn
  forward_cookies                 = "all"
  forward_headers                 = ["Host", "Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method", "csrf-token"]
  forward_query_string            = true
  default_ttl                     = 60
  min_ttl                         = 0
  max_ttl                         = 86400
  compress                        = true
  cached_methods                  = ["GET", "HEAD"]
  price_class                     = "PriceClass_All"
  log_bucket_fqdn                 = var.log_bucket
  logging_enabled                 = var.log_bucket != "" ? true : false
  viewer_minimum_protocol_version = "TLSv1.2_2019"

  ordered_cache = [
    # dont cache admin
    merge(local.nocache_behavior, map("path_pattern", "admin/*")),
    # dont cache api
    merge(local.nocache_behavior, map("path_pattern", "api/*")),
    # dont cache user and teams pages
    merge(local.nocache_behavior, map("path_pattern", "/")),
    merge(local.nocache_behavior, map("path_pattern", "register")),
    merge(local.nocache_behavior, map("path_pattern", "team")),
    merge(local.nocache_behavior, map("path_pattern", "user")),
    merge(local.nocache_behavior, map("path_pattern", "teams/*")),
    merge(local.nocache_behavior, map("path_pattern", "users/*")),
    # dont cache user settings etc.
    merge(local.nocache_behavior, map("path_pattern", "settings")),
    merge(local.nocache_behavior, map("path_pattern", "logout")),
    merge(local.nocache_behavior, map("path_pattern", "login")),
    # dont cache challenges and scoreboard.
    merge(local.nocache_behavior, map("path_pattern", "challenges")),
    merge(local.nocache_behavior, map("path_pattern", "scoreboard")),
    # dont cache notifications.
    merge(local.nocache_behavior, map("path_pattern", "events")),
    merge(local.nocache_behavior, map("path_pattern", "notifications"))
  ]
}