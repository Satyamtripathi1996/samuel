variable "zone_name" {
  description = "Name of DNS zone"
  type        = string
  
}

variable "records" {
  description = "Route53 list of DNS records"
  type = any
 }