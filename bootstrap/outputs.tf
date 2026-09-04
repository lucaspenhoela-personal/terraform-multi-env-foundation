output "state_bucket_name" {
  description = "Nome do bucket a ser usado no bloco backend do root module."
  value       = aws_s3_bucket.state.id
}

output "lock_table_name" {
  description = "Nome da tabela a ser usada no bloco backend do root module."
  value       = aws_dynamodb_table.lock.name
}

output "backend_config_hint" {
  description = "Valores prontos para o bloco backend s3 do root module."
  value       = <<-HINT
    bucket         = "${aws_s3_bucket.state.id}"
    key            = "multi-env/terraform.tfstate"
    region         = "${var.aws_region}"
    dynamodb_table = "${aws_dynamodb_table.lock.name}"
    encrypt        = true
  HINT
}
