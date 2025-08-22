terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

data "http" "myip" {
  url = "https://myip.wtf/text"
}

data "aws_availability_zones" "available" {}