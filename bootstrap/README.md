bootstrap

Cria a infraestrutura do remote state do root module: um bucket S3 versionado
e criptografado, e uma tabela DynamoDB para state locking.

Este diretorio usa state LOCAL de proposito. E o problema do ovo e da galinha:
o backend S3 exige que o bucket exista antes do primeiro terraform init, entao
alguem precisa criar esse bucket sem usar backend remoto.

Aplicado uma unica vez:

  cd bootstrap
  terraform init
  terraform plan
  terraform apply

Depois do apply, o arquivo terraform.tfstate deste diretorio nao e versionado
(esta no .gitignore da raiz). Se ele for perdido, os recursos continuam
existindo na AWS e podem ser reimportados com terraform import.

O bucket tem prevent_destroy = true. Para remove-lo de proposito, comente o
bloco lifecycle, rode terraform apply, esvazie o bucket e so entao destrua.

Alternativa mais recente

  A partir do Terraform 1.10 o backend S3 faz locking nativo via arquivo de
  lock no proprio bucket (use_lockfile = true), dispensando o DynamoDB. Este
  projeto usa DynamoDB por ser o padrao de referencia da certificacao.
