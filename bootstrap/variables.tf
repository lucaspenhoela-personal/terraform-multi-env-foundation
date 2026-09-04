variable "aws_region" {
  description = "Regiao AWS onde o bucket de state e a tabela de lock serao criados."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = <<-DESC
    Nome do bucket S3 que armazena o remote state. Nomes de bucket sao globais
    em toda a AWS, entao precisa ser unico. Nao inclua o account ID aqui: o
    nome aparece em codigo e em capturas de tela do portfolio.
  DESC
  type        = string
  default     = "tfstate-lucaspenhoela-multienv"
}

variable "lock_table_name" {
  description = "Nome da tabela DynamoDB usada para state locking."
  type        = string
  default     = "tfstate-lock-multienv"
}
