output "app_security_group_id" {
  description = "ID do security group da camada de aplicacao."
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "ID do security group de banco de dados."
  value       = aws_security_group.db.id
}

output "instance_profile_name" {
  description = "Nome do instance profile a ser usado pelas instancias EC2."
  value       = aws_iam_instance_profile.instance.name
}

output "instance_role_arn" {
  description = "ARN da role assumida pelas instancias."
  value       = aws_iam_role.instance.arn
}

output "ssh_ingress_enabled" {
  description = "Indica se alguma regra de SSH foi criada."
  value       = length(var.ssh_allowed_cidrs) > 0
}
