# data "aws_caller_identity" "current" {}

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.31"

#   cluster_name                     = "${local.name}-eks"
#   cluster_version                  = var.cluster_version
#   cluster_endpoint_private_access   = true
#   cluster_endpoint_public_access    = true
#   authentication_mode               = "API_AND_CONFIG_MAP"
#   enable_cluster_creator_admin_permissions = true

#   # Handle existing KMS key and CloudWatch Log Group remember to change the values if you want to use your own KMS key or CloudWatch Log Group to a variable
#   # If you want to use your own KMS key, set create_kms_key to false and provide the kms_key_arn variable
#   create_kms_key = var.kms_key ? true : false
#   create_cloudwatch_log_group = var.cloudwatch_log_group ? true : false

#   # Configure cluster encryption
#   cluster_encryption_config = []

#   cluster_upgrade_policy = {
#     support_type = "STANDARD"
#   }

#   cluster_zonal_shift_config = {
#     enabled = true
#   }

#   cluster_addons = {
#     coredns = {}
#     kube-proxy = {}
#     eks-pod-identity-agent = {}
#     vpc-cni = {}
#   }

#   # Configure node security group rules
#   node_security_group_additional_rules = {
#     ingress_self_all = {
#       description = "Node to node all ports/protocols"
#       protocol    = "-1"
#       from_port   = 0
#       to_port     = 0
#       type        = "ingress"
#       self        = true
#     }
    
#     egress_all = {
#       description = "Node all egress"
#       protocol    = "-1"
#       from_port   = 0
#       to_port     = 0
#       type        = "egress"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
    
#   }

#   # Configure node pools
#   cluster_compute_config = {
#     enabled    = true
#     node_pools = ["general-purpose"]
#   }

#   # Enable control plane logging
#   cluster_enabled_log_types = [
#     "api",
#     "audit",
#     "authenticator",
#     "controllerManager",
#     "scheduler"
#   ]

#   # Configure VPC and subnets
#   vpc_id     = var.eks_vpc
#   control_plane_subnet_ids = var.eks_private_subnets
#   subnet_ids = var.eks_private_subnets


#   access_entries = {
#     admin_sso = {
#       principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_c058cbfc989a7680"
#       policy_associations = {
#         cluster_admin = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#           access_scope = {
#             type = "cluster"
#           }
#         }
#         admin = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
#           access_scope = {
#             type = "cluster"
#           }
#         }
#       }
#     }
#     poweruser_sso = {
#       principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_PowerUserAccess_d09c4438f7d58e8d"
#       policy_associations = {
#         cluster_admin = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#           access_scope = {
#             type = "cluster"
#           }
#         }
#         admin = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
#           access_scope = {
#             type = "cluster"
#           }
#         }
#       }
#     }
#   }

#   tags = local.tags
# }


# ###############################
# # OIDC Provider Data Source for IRSA
# ###############################
# data "aws_iam_openid_connect_provider" "oidc_provider" {
#   url = module.eks.cluster_oidc_issuer_url
#   depends_on = [ module.eks ]
# }

# # ###############################
# # # IRSA for External DNS
# # ###############################
# # Build the assume role policy for External DNS, which requires that the service account
# # in the "kube-system" namespace with the name "external-dns" can assume this role.
# data "aws_iam_policy_document" "external_dns_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"
    
#     principals {
#       type        = "Federated"
#       identifiers = [data.aws_iam_openid_connect_provider.oidc_provider.arn]
#     }
    
#     condition {
#       test     = "StringEquals"
#       variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
#       values = [
#         "system:serviceaccount:external-dns:external-dns",
#         "system:serviceaccount:cert-manager:cert-manager-acme-dns01-route53"
#       ]
#     }
    
#     condition {
#       test     = "StringEquals"
#       variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"
#       values   = ["sts.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "external_dns" {
#   name               = "external-dns"
#   assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role_policy.json
# }

# # Define a minimal policy giving External DNS permissions to manage Route 53 records.
# data "aws_iam_policy_document" "external_dns_policy_doc" {
#   statement {
#     actions = [
#       "route53:GetChange",
#       "route53:GetHostedZone",
#       "route53:ListResourceRecordSets",
#       "route53:ChangeResourceRecordSets",
#       "route53:ListHostedZonesByName",
#       "route53:ListHostedZones"
#     ]
#     resources = ["arn:aws:route53:::hostedzone/*","arn:aws:route53:::change/*"]
#   }

#   statement {
#     actions = [
#       "route53:ListHostedZones",
#       "route53:ListHostedZonesByName",
#       "route53:ListResourceRecordSets",
#       "route53:ListTagsForResources"
#     ]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "external_dns_policy" {
#   name   = "external-dns-policy"
#   policy = data.aws_iam_policy_document.external_dns_policy_doc.json
# }

# resource "aws_iam_role_policy_attachment" "external_dns_attach" {
#   role       = aws_iam_role.external_dns.name
#   policy_arn = aws_iam_policy.external_dns_policy.arn
# }

# ###############################
# # LoadBalancer Contoller IAM Policy
# ###############################
# resource "aws_iam_role" "AmazonEKSLoadBalancerControllerRole" {
#   name = "AmazonEKSLoadBalancerControllerRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Effect = "Allow"
#         Principal = {
#           Federated = data.aws_iam_openid_connect_provider.oidc_provider.arn
#         }
#         Condition = {
#           StringEquals = {
#             "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = [
#               "system:serviceaccount:kube-system:eks-lb-aws-load-balancer-controller"
#             ]
#             "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })
  
# }

# resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
#   name        = "AWSLoadBalancerControllerIAMPolicy"
#   description = "IAM policy for AWS Load Balancer Controller"
#   policy = templatefile("${path.module}/policies/awslb_iam_policy.json", {})
# }

# resource "aws_iam_role_policy_attachment" "AWSLoadBalancerControllerIAMPolicyAttachment" {
#   role       = aws_iam_role.AmazonEKSLoadBalancerControllerRole.name
#   policy_arn = aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn
# }
data "aws_caller_identity" "current" {}

# Data sources to find the actual SSO role names
data "aws_iam_roles" "sso_admin_roles" {
  name_regex = "AWSReservedSSO_AdministratorAccess_.*"
}

data "aws_iam_roles" "sso_poweruser_roles" {
  name_regex = "AWSReservedSSO_PowerUserAccess_.*"
}

# Get the first (and typically only) matching role for each
locals {
  admin_sso_role_arn = length(data.aws_iam_roles.sso_admin_roles.arns) > 0 ? tolist(data.aws_iam_roles.sso_admin_roles.arns)[0] : null
  poweruser_sso_role_arn = length(data.aws_iam_roles.sso_poweruser_roles.arns) > 0 ? tolist(data.aws_iam_roles.sso_poweruser_roles.arns)[0] : null
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                     = "${local.name}-eks"
  cluster_version                  = var.cluster_version
  cluster_endpoint_private_access   = true
  cluster_endpoint_public_access    = true
  authentication_mode               = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true

  # Handle existing KMS key and CloudWatch Log Group remember to change the values if you want to use your own KMS key or CloudWatch Log Group to a variable
  # If you want to use your own KMS key, set create_kms_key to false and provide the kms_key_arn variable
  create_kms_key = var.kms_key ? true : false
  create_cloudwatch_log_group = var.cloudwatch_log_group ? true : false

  # Configure cluster encryption
  cluster_encryption_config = []

  cluster_upgrade_policy = {
    support_type = "STANDARD"
  }

  cluster_zonal_shift_config = {
    enabled = true
  }

  cluster_addons = {
    coredns = {}
    kube-proxy = {}
    eks-pod-identity-agent = {}
    vpc-cni = {}
  }

  # Configure node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Configure node pools
  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  # Enable control plane logging
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Configure VPC and subnets
  vpc_id     = var.eks_vpc
  control_plane_subnet_ids = var.eks_private_subnets
  subnet_ids = var.eks_private_subnets

  # Only create access entries if the SSO roles exist
  access_entries = merge(
    local.admin_sso_role_arn != null ? {
      admin_sso = {
        principal_arn = local.admin_sso_role_arn
        policy_associations = {
          cluster_admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {},
    local.poweruser_sso_role_arn != null ? {
      poweruser_sso = {
        principal_arn = local.poweruser_sso_role_arn
        policy_associations = {
          cluster_admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {}
  )

  tags = local.tags
}

# Rest of your configuration remains the same...
###############################
# OIDC Provider Data Source for IRSA
###############################
data "aws_iam_openid_connect_provider" "oidc_provider" {
  url = module.eks.cluster_oidc_issuer_url
  depends_on = [ module.eks ]
}

# ###############################
# # IRSA for External DNS
# ###############################
# Build the assume role policy for External DNS, which requires that the service account
# in the "kube-system" namespace with the name "external-dns" can assume this role.
data "aws_iam_policy_document" "external_dns_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.oidc_provider.arn]
    }
    
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:external-dns:external-dns",
        "system:serviceaccount:cert-manager:cert-manager-acme-dns01-route53"
      ]
    }
    
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role_policy.json
}

# Define a minimal policy giving External DNS permissions to manage Route 53 records.
data "aws_iam_policy_document" "external_dns_policy_doc" {
  statement {
    actions = [
      "route53:GetChange",
      "route53:GetHostedZone",
      "route53:ListResourceRecordSets",
      "route53:ChangeResourceRecordSets",
      "route53:ListHostedZonesByName",
      "route53:ListHostedZones"
    ]
    resources = ["arn:aws:route53:::hostedzone/*","arn:aws:route53:::change/*"]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResources"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_dns_policy" {
  name   = "external-dns-policy"
  policy = data.aws_iam_policy_document.external_dns_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "external_dns_attach" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns_policy.arn
}

###############################
# LoadBalancer Contoller IAM Policy
###############################
resource "aws_iam_role" "AmazonEKSLoadBalancerControllerRole" {
  name = "AmazonEKSLoadBalancerControllerRole"

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
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = [
              "system:serviceaccount:kube-system:eks-lb-aws-load-balancer-controller"
            ]
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy = templatefile("${path.module}/policies/awslb_iam_policy.json", {})
}

resource "aws_iam_role_policy_attachment" "AWSLoadBalancerControllerIAMPolicyAttachment" {
  role       = aws_iam_role.AmazonEKSLoadBalancerControllerRole.name
  policy_arn = aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn
}