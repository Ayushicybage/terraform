module "network" {
  source = "./modules/network"
  vpc_cidr = var.vpc_cidr
}

module "web" {
  source = "./modules/web"
  vpc_id = module.network.vpc_id
  public_subnets = module.network.public_subnets
  key_name = var.key_name
}

module "app" {
  source = "./modules/app"
  vpc_id = module.network.vpc_id
  private_subnets = module.network.private_subnets
  key_name = var.key_name
}

module "db" {
  source = "./modules/db"
  private_subnets = module.network.private_subnets
  db_username = var.db_username
  db_password = var.db_password
}
