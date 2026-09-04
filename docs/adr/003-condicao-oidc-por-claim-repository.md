ADR-003: Restricao OIDC pelo claim repository, nao pelo sub

Status: aceito
Data: 2026-09-04

Contexto

  A trust policy da role do CI restringia a origem do token com o padrao
  classico documentado pela AWS e pelo GitHub:

    StringLike token.actions.githubusercontent.com:sub
      = "repo:OWNER/REPO:*"

  Toda a configuracao estava correta: provider OIDC presente na conta com
  client_id sts.amazonaws.com, audience correta, nome de repositorio exato.
  Ainda assim os tres jobs falhavam com
  "Not authorized to perform sts:AssumeRoleWithWebIdentity".

  Um passo temporario no workflow decodificou o payload do JWT e revelou o
  sub real emitido:

    repo:OWNER@286689955/REPO@1357398084:pull_request

  O GitHub estava incluindo os IDs numericos imutaveis do owner e do
  repositorio dentro do sub. O padrao "repo:OWNER/REPO:*" nao casa com essa
  forma, porque o wildcard esta no fim e as insercoes estao no meio.

  No mesmo payload, o claim "repository" vinha limpo: "OWNER/REPO".

Decisao

  Restringir a origem por duas condicoes:

  1. StringEquals sobre o claim "repository", igual a "OWNER/REPO".
     Comparacao exata, sem wildcard.
  2. StringLike sobre o "sub", restringindo o tipo de evento a
     pull_request e a ref refs/heads/main, com wildcard nas posicoes onde
     os IDs podem ou nao aparecer.

Motivos

  - O claim "repository" tem a forma "owner/repo" independentemente de a
    inclusao de IDs estar ativa. A condicao deixa de depender de uma
    configuracao do GitHub que pode mudar sem aviso.
  - A comparacao exata em "repository" e mais forte que um StringLike com
    wildcard: nao ha padrao para escapar.
  - Manter uma condicao sobre o sub preserva a restricao por evento. Sem
    ela, um workflow em qualquer branch ou tag do repositorio poderia
    assumir a role.

Alternativa descartada

  Ajustar o padrao do sub para "repo:OWNER@*/REPO@*:*". Funciona enquanto a
  inclusao de IDs estiver ativa, e para de funcionar se for desativada. Uma
  condicao de seguranca que depende de configuracao externa volatil e
  fragil por definicao.

Licao

  Quando OIDC falha com "Not authorized" e toda a configuracao parece
  correta, decodificar o sub real do token resolve em um passo o que
  hipoteses sucessivas
