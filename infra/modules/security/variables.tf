variable "project" {
  description = "Short project name used in resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC these security groups belong to"
  type        = string
}

variable "app_port" {
  description = "Port the Express API listens on"
  type        = number
}
