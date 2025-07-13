# ################################################################################
# # Redis Elasticache
# ################################################################################
# resource "aws_elasticache_subnet_group" "this" {
#   name       = "elasticache-subnetgroup"
#   description = "Elasticache subnet group for Redis"
#   subnet_ids = var.elasticache_subnet_ids[*]

#   tags = local.tags
# }

# resource "aws_elasticache_cluster" "this" {
#   cluster_id           = "${local.name}-redis-cluster"
#   engine               = "redis"
#   engine_version       = "7.1"
#   node_type            = "cache.t4g.small"
#   num_cache_nodes      = 1
#   parameter_group_name = aws_elasticache_parameter_group.this.name
  
#   apply_immediately = true
#   az_mode = "single-az"
#   port                 = 6379
#   network_type = "ipv4"
#   ip_discovery = "ipv4"
#   subnet_group_name = aws_elasticache_subnet_group.this.name
#   security_group_ids = [module.redis_sg.security_group_id]

#   maintenance_window = "sun:05:00-sun:09:00"

#   tags = local.tags
#   depends_on = [ aws_elasticache_subnet_group.this, module.redis_sg, aws_elasticache_parameter_group.this ]
#   lifecycle {
#     ignore_changes = [
#       num_cache_nodes,
#       node_type,
#       engine_version,
#       parameter_group_name,
#       port,
#       apply_immediately
#     ]
#   }
# }

# resource "aws_elasticache_parameter_group" "this" {
#   name   = "redis-params"
#   family = "redis7"

#   parameter {
#     name  = "latency-tracking"
#     value = "yes"
#   }

#   tags = local.tags

# }

# ################################################################################
# # Redis Users / Group
# ################################################################################
# resource "aws_elasticache_user" "this" {
#     user_id = "redisUser"
#     user_name = "default"
#     engine = "redis"
#     access_string = "on ~* +@all"
#     no_password_required = true

#     authentication_mode {
#       type = "no-password-required"
#     }
#     tags = local.tags

#     lifecycle {
#       ignore_changes = [ user_id, user_name, access_string, authentication_mode ]
#     }
# }

# resource "aws_elasticache_user_group" "this" {
#   engine = "redis"
#   user_group_id = "redisUserGoup"
#   user_ids = [ aws_elasticache_user.this.user_id]

#   lifecycle {
#     ignore_changes = [ user_ids, ]
#   }

#   tags = local.tags
# }

# ################################################################################
# # Security Group
# ################################################################################
# module "redis_sg" {
#     source = "../sg"
#     env = var.env
#     sg_name = "${local.name}-redis-sg"
#     sg_description = "Complete Redis security group"
#     vpc_id = var.vpc_id
#     ingress_with_cidr_blocks = [
#       {
#         from_port   = 6379
#         to_port     = 6379
#         protocol    = "tcp"
#         description = "ElastiCache (Redis) access from within VPC"
#         cidr_blocks = var.vpc_cidr
#       },
#     ]
#     egress_with_cidr_blocks = [
#       {
#         rule = "all-all"
#       }]
# }
################################################################################
# Redis Elasticache
################################################################################
resource "aws_elasticache_subnet_group" "this" {
  name       = "elasticache-subnetgroup"
  description = "Elasticache subnet group for Redis"
  subnet_ids = var.elasticache_subnet_ids[*]

  tags = local.tags
}

resource "aws_elasticache_cluster" "this" {
  cluster_id           = "${local.name}-redis-cluster"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t4g.small"
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.this.name
  
  # Enable TLS encryption
  transit_encryption_enabled = true
  port                      = 6380  # TLS port
  
  apply_immediately = true
  az_mode = "single-az"
  network_type = "ipv4"
  ip_discovery = "ipv4"
  subnet_group_name = aws_elasticache_subnet_group.this.name
  security_group_ids = [module.redis_sg.security_group_id]

  maintenance_window = "sun:05:00-sun:09:00"

  tags = local.tags
  depends_on = [ aws_elasticache_subnet_group.this, module.redis_sg, aws_elasticache_parameter_group.this ]
  
  lifecycle {
    ignore_changes = [
      num_cache_nodes,
      node_type,
      engine_version,
      parameter_group_name,
      apply_immediately
    ]
  }
}

resource "aws_elasticache_parameter_group" "this" {
  name   = "redis-params"
  family = "redis7"

  parameter {
    name  = "latency-tracking"
    value = "yes"
  }

  tags = local.tags
}

################################################################################
# Redis Users / Group
################################################################################
resource "aws_elasticache_user" "this" {
    user_id = "redisUser"
    user_name = "default"
    engine = "redis"
    access_string = "on ~* +@all"
    no_password_required = true

    authentication_mode {
      type = "no-password-required"
    }
    tags = local.tags

    lifecycle {
      ignore_changes = [ user_id, user_name, access_string, authentication_mode ]
    }
}

resource "aws_elasticache_user_group" "this" {
  engine = "redis"
  user_group_id = "redisUserGoup"
  user_ids = [ aws_elasticache_user.this.user_id]

  lifecycle {
    ignore_changes = [ user_ids, user_group_id ]
  }

  tags = local.tags
}

################################################################################
# Security Group
################################################################################
module "redis_sg" {
    source = "../sg"
    env = var.env
    sg_name = "${local.name}-redis-sg"
    sg_description = "Complete Redis security group"
    vpc_id = var.vpc_id
    ingress_with_cidr_blocks = [
      {
        from_port   = 6380  # TLS port
        to_port     = 6380
        protocol    = "tcp"
        description = "ElastiCache (Redis) TLS access from within VPC"
        cidr_blocks = var.vpc_cidr
      },
    ]
    egress_with_cidr_blocks = [
      {
        rule = "all-all"
      }]
}

################################################################################
# Outputs
################################################################################
output "redis_endpoint" {
  value = aws_elasticache_cluster.this.cache_nodes[0].address
  description = "Redis cluster endpoint"
}

output "redis_port" {
  value = aws_elasticache_cluster.this.port
  description = "Redis cluster port"
}

output "redis_connection_string" {
  value = "${aws_elasticache_cluster.this.cache_nodes[0].address}:${aws_elasticache_cluster.this.port}"
  description = "Redis connection string"
}