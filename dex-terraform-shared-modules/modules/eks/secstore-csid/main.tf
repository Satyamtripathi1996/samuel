data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

###############################
# OIDC Provider Data Source for IRSA
###############################
data "aws_iam_openid_connect_provider" "oidc_provider" {
  url = var.eks_module_url
}

###############################
# Security Store CSI Role
###############################
resource "aws_iam_role" "security_store_csi_role" {
  name = "security-store-csi-role"

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
            "${replace(var.eks_module_url, "https://", "")}:sub" = var.security_store_csi_service_account
          }
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "security_store_csi_policy_doc" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*", "*"]
    }
}

resource "aws_iam_policy" "security_store_csi_policy" {
  name   = "security-store-csi-policy"
  policy = data.aws_iam_policy_document.security_store_csi_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "security_store_csi_attach" {
  role       = aws_iam_role.security_store_csi_role.name
  policy_arn = aws_iam_policy.security_store_csi_policy.arn
}


