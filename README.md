terraform-multi-env-foundation

Infraestrutura AWS multi-ambiente (dev, staging, prod) provisionada com um
unico conjunto de codigo Terraform, variando apenas os arquivos de variaveis
por ambiente. Projeto de portfolio com foco nos topicos do HashiCorp Terraform
Associate: modulos reutilizaveis, remote state com locking, workspaces,
for_each e pipeline de validacao em pull request.

Escopo

  - Tres modulos reutilizaveis:
      network   VPC, subnets publicas e privadas, route tables, internet gateway
      security  security groups e IAM roles
      compute   instancias EC2 provisionadas dinamicamente via for_each
  - Remote state em S3 com locking em DynamoDB, criado por um Terraform de
    bootstrap separado (state local, aplicado uma unica vez).
  - Tres workspaces (dev, staging, prod) apontando para o mesmo codigo, cada um
    com seu arquivo em envs/.
  - GitHub Actions rodando fmt, validate, plan e estimativa de custo em cada
    pull request, autenticando na AWS via OIDC (sem access keys armazenadas).

Fora de escopo

  - Infraestrutura permanente. O modulo compute e validado por terraform plan;
    nenhum recurso com custo fica em execucao entre sessoes.
  - Separacao de ambientes por conta AWS. Ver docs/adr/001-workspaces.md.

Estrutura

  bootstrap/          cria bucket S3 e tabela DynamoDB do remote state
  modules/network/    modulo de rede
  modules/security/   modulo de security groups e IAM
  modules/compute/    modulo de EC2 com for_each
  envs/               dev.tfvars, staging.tfvars, prod.tfvars
  docs/adr/           registros de decisao de arquitetura
  .github/workflows/  pipeline de CI
  *.tf na raiz        root module que compoe os tres modulos

Custo

  VPC, subnets, route tables, security groups e IAM roles nao geram custo.
  NAT Gateway e EC2 geram custo e ficam desabilitados por padrao nas variaveis.
  O bucket de state e a tabela DynamoDB em modo on-demand ficam dentro do free
  tier permanente para o volume deste projeto.

Nota sobre locking

  A partir do Terraform 1.10 o backend S3 suporta locking nativo
  (use_lockfile = true) e a tabela DynamoDB deixou de ser necessaria. Este
  projeto implementa a versao com DynamoDB por ser o padrao historico e o
  conteudo de referencia da certificacao, e documenta a alternativa.

Decisoes de arquitetura

  docs/adr/001-workspaces.md  por que workspaces, e qual o limite deles
