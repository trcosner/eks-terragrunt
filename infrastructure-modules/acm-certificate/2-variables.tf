variable "domain_name" {
  description = "The domain name for the certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names for the certificate"
  type        = list(string)
  default     = []
}

variable "validation_method" {
  description = "Method to use for domain validation. DNS or EMAIL"
  type        = string
  default     = "DNS"
}

variable "zone_id" {
  description = "Route53 hosted zone ID for DNS validation (required if validation_method is DNS)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to the certificate"
  type        = map(string)
  default     = {}
}

variable "create_route53_records" {
  description = "Whether to automatically create Route53 DNS validation records"
  type        = bool
  default     = true
}