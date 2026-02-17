output "alb_dns_name" {
  value = module.web.alb_dns_name
}

output "db_endpoint" {
  value = module.db.db_endpoint
}
