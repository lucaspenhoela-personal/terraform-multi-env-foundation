variable "project" {
  description = "Prefixo de nome usado em todos os recursos."
  type        = string
}

variable "environment" {
  description = "Ambiente logico (dev, staging, prod). Compoe o nome dos recursos."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment invalido. No root module ele vem do workspace ativo: rode terraform workspace select dev (ou staging, prod)."
  }
}

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC. Precisa ser /16 para o calculo de subnets funcionar."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && split("/", var.vpc_cidr)[1] == "16"
    error_message = "vpc_cidr precisa ser um CIDR valido com mascara /16."
  }
}

variable "az_count" {
  description = <<-DESC
    Quantas zonas de disponibilidade usar. Uma subnet publica e uma privada
    sao criadas em cada AZ. Minimo 1, maximo 3.
  DESC
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count deve estar entre 1 e 3."
  }
}

variable "enable_nat_gateway" {
  description = <<-DESC
    Cria um NAT Gateway para dar saida a internet as subnets privadas.
    ATENCAO: NAT Gateway gera custo por hora e por GB processado, sem free
    tier. Mantenha false salvo necessidade explicita.
  DESC
  type        = bool
  default     = false
}
