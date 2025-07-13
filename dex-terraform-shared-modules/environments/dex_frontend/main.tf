###
################################################
# Data Blocks
################################################
data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

###############################################
# S3 Buckets
################################################
module "s3" {
  source       = "../../modules/s3"
  env          = var.env
  region       = var.region
  buckets_list = var.buckets_list
}

################################################
# Code Artifacts
################################################
# module "artifact" {
#   source               = "../../modules/codeartifact"
#   env                  = var.env
#   repository_name      = var.artifact_repo
#   external_connections = var.external_packages
# }

################################################
# ECR Repo
################################################
# module "ecr" {
#   source = "../../modules/ecr"
#   env    = var.env
# }

################################################
# IAM Configuration
################################################
# module "iam" {
#   source                  = "../../modules/iam"
#   env                     = var.env
#   region                  = var.region
#   iam_groups_names        = var.iam_groups_names
#   iam_developerUser_names = var.iam_developerUser_names
#   iam_devOpsUser_names    = var.iam_devOpsUser_names
#   devops_cgp_arn          = var.devops_cgp_arn
#   developer_cgp_arn       = var.developer_cgp_arn
# }

################################################
# VPC Netwok
################################################
module "network" {
  source = "../../modules/network"
  providers = {
    aws = aws.network
  }
  aws_profile               = var.aws_profile
  env                       = var.env
  region                    = var.region
  vpc_cidr                  = var.vpc_cidr
  public_subnets            = var.public_subnets
  private_subnets           = var.private_subnets
  database_subnets          = var.database_subnets
  database_internet_gateway = false
  elasticache_subnets       = var.elasticache_subnets
}

################################################
# EKS
################################################
module "eks" {
  source               = "../../modules/eks"
  cluster_version      = var.cluster_version
  env                  = var.env
  region               = var.region
  eks_vpc              = module.network.vpc_id
  eks_private_subnets  = module.network.private_subnets
  kms_key              = var.kms_key
  cloudwatch_log_group = var.cloudwatch_log_group
}

################################################
# EKS External ECR Permissions
################################################
module "external_ecr_permissions" {
  source = "../../modules/eks/external-ecr"

  eks_module_url = module.eks.cluster_oidc_issuer_url
  external_ecr_service_account = [
    "system:serviceaccount:default:external-ecr-image-pull",
    "system:serviceaccount:dex-portal:dex-frontend-external-ecr-image-pull",
    "system:serviceaccount:enrollment:dex-frontend-external-ecr-image-pull",
    "system:serviceaccount:utility:dex-frontend-external-ecr-image-pull",
    "system:serviceaccount:wep-admin:dex-frontend-external-ecr-image-pull",
    "system:serviceaccount:wep-portal:dex-frontend-external-ecr-image-pull"
  ]
}

################################################
# Security Store CSI Permissions
################################################
module "secstore_permissions" {
  source = "../../modules/eks/secstore-csid"

  eks_module_url = module.eks.cluster_oidc_issuer_url
  security_store_csi_service_account = [
    "system:serviceaccount:kube-system:csi-secrets-store-provider-aws",
    "system:serviceaccount:dex-portal:dex-frontend-secrets-provider-aws",
    "system:serviceaccount:enrollment:dex-frontend-secrets-provider-aws",
    "system:serviceaccount:utility:dex-frontend-secrets-provider-aws",
    "system:serviceaccount:wep-admin:dex-frontend-secrets-provider-aws",
    "system:serviceaccount:wep-portal:dex-frontend-secrets-provider-aws"
  ]
}

################################################
# RDS
################################################
module "rds" {
  source                  = "../../modules/rds"
  env                     = var.env
  region                  = var.region
  rds_config              = var.rds_config
  database_subnet_group   = module.network.database_subnet_group_name
  password_rotation_rules = "rate(15 days)"
  vpc_id                  = module.network.vpc_id
  vpc_cidr                = module.network.vpc_cidr_block
  publicly_accessible     = false
}

################################################
# Amplify
################################################
# module "amplify" {
#   source       = "../../modules/amplify"
#   env          = var.env
#   region       = var.region
#   amp_config   = var.amp_config
#   custom_rules = var.amp_custom_rules
# }

################################################
# Redis Elasticache
################################################
module "redis" {
  source                 = "../../modules/elasticache"
  env                    = var.env
  region                 = var.region
  elasticache_subnet_ids = module.network.elasticache_subnets
  vpc_id                 = module.network.vpc_id
  vpc_cidr               = module.network.vpc_cidr_block
}
##################################################
# Route53
##################################################
module "route53" {
  source = "../../modules/route53/zone"
  env    = var.env
  zone = {
    "dex-fe.mocafi.com" = {
      comment = "dex-fe.mocafi.com (dex-frontend)"
      name    = "dex-fe.mocafi.com"
      # vpc = [
      #   {
      #     vpc_id     = module.network.vpc_id
      #     vpc_region = var.region
      #   }
      # ]
      force_destroy = true

      timeouts = {
        create = 30
        delete = 30
        update = 30
      }

      tags = {
        Name      = "dex-fe.mocafi.com"
        ManagedBy = "Terraform"
        Owner     = "Mocafi"
      }
    }
  }
}