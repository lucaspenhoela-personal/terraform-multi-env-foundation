# O provider OIDC do GitHub Actions e um recurso SINGLETON por conta AWS:
# a URL token.actions.githubusercontent.com admite um unico provider.
#
# Por isso ele NAO e declarado como resource aqui. Este provider ja existia
# na conta antes deste projeto, e provavelmente e usado por outros
# repositorios. Um resource faria cada projeto sobrescrever o thumbprint
# configurado pelos demais a cada apply. Modelar como data source deixa
# claro que este projeto consome o provider, nao o possui.
#
# Se a conta ainda nao tiver o provider, cria-lo uma vez com:
#   aws iam create-open-id-connect-provider \
#     --url https://token.actions.githubusercontent.com \
#     --client-id-list sts.amazonaws.com
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Trust policy: define QUEM pode assumir a role e sob quais condicoes.
data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    # A audience precisa bater com o que o GitHub envia.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # ESTA e a condicao critica. Sem restringir a origem, QUALQUER
    # repositorio do GitHub no mundo poderia assumir esta role. E o erro de
    # configuracao mais comum e mais grave em OIDC.
    #
    # A restricao usa o claim "repository", nao o "sub". Motivo: quando a
    # organizacao ou a conta habilita a inclusao de IDs nos claims, o sub
    # passa a ter a forma
    #   repo:owner@<owner_id>/repo@<repo_id>:pull_request
    # e um padrao escrito como repo:owner/repo:* deixa de casar. O claim
    # "repository" permanece "owner/repo" nos dois casos, entao a condicao
    # nao depende dessa configuracao do GitHub.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository"
      values   = ["${var.github_owner}/${var.github_repo}"]
    }

    # Restringe tambem o tipo de evento, com wildcard nas extremidades para
    # tolerar os IDs opcionais no meio do sub. Sem isso, um workflow em
    # qualquer branch ou tag do repositorio poderia assumir a role.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}*/${var.github_repo}*:pull_request",
        "repo:${var.github_owner}*/${var.github_repo}*:ref:refs/heads/main"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_plan" {
  name        = "github-actions-terraform-plan"
  description = "Role assumida pelo GitHub Actions para rodar terraform plan"

  assume_role_policy   = data.aws_iam_policy_document.github_assume_role.json
  max_session_duration = 3600

  tags = {
    Name = "github-actions-terraform-plan"
  }
}

# Permissao de leitura para o plan. ReadOnlyAccess e uma policy gerenciada
# ampla, mas de leitura: o pipeline pode descrever recursos, nunca criar,
# alterar ou destruir. Um plan nao precisa de mais que isso.
resource "aws_iam_role_policy_attachment" "github_actions_readonly" {
  role       = aws_iam_role.github_actions_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# O plan tambem precisa LER e TRAVAR o state. ReadOnlyAccess cobre a leitura
# do S3 e do DynamoDB, mas nao a escrita do item de lock, que e uma operacao
# de gravacao. Esta policy adiciona so isso, com escopo nos recursos exatos.
data "aws_iam_policy_document" "state_access" {
  statement {
    sid    = "StateBucketRead"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]
  }

  statement {
    sid    = "StateLockTable"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]

    resources = [aws_dynamodb_table.lock.arn]
  }
}

resource "aws_iam_policy" "state_access" {
  name        = "github-actions-terraform-state-access"
  description = "Leitura do state em S3 e gerencia do lock em DynamoDB"
  policy      = data.aws_iam_policy_document.state_access.json
}

resource "aws_iam_role_policy_attachment" "state_access" {
  role       = aws_iam_role.github_actions_plan.name
  policy_arn = aws_iam_policy.state_access.arn
}
