output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the RDS master credentials (read by the app instance role, never by GitHub Actions)"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}
