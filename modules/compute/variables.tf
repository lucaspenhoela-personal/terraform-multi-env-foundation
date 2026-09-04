variable "project" {
  description = "Prefixo de nome usado em todos os recursos."
  type        = string
}

variable "environment" {
  description = "Ambiente logico (dev, staging, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment invalido. No root module ele vem do workspace ativo: rode terraform workspace select dev (ou staging, prod)."
  }
}

variable "subnet_ids" {
  description = "Mapa de AZ para ID de subnet, vindo do modulo network."
  type        = map(string)
}

variable "security_group_ids" {
  description = "Lista de security groups a anexar as instancias."
  type        = list(string)
}

variable "instance_profile_name" {
  description = "Nome do instance profile com a role das instancias."
  type        = string
}

variable "instances" {
  description = <<-DESC
    Mapa de instancias a provisionar. A chave e o nome logico da instancia
    e vira sufixo da tag Name. Os atributos marcados com optional() tem
    valor padrao e podem ser omitidos no tfvars.

    Exemplo em envs/dev.tfvars:

      instances = {
        web = {
          instance_type = "t3.micro"
        }
        worker = {
          instance_type = "t3.small"
          volume_size   = 20
          role          = "worker"
        }
      }
  DESC

  type = map(object({
    instance_type = string
    volume_size   = optional(number, 8)
    role          = optional(string, "app")
    az_index      = optional(number, 0)
  }))

  default = {}

  validation {
    condition = alltrue([
      for name, cfg in var.instances : cfg.volume_size >= 8 && cfg.volume_size <= 100
    ])
    error_message = "volume_size deve estar entre 8 e 100 GB."
  }

  validation {
    condition = alltrue([
      for name, cfg in var.instances : can(regex("^[tm][3-7][ag]?\\.", cfg.instance_type))
    ])
    error_message = "instance_type deve ser de familia t ou m (geracoes 3 a 7), para conter custo."
  }
}
