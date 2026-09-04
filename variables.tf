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

variable "ssh_allowed_cidrs" {
  description = "CIDRs autorizados a SSH. Vazio por padrao; prefira SSM."
  type        = list(string)
  default     = []
}

variable "enable_ssm_access" {
  description = "Habilita acesso via SSM Session Manager nas instancias."
  type        = bool
  default     = true
}

variable "instances" {
  description = <<-DESC
    Mapa de instancias EC2 a provisionar. Vazio por padrao: EC2 gera custo
    nesta conta. Ver modules/compute/variables.tf para o formato.
  DESC

  type = map(object({
    instance_type = string
    volume_size   = optional(number, 8)
    role          = optional(string, "app")
    az_index      = optional(number, 0)
  }))

  default = {}
}
