###############################
# OIDC Provider Data Source for IRSA
###############################
data "aws_iam_openid_connect_provider" "oidc_provider" {
  url = var.eks_module_url
}

###############################
# External ECR Image Pull Permissions
###############################
resource "aws_iam_role" "external_ecr_image_pull_role" {
  name = "external-ecr-image-pull-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.eks_module_url, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(var.eks_module_url, "https://", "")}:sub" = var.external_ecr_service_account
          }
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "external_ecr_image_pull_policy_doc" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["arn:aws:ecr:*:*:repository/*"]
    }
}

resource "aws_iam_policy" "external_ecr_image_pull_policy" {
  name   = "external-ecr-image-pull-policy"
  policy = data.aws_iam_policy_document.external_ecr_image_pull_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "external_ecr_image_pull_attach" {
  role       = aws_iam_role.external_ecr_image_pull_role.name
  policy_arn = aws_iam_policy.external_ecr_image_pull_policy.arn
}
