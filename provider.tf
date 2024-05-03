variable "region" {
  type = string
}

variable "backend_bucket" {
  type = string
}

provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = var.backend_bucket
    key    = "terraformstate"
    region = var.region
  }
}
