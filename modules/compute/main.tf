locals {
  name_prefix = "${var.project}-${var.environment}"

  # Lista ordenada de AZs disponiveis, derivada das chaves do mapa de subnets.
  # keys() em mapa retorna sempre em ordem lexicografica, entao o resultado
  # e deterministico entre execucoes.
  azs = keys(var.subnet_ids)

  # Resolve, para cada instancia, em qual subnet ela vai. O modulo do resto
  # (%) garante que um az_index maior que o numero de AZs nao estoure o
  # indice; ele apenas volta ao inicio da lista.
  instance_subnets = {
    for name, cfg in var.instances :
    name => var.subnet_ids[local.azs[cfg.az_index % length(local.azs)]]
  }
}

# AMI resolvida em tempo de plan. Nunca hardcode ID de AMI: ele muda a cada
# release e e diferente em cada regiao.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "this" {
  for_each = var.instances

  ami           = data.aws_ami.al2023.id
  instance_type = each.value.instance_type
  subnet_id     = local.instance_subnets[each.key]

  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.instance_profile_name

  # Sem key_name de proposito: o acesso e via SSM Session Manager. Nao existe
  # chave privada para vazar nem porta 22 aberta.

  root_block_device {
    volume_size           = each.value.volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # IMDSv2 obrigatorio. Com "required", o metadata service exige um token
  # obtido por PUT, o que bloqueia a classe de ataque SSRF que le credenciais
  # da instancia por um simples GET. E o item de seguranca que auditoria de
  # EC2 mais aponta.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring = false

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    environment   = var.environment
    instance_role = each.value.role
  })

  tags = {
    Name = "${local.name_prefix}-${each.key}"
    Role = each.value.role
  }

  lifecycle {
    # Impede que uma nova release de AMI force recriacao da instancia em
    # todo plan. Atualizacao de AMI passa a ser uma acao deliberada.
    ignore_changes = [ami]
  }
}
