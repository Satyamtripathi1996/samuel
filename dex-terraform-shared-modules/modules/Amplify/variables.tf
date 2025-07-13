variable "env" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "us-east-2"
}

variable "amp_config" {
  type = list(object({
    name            = string
    repo            = string
    branch_name     = string
    framework       = string
    github_pat_path = string
    domain_name     = string
    backend         = bool
  }))
  default = [
    {
      name            = "sports-commerce"
      repo            = "https://github.com/Kundan547/Sports-commerce.git"
      branch_name     = "master"
      framework       = "React"
      github_pat_path = "/github/pat/sports-commerce"
      domain_name     = "samuel.cloudbyvin.com"
      backend         = true
    }
  ]
}


variable "custom_rules" {
  type = list(object({
    source = string
    status = string
    target = string
  }))
  default = [
    {
      source = "/old-path"
      status = "301"
      target = "/new-path"
    }
  ]
}
