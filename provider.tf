variable "region" {
  type = string
}

provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "gates-terraform-backend-42853"
    key    = "terraformstate"
    region = "eu-west-1"
  }
}
