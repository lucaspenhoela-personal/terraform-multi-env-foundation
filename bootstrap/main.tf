# Bucket S3 que armazena o remote state do root module.
# Este diretorio usa state LOCAL de proposito: e ele que cria a
# infraestrutura de onde o state remoto vai viver.
resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

# Versionamento e a rede de seguranca do state: se um apply corromper o
# arquivo, a versao anterior continua recuperavel.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# O state guarda em texto claro tudo que o Terraform sabe, incluindo
# atributos sensiveis. Criptografia em repouso nao e opcional.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Bloqueio total de acesso publico. Um bucket de state exposto entrega o
# desenho da infraestrutura inteira.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Tabela de lock. O backend S3 grava um item aqui durante o apply; um segundo
# apply concorrente encontra o item e aborta em vez de corromper o state.
# A chave precisa se chamar exatamente LockID: e o nome que o backend usa.
resource "aws_dynamodb_table" "lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
