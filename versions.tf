terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # O bloco backend NAO aceita variaveis, locals ou interpolacao. Os valores
  # precisam ser literais. Por isso os nomes aparecem hardcoded aqui, vindos
  # do output backend_config_hint do bootstrap.
  #
  # Com workspaces, o backend S3 grava o state em:
  #   env:/<workspace>/multi-env/terraform.tfstate
  # O caminho sem prefixo e reservado ao workspace default.
  backend "s3" {
    bucket         = "tfstate-lucaspenhoela-multienv"
    key            = "multi-env/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-lock-multienv"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = terraform.workspace
      ManagedBy   = "terraform"
    }
  }
}
