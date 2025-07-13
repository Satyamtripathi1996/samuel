provider "aws" {
  alias   = "network"
  region  = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  providers = {
    aws = aws.network
  }

  name             = "${local.name}-vpc"
  cidr             = var.vpc_cidr
  azs              = local.azs
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets
  elasticache_subnets = var.elasticache_subnets
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_ipv6 = false

  create_database_subnet_group = true
  create_database_internet_gateway_route = var.database_internet_gateway
  manage_default_network_acl = false
  manage_default_security_group = false
  manage_default_route_table = false

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true
  #map_public_ip_on_launch = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
  flow_log_traffic_type                = "ALL"
  flow_log_destination_type            = "cloud-watch-logs"
  flow_log_log_format                  = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"

  public_dedicated_network_acl = true
  private_dedicated_network_acl = true
  database_dedicated_network_acl = true
  elasticache_dedicated_network_acl = true

  public_subnet_tags = {
    Type = "public",
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    Type = "private applications",
    "kubernetes.io/role/internal-elb" = 1
  }
  database_subnet_tags = {
    Type = "database"
  }
  elasticache_subnet_tags = {
    Type = "elasticache"
  }

  tags = local.tags
}
