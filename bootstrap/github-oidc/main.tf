# Bootstrap do acesso do GitHub Actions à AWS por OIDC.
#
# Substitui a access key de longa duração (AWS_ACCESS_KEY_ID e
# AWS_SECRET_ACCESS_KEY) por uma role que o GitHub assume com um token
# temporário, válido só durante o job.
#
# Roda UMA vez, à mão, por alguém com acesso de administrador na conta:
#   terraform -chdir=bootstrap/github-oidc init
#   terraform -chdir=bootstrap/github-oidc apply
# Depois, grave a saída "role_arn" no secret AWS_ROLE_ARN do repositório da API.
#
# Fica fora de env/Homolog de propósito: o pipeline destrói e recria aquele
# ambiente, e não pode apagar a própria role que usa para entrar na AWS.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "terraform-state-api-go-cicd-enzodiasdev"
    key          = "bootstrap/github-oidc/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "repositorio_github" {
  description = "Repositório (dono/nome) cujos workflows podem assumir a role."
  type        = string
  default     = "EnzoDiasDev/Curso_CI_3-Projeto_inicial"
}

variable "branches_permitidas" {
  description = "Branches que podem assumir a role. main faz o deploy no EKS; Homolog roda o teste de carga no ECS."
  type        = list(string)
  default     = ["main", "Homolog"]
}

# O provedor OIDC do GitHub é único por conta. Se ele já existir, importe em
# vez de criar:
#   terraform import aws_iam_openid_connect_provider.github \
#     arn:aws:iam::<conta>:oidc-provider/token.actions.githubusercontent.com
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "confianca" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Só aceita tokens de push nas branches permitidas deste repositório.
    # Pull requests, forks e outras branches não conseguem assumir a role.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for branch in var.branches_permitidas : "repo:${var.repositorio_github}:ref:refs/heads/${branch}"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = "github-actions-api-go"
  description          = "Role assumida pelo GitHub Actions via OIDC para o deploy da API Go"
  assume_role_policy   = data.aws_iam_policy_document.confianca.json
  max_session_duration = 3600
}

# O pipeline cria VPC, EKS, RDS, ECS e roles IAM, então precisa de permissão
# ampla. O ganho aqui é que a credencial é temporária e só pode ser usada pelo
# repositório e pelas branches acima. Reduzir esta política ao mínimo é o
# próximo passo.
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "role_arn" {
  value = aws_iam_role.github_actions.arn
}
