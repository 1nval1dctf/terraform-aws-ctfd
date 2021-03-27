# Create a new application load balancer.
resource "aws_lb" "lb" {
  name = var.app_name
  #tfsec:ignore:AWS005
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id, aws_security_group.alb_outboud.id]
  subnets            = module.subnets.public_subnet_ids

  dynamic "access_logs" {
    for_each = var.log_bucket != "" ? [1] : []
    content {
      bucket  = var.log_bucket
      prefix  = "logs/alb/"
      enabled = true
    }
  }
}

# Create a new target group for the application load balancer.
resource "aws_alb_target_group" "group" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  # Initial deployment will 302 redirect to setup page. We should not consider
  # the instnace unhealthy in that case
  health_check {
    path    = "/"
    matcher = "200,302"
  }
}

# HTTP request 
# Prefer HTTPS if certificate_arm set and we dont have cloudfront
# In that case http requests will redirect to https
resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  #tfsec:ignore:AWS004
  protocol = "HTTP"
  # only if https_certificate_arn is NOT set OR we are creating a CDN
  count = (var.https_certificate_arn == "" || var.create_cdn == true) ? 1 : 0

  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type             = "forward"
  }
}

# forward HTTP request to HTTPS
resource "aws_alb_listener" "listener_http_forward" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"
  # only if https_certificate_arn is set and we are not creating a CDN
  count = (var.https_certificate_arn != "" && var.create_cdn != true) ? 1 : 0

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Create a new application load balancer listener for HTTPS.
resource "aws_alb_listener" "listener_https" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.https_certificate_arn
  # only if https_certificate_arn is set and we are not creating a CDN
  count = (var.https_certificate_arn != "" && var.create_cdn != true) ? 1 : 0

  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type             = "forward"
  }
}