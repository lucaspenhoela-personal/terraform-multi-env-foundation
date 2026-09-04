# Data source: consulta a AWS em tempo de plan em vez de criar recurso.
# Os nomes de AZ variam por conta e regiao, entao nao devem ser hardcoded.
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = "${var.project}-${var.environment}"

  # slice pega apenas as primeiras az_count zonas da lista retornada.
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Expressoes "for" transformam a lista de AZs em mapas indexados pelo nome
  # da AZ. for_each exige map ou set, nunca lista.
  # cidrsubnet(prefix, newbits, num): a partir de um /16, somando 8 bits,
  # gera /24. Publicas usam os indices 0,1,2; privadas 100,101,102, para
  # deixar espaco de crescimento entre os dois grupos.
  public_subnets = {
    for idx, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, idx)
  }

  private_subnets = {
    for idx, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 100)
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# for_each cria uma instancia do recurso por entrada do mapa. Cada uma recebe
# um endereco estavel no state: aws_subnet.public["us-east-1a"].
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "${local.name_prefix}-private-${each.key}"
    Tier = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.name_prefix}-rt-public"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Uma unica route table privada. Sem NAT ela nao tem rota de saida, o que e
# proposital: as subnets privadas ficam realmente sem internet.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-rt-private"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# --- NAT Gateway: opcional e desligado por padrao (gera custo) ---

# count com expressao condicional e o idioma para recurso liga/desliga.
# for_each seria errado aqui: nao ha multiplas instancias, ha zero ou uma.
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-eip-nat"
  }
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = values(aws_subnet.public)[0].id

  tags = {
    Name = "${local.name_prefix}-nat"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}
