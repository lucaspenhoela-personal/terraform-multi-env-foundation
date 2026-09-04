# terraform.workspace e o nome do workspace ativo. E o mecanismo que faz o
# mesmo codigo produzir recursos distintos por ambiente.
#
# Nao existe guard de workspace aqui de proposito. A validacao da variavel
# "environment" no modulo network ja bloqueia qualquer workspace fora de
# dev/staging/prod, e validacao de variavel e avaliada ANTES de preconditions
# de recurso. Um guard baseado em precondition nunca chegaria a executar.
locals {
  environment = terraform.workspace
}

module "network" {
  source = "./modules/network"

  project            = var.project
  environment        = local.environment
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  enable_nat_gateway = var.enable_nat_gateway
}
