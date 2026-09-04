output "workspace" {
  description = "Workspace ativo, equivalente ao ambiente."
  value       = terraform.workspace
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "app_security_group_id" {
  value = module.security.app_security_group_id
}

output "db_security_group_id" {
  value = module.security.db_security_group_id
}

output "instance_profile_name" {
  value = module.security.instance_profile_name
}

output "instance_ids" {
  value = module.compute.instance_ids
}

output "ami_id" {
  value = module.compute.ami_id
}
