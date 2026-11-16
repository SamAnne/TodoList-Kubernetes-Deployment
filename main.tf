variable "github_repository" {
  type        = string
  description = "GitHub repository allowed to push images, as owner/name."
  default     = "SamAnne/TodoList"
}

resource "aws_ecr_repository" "todolist" {
  name = "ecr-todolist-uvu-it3200-ansamaalsharif"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-uvu-it3200-ansamaalsharif"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:ref:refs/heads/master"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "github_ecr_push" {
  name = "ecr-push-github-uvu-it3200-ansamaalsharif"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:DescribeImages"
        ]
        Resource = aws_ecr_repository.todolist.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_ecr_push" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_ecr_push.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}