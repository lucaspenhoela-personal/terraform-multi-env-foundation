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

variable "vpc_id" {
  description = "ID da VPC onde os security groups serao criados."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR da VPC, usado para restringir trafego interno."
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = <<-DESC
    Lista de CIDRs autorizados a abrir SSH nas instancias. Lista vazia
    significa que nenhuma regra de SSH e criada, que e o padrao.
    NUNCA use 0.0.0.0/0 aqui. A validacao abaixo bloqueia esse valor.
  DESC
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.ssh_allowed_cidrs, "0.0.0.0/0")
    error_message = "SSH aberto para 0.0.0.0/0 nao e permitido. Use um CIDR especifico ou prefira SSM Session Manager."
  }
}

variable "enable_ssm_access" {
  description = <<-DESC
    Anexa a policy gerenciada AmazonSSMManagedInstanceCore a role das
    instancias, permitindo acesso via Session Manager sem porta 22 aberta
    e sem chave SSH.
  DESC
  type        = bool
  default     = true
}
