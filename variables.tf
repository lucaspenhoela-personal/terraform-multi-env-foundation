variable "aws_region" {
  description = "Regiao AWS de destino."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefixo de nome dos recursos."
  type        = string
  default     = "multienv"
}

variable "vpc_cidr" {
  description = "CIDR /16 da VPC deste ambiente."
  type        = string
}

variable "az_count" {
  description = "Numero de AZs a utilizar neste ambiente."
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Cria NAT Gateway. Gera custo. Mantenha false."
  type        = bool
  default     = false
}
