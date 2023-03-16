variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "internal_appl_port" {
  description = "Internal port used by Appl"
  type = number
  sensitive = false
  default = 8000
}

variable "external_appl_port" {
  description = "External port used by Appl"
  type = number
  sensitive = false
  default = 80
}