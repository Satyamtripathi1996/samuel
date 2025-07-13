#aws_profile = "default"
region = "us-east-1"
env    = "dex-backend"

# S3 Buckets
buckets_list = [
  {
    bucket_name = "dex-backend-state-bucket"
  }
]

# Code Artifacts
artifact_repo = "devpkg"
external_packages = {
  "npm" = "npmjs"
}

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Subnet Configuration - Using 2 AZs to match existing EKS cluster
public_subnets = [
  "10.0.1.0/24", # us-east-1a - For NAT Gateway, Load Balancers
  "10.0.2.0/24", # us-east-1b - For NAT Gateway, Load Balancers
  "10.0.3.0/24"  # us-east-1c - For NAT Gateway, Load Balancers
]

private_subnets = [
  "10.0.11.0/24", # us-east-1a - For EKS nodes, application servers
  "10.0.12.0/24", # us-east-1b - For EKS nodes, application servers
  "10.0.13.0/24"  # us-east-1c - For EKS nodes, application servers
]

database_subnets = [
  "10.0.21.0/24", # us-east-1a - For RDS instances
  "10.0.22.0/24", # us-east-1b - For RDS instances
  "10.0.23.0/24"  # us-east-1c - For RDS instances
]

elasticache_subnets = [
  "10.0.31.0/24", # us-east-1a - For ElastiCache Redis
  "10.0.32.0/24", # us-east-1b - For ElastiCache Redis
  "10.0.33.0/24"  # us-east-1c - For ElastiCache Redis
]

# Network Security
# allowed_public_ips = "0.0.0.0/0"  # Restrict this to your office IP range for better security

# EKS Configuration
cluster_version      = "1.33"
kms_key              = true
cloudwatch_log_group = false

# # IAM Configurations
iam_groups_names        = ["Developers", "DevOps"]
iam_developerUser_names = ["samuel", "peter", "lekan"]
iam_devOpsUser_names    = ["sammy", "joseph", "saul"]
devops_cgp_arn          = ["arn:aws:iam::aws:policy/AdministratorAccess"]
developer_cgp_arn       = ["arn:aws:iam::aws:policy/PowerUserAccess"]

# RDS Configuration
rds_config = [
  {
    name                 = "db",
    engine               = "postgres",
    engine_version       = "17.5",
    family               = "postgres17",
    major_engine_version = "17.5",
    instance_class       = "db.t3.micro",
    username             = "dex_pgadmin",
    min_storage          = 20,
    max_storage          = 50,
    port                 = 5432,
    replica              = true,
    final_snapshot       = false,
    deletion_protection  = false,
    multi_az             = true,
  }
]
# Amplify Frontend
amp_config = [
  {
    name            = "popupuibackend",
    framework       = "React"
    repo            = "https://github.com/aws-samples/aws-amplify-react-sample"
    github_pat_path = "/amplify/public"
    branch_name     = "main"
    stage           = "PRODUCTION"
    backend         = true
    domain_name     = "awsamplifyapp.com"
  },
  {
    name            = "angularuiform",
    framework       = "Angular"
    repo            = "https://github.com/aws-samples/aws-amplify-angular-sample"
    github_pat_path = "/amplify/public"
    branch_name     = "main"
    stage           = "DEVELOPMENT"
    backend         = false
    domain_name     = "awsamplifyapp.com"
  }
]

amp_custom_rules = [
  { source = "/<*>", status = "404", target = "/index.html" },
  { source = "/api/*", status = "200", target = "/api/index.html" }
]
