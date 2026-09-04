ADR-001: Workspaces para separar ambientes

Status: aceito
Data: 2026-09-04

Contexto

  O projeto precisa provisionar dev, staging e prod com o mesmo codigo. Ha
  duas abordagens correntes:

  1. terraform workspace: um root module, um backend, um state por workspace.
     Ambientes compartilham conta AWS, credenciais e bucket de state.
  2. Um diretorio por ambiente (ou uma conta AWS por ambiente), cada um com
     seu proprio backend e suas proprias credenciais.

Decisao

  Usar workspaces.

  Motivos: e tema de avaliacao do Terraform Associate; permite custo zero
  (uma unica conta); demonstra o uso de terraform.workspace como variavel de
  interpolacao para nomear recursos por ambiente.

Consequencias e limites

  - Todos os ambientes vivem na mesma conta AWS. Um erro de IAM ou uma
    credencial vazada afeta dev e prod igualmente. Nao ha isolamento de blast
    radius nem limite de billing por ambiente.
  - Um `terraform workspace select` errado antes de um apply e um risco real.
    Mitigacao: o pipeline de CI le o workspace a partir da branch, nunca de
    variavel manual.
  - A propria HashiCorp orienta que workspaces nao sao adequados quando prod
    exige separacao forte de credenciais e permissoes.

  Em ambiente real, a separacao correta e uma conta AWS por ambiente dentro de
  uma AWS Organization, com SCPs por OU. Essa abordagem esta modelada no
  projeto aws-landing-zone-ai-review (Decisao 3). Este repositorio usa
  workspaces conscientemente, por escopo de estudo e restricao de custo.
