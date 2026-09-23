variable "project" {
  description = "Short project name used in resource naming"
  type        = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "app_sg_id" {
  type = string
}

variable "app_port" {
  description = "Port the Express API listens on"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type for the app tier"
  type        = string
}

variable "asg_min_size" {
  type = number
}

variable "asg_max_size" {
  type = number
}

variable "asg_desired_capacity" {
  type = number
}

variable "deploy_bucket_name" {
  description = "Deploy-artifacts S3 bucket name, passed into user_data"
  type        = string
}

variable "deploy_bucket_arn" {
  description = "Deploy-artifacts S3 bucket ARN, for the instance role's inline policy"
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for the RDS master credentials"
  type        = string
}

variable "db_host" {
  type = string
}

variable "db_port" {
  type = number
}

variable "db_name" {
  type = string
}
