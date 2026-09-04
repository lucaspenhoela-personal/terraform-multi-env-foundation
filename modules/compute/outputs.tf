output "instance_ids" {
  description = "Mapa de nome logico para ID da instancia."
  value       = { for name, inst in aws_instance.this : name => inst.id }
}

output "private_ips" {
  description = "Mapa de nome logico para IP privado."
  value       = { for name, inst in aws_instance.this : name => inst.private_ip }
}

output "instance_subnets" {
  description = "Em qual subnet cada instancia foi colocada."
  value       = local.instance_subnets
}

output "ami_id" {
  description = "ID da AMI resolvida em tempo de plan."
  value       = data.aws_ami.al2023.id
}

output "instance_count" {
  description = "Quantidade de instancias provisionadas."
  value       = length(aws_instance.this)
}
