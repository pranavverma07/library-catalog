output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "instance_role_arn" {
  value = aws_iam_role.app_instance.arn
}
