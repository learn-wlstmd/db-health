variable "region" {
  description = "The region in which the resources will be created"
  default     = "us-east-1"
}

variable "project_name" {
  description = "The project name"
  default     = "demo-us"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.100.0.0/16"
}

variable "availability_zones" {
    description = "The availability zones in which the resources will be created"
    default     = ["a", "b", "c"]
}

variable "subnet_prefix" {
  description = "The prefix for the subnets"
  default     = "24"
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets"
  default     = [0,1,2]
}

variable "private_subnet_cidrs" {
  description = "The CIDR blocks for the private subnets"
  default     = [3,4,5]  
}