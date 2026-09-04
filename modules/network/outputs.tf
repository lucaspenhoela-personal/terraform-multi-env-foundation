output "vpc_id" {
  description = "ID da VPC criada."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "Bloco CIDR da VPC, para uso em regras de security group."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Mapa de AZ para ID da subnet publica."
  value       = { for az, subnet in aws_subnet.public : az => subnet.id }
}

output "private_subnet_ids" {
  description = "Mapa de AZ para ID da subnet privada."
  value       = { for az, subnet in aws_subnet.private : az => subnet.id }
}

output "nat_gateway_enabled" {
  description = "Indica se as subnets privadas tem rota de saida."
  value       = var.enable_nat_gateway
}
