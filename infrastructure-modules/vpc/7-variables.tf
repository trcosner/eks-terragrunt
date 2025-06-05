variable "env" {
    description = "Environment name"
    type = string
}

variable "vpc_cidr_block" {
    description = "CIDR block for the VPC"
    type        = string
    default     = "10.0.0.0/16"
}

variable "azs" {
    description = "List of availability zones"
    type        = list(string)
}

variable "public_subnets" {
    description = "List of public subnets"
    type        = list(string)
}

variable "private_subnets" {
    description = "List of private subnets"
    type        = list(string)
}

variable "private_subnet_tags" {
    description = "Tags for private subnets"
    type        = map(string)
}

variable "public_subnet_tags" {
    description = "Tags for public subnets"
    type        = map(string)
}