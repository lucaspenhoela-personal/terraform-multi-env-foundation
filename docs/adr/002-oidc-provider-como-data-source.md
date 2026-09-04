ADR-002: OIDC provider do GitHub como data source, nao resource

Status: aceito
Data: 2026-09-04

Contexto

  O pipeline autentica na AWS via OIDC, o que exige um recurso
  aws_iam_openid_connect_provider apontando para
  token.actions.githubusercontent.com.

  Esse recurso e um singleton por conta AWS: a URL admite um unico provider.
  Ao tentar cria-lo, o apply falhou com StatusCode 409, "already exists" —
  o provider ja existia na conta, criado antes deste projeto e provavelmente
  em uso por outros repositorios.

  Importado para o state com terraform import, o plan seguinte mostrou
  1 to change: a lista de thumbprints da conta continha um valor diferente
  dos declarados neste repositorio, e o Terraform removeria o existente.

Decisao

  Modelar o provider como data source. Este projeto le o ARN do provider,
  nao o gerencia.

Motivos

  - Um recurso singleton compartilhado entre repositorios nao pode ter dono
    unico. Se cada projeto o declarar como resource, cada apply sobrescreve
    a configuracao dos demais.
  - O thumbprint atual da conta funciona; alterar sem necessidade poderia
    quebrar o CI de outro repositorio.
  - Data source expressa a relacao real: consumo, nao propriedade.

Consequencias

  - O repositorio nao documenta em codigo como o provider e criado. Mitigado
    com um comentario em bootstrap/oidc.tf contendo o comando de criacao.
  - Se a conta nao tiver o provider, o plan falha com erro de data source
    nao encontrado. O comando de criacao no comentario resolve.
  - Este projeto continua sendo dono da role, das policies e dos
    attachments. Apenas o provider federado e externo.

Alternativa descartada

  Manter como resource e alinhar o thumbprint. Descartada porque resolveria o
  conflito imediato sem resolver a causa: o proximo projeto que declarasse o
  mesmo resource reabriria a briga.
