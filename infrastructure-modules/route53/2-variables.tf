variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the hosted zone"
  type        = map(string)
  default     = {}
}
