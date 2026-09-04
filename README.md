terraform-multi-env-foundation

Infraestrutura AWS multi-ambiente (dev, staging, prod) provisionada com um
unico conjunto de codigo Terraform, variando apenas os arquivos de variaveis
por ambiente. Projeto de portfolio com foco nos topicos do HashiCorp Terraform
Associate.

O que este repositorio demonstra

  - Modulos reutilizaveis com interface tipada e validacao de entrada
  - Remote state em S3 com locking, criado por um Terraform de bootstrap
  - Workspaces como mecanismo de separacao de ambientes, e seus limites
  - for_each sobre mapas de objetos, com optional() e defaults
  - Validacao preventiva: configuracoes insegura ou caras sao impossiveis
    de aplicar, nao apenas desaconselhadas
  - Pipeline de validacao em pull request autenticando por OIDC, sem
    nenhuma credencial de longa duracao armazenada
  - Decisoes de arquitetura registradas como ADRs, incluindo as que
    surgiram de falhas reais durante a implementacao

Estrutura

  bootstrap/          state remoto e role OIDC do CI (state local, apply unico)
  modules/network/    VPC, subnets publicas e privadas, route tables, IGW
  modules/security/   security groups e IAM role para SSM
  modules/compute/    EC2 provisionada por for_each sobre mapa tipado
  envs/               dev.tfvars, staging.tfvars, prod.tfvars
  docs/adr/           registros de decisao de arquitetura
  .github/workflows/  pipeline de fmt, validate e plan
  *.tf na raiz        root module que compoe os tres modulos

Como usar

  O bucket de state precisa existir antes do primeiro init da raiz. Por isso
  o bootstrap roda primeiro, com state local:

    cd bootstrap
    terraform init
    terraform apply

  Depois, na raiz:

    terraform init
    terraform workspace select dev
    terraform plan -var-file=envs/dev.tfvars

  Os workspaces dev, staging e prod usam o mesmo codigo. A unica diferenca
  entre ambientes esta nos arquivos de envs/: CIDR da VPC, numero de AZs e
  quais instancias provisionar.

Custo

  VPC, subnets, route tables, security groups, IAM roles e o provider OIDC
  nao geram custo. O bucket de state e a tabela DynamoDB on-demand geram
  custo minimo pelo volume deste projeto.

  Dois recursos geram custo relevante e estao desabilitados por padrao:

    enable_nat_gateway = false   NAT Gateway: cobranca por hora e por GB
    instances          = {}      EC2: free tier expirado nesta conta

  O modulo compute e validado por terraform plan. Nenhuma instancia fica em
  execucao entre sessoes de trabalho.

Validacao preventiva

  Algumas configuracoes falham no plan, antes de qualquer chamada a AWS:

    ssh_allowed_cidrs contendo 0.0.0.0/0     SSH aberto ao mundo
    instance_type fora das familias t e m    contencao de custo
    volume_size fora da faixa 8 a 100 GB     contencao de custo
    vpc_cidr sem mascara /16                 o calculo de subnets depende disso
    environment fora de dev/staging/prod     protege contra o workspace default

  A ultima tem um efeito colateral documentado: terraform validate rodando
  com -backend=false ve terraform.workspace como "default" e falha. O
  pipeline define TF_WORKSPACE=dev nesse passo.

Pipeline

  Roda em pull request para main, em dois estagios.

  O primeiro valida sem tocar na AWS: fmt -check, validate na raiz e
  validate em cada modulo isoladamente. Nao usa credencial nenhuma, entao
  erro de codigo aparece em segundos.

  O segundo roda plan nos tres ambientes em paralelo e comenta o resultado
  no PR. Autentica assumindo uma role via OIDC: o GitHub apresenta um token
  assinado, a AWS devolve credencial temporaria. Nao existe access key
  armazenada como secret. A role tem apenas permissao de leitura, mais o
  necessario para gerenciar o lock do state.

  Nao existe role de apply. Aplicar mudanca e uma acao manual, deliberada.

Decisoes de arquitetura

  docs/adr/001-workspaces.md
    Por que workspaces, e por que eles nao substituem uma conta por
    ambiente. Referencia o projeto de landing zone multi-conta.

  docs/adr/002-oidc-provider-como-data-source.md
    O provider OIDC e um singleton por conta AWS. Modelado como data
    source, nao resource, para nao sobrescrever a configuracao de outros
    repositorios que o usam.

  docs/adr/003-condicao-oidc-por-claim-repository.md
    A trust policy restringe a origem pelo claim repository em vez do sub,
    porque o sub muda de forma quando o GitHub inclui IDs numericos nos
    claims.

Nota sobre locking

  A partir do Terraform 1.10 o backend S3 suporta locking nativo
  (use_lockfile = true) e a tabela DynamoDB deixou de ser necessaria. Este
  projeto implementa a versao com DynamoDB por ser o padrao de referencia
  da certificacao, e emite um aviso de parametro depreciado a cada execucao.

Evolucao possivel

  - Launch template e Auto Scaling Group no lugar de instancias individuais
  - Estimativa de custo por pull request
  - Separacao por conta AWS em vez de workspace, conforme ADR-001
