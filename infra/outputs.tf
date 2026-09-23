output "alb_dns_name" {
  description = "Public URL for the backend API (via ALB)"
  value       = module.compute.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "Public URL for the frontend (via CloudFront)"
  value       = module.frontend.cloudfront_domain_name
}

output "frontend_bucket" {
  value = module.frontend.bucket_name
}

output "cloudfront_distribution_id" {
  description = "Needed by the frontend CD workflow to invalidate the cache after each deploy"
  value       = module.frontend.cloudfront_distribution_id
}

output "deploy_artifacts_bucket" {
  description = "Needed by the backend CD workflow to upload app.zip + deploy.sh"
  value       = module.storage.bucket_name
}

output "db_endpoint" {
  value = module.database.db_endpoint
}

output "db_port" {
  value = module.database.db_port
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the RDS master credentials (read by the app instance role, never by GitHub Actions)"
  value       = module.database.db_secret_arn
}

output "asg_name" {
  description = "Needed by the backend CD workflow to target instances via SSM Run Command"
  value       = module.compute.asg_name
}
