variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}
