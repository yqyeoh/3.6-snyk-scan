data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repository_username}*/${var.github_repository_name}*:*",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_oidc" {
  name               = var.github_oidc_role_name
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
}

data "aws_iam_policy_document" "lambda_deploy" {
  statement {
    sid       = "TfStateList"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.tfstate_bucket}"]
  }

  statement {
    sid     = "TfStateReadWrite"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::${var.tfstate_bucket}/${var.tfstate_key}",
      "arn:aws:s3:::${var.tfstate_bucket}/${var.tfstate_key}.tflock",
    ]
  }

  statement {
    sid = "LambdaExecutionRole"
    actions = [
      "iam:CreateRole",
      "iam:GetRole",
      "iam:DeleteRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListInstanceProfilesForRole",
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/${var.lambda_function_name}-role"]
  }

  statement {
    sid       = "PassRoleToLambda"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/${var.lambda_function_name}-role"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }

  statement {
    sid       = "LambdaFunction"
    actions   = ["lambda:*"]
    resources = ["arn:aws:lambda:${local.region}:${local.account_id}:function:${var.lambda_function_name}"]
  }

  statement {
    sid       = "LogGroup"
    actions   = ["logs:*"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${var.lambda_function_name}*"]
  }

  statement {
    sid       = "LogGroupDescribe"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_deploy" {
  name   = "${var.github_oidc_role_name}-lambda-deploy"
  role   = aws_iam_role.github_oidc.id
  policy = data.aws_iam_policy_document.lambda_deploy.json
}

variable "lambda_function_name" {
  description = "Name of the Lambda function deployed by GitHub Actions"
  type        = string
  default     = "yq-hello-world-lambda"
}

variable "tfstate_bucket" {
  description = "S3 bucket holding the Lambda Terraform state"
  type        = string
  default     = "sctp-tfstate-ce13"
}

variable "tfstate_key" {
  description = "S3 key of the Lambda Terraform state"
  type        = string
  default     = "yq/snyk-3.6"
}

variable "github_repository_username" {
  description = "GitHub repository username"
  type        = string
}

variable "github_repository_name" {
  description = "GitHub repository name"
  type        = string
}

variable "github_oidc_role_name" {
  description = "Name of the GitHub OIDC role"
  type        = string
}

output "github_oidc_role_arn" {
  value = aws_iam_role.github_oidc.arn
}
