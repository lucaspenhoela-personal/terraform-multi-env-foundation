locals {
  name_prefix = "${var.project}-${var.environment}"
}

# --- Security group da camada de aplicacao ---

# Criado sem regras inline. As regras vem em recursos aws_vpc_security_group_*
# separados de proposito: regra inline e o recurso completo sao mutuamente
# exclusivos, e regras separadas podem ser adicionadas ou removidas sem
# recriar o security group inteiro.
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app"
  description = "Trafego da camada de aplicacao"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-sg-app"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Egress liberado para IPv4. Protocolo "-1" significa TODO protocolo e e a
# regra mais permissiva que existe na AWS. Qualquer auditoria de security
# group precisa tratar "-1" explicitamente, porque ele nao aparece com
# from_port/to_port preenchidos.
resource "aws_vpc_security_group_egress_rule" "app_all_ipv4" {
  security_group_id = aws_security_group.app.id
  description       = "Saida liberada IPv4"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# Mesma liberacao para IPv6. Um auditor que so leia cidr_ipv4 conclui,
# incorretamente, que nao ha saida liberada aqui.
resource "aws_vpc_security_group_egress_rule" "app_all_ipv6" {
  security_group_id = aws_security_group.app.id
  description       = "Saida liberada IPv6"

  ip_protocol = "-1"
  cidr_ipv6   = "::/0"
}

# Trafego HTTP apenas de dentro da VPC.
resource "aws_vpc_security_group_ingress_rule" "app_http_from_vpc" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP interno"

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = var.vpc_cidr
}

# SSH: uma regra por CIDR autorizado. for_each sobre toset porque a variavel
# e uma lista e for_each exige map ou set. Com a lista vazia (padrao),
# nenhuma regra e criada.
resource "aws_vpc_security_group_ingress_rule" "app_ssh" {
  for_each = toset(var.ssh_allowed_cidrs)

  security_group_id = aws_security_group.app.id
  description       = "SSH de ${each.value}"

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_ipv4   = each.value
}

# --- Security group de banco de dados ---

resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db"
  description = "Trafego de banco de dados"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-sg-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Referencia por security group, nao por CIDR. Assim a autorizacao acompanha
# a identidade da instancia em vez de depender do IP que ela recebeu.
# E o padrao correto para comunicacao entre camadas.
resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id = aws_security_group.db.id
  description       = "PostgreSQL a partir da camada de aplicacao"

  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.app.id
}
