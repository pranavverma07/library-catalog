module "networking" {
  source = "./modules/networking"

  project              = var.project
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security" {
  source = "./modules/security"

  project  = var.project
  vpc_id   = module.networking.vpc_id
  app_port = var.app_port
}

module "database" {
  source = "./modules/database"

  project              = var.project
  db_instance_class    = var.db_instance_class
  db_name              = var.db_name
  db_username          = var.db_username
  db_allocated_storage = var.db_allocated_storage
  private_subnet_ids   = module.networking.private_subnet_ids
  rds_sg_id            = module.security.rds_sg_id
}

module "frontend" {
  source = "./modules/frontend"

  project = var.project
}

module "storage" {
  source = "./modules/storage"

  project = var.project
}

module "compute" {
  source = "./modules/compute"

  project              = var.project
  aws_region           = var.aws_region
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  alb_sg_id            = module.security.alb_sg_id
  app_sg_id            = module.security.app_sg_id
  app_port             = var.app_port
  instance_type        = var.instance_type
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity
  deploy_bucket_name   = module.storage.bucket_name
  deploy_bucket_arn    = module.storage.bucket_arn
  db_secret_arn        = module.database.db_secret_arn
  db_host              = module.database.db_endpoint
  db_port              = module.database.db_port
  db_name              = var.db_name
}
