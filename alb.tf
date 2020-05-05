# Create a new application load balancer.
resource "aws_lb" "lb" {
  name               = var.app_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id, aws_security_group.alb_outboud.id]
  subnets            = module.subnets.public_subnet_ids
}

# Create a new target group for the application load balancer.
resource "aws_alb_target_group" "group" {
  port      = 80
  protocol  = "HTTP"
  vpc_id    = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  # Initial deployment will 302 redirect to setup page. We should not consider
  # the instnace unhealthy in that case
  health_check {
    path = "/"
    matcher = "200,302"
  }
}

# HTTP request 
# Prefer HTTPS if certificate_arm set
# In that case http requests will redirect to https
resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"
  # only if certificate_arm is NOT set
  count             = var.https_certificate_arn != "" ? 0 : 1

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
  # only if certificate_arm is set
  count             = var.https_certificate_arn != "" ? 1 : 0

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
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.https_certificate_arn
  # only if certificate_arm is set
  count             = var.https_certificate_arn != "" ? 1 : 0

  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type             = "forward"
  }
}