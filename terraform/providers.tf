# ---------------------------------------------------------
# terrform info, provider, version
# ---------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "keyholding-tfstate-radix"
    key    = "keyholding_1.tfstate"
    region = "us-east-1"
  }
}

# ---------------------------------------------------------
# cloud-hosting platform provider
# ---------------------------------------------------------
provider "aws" {
  region = "us-east-1"
}
