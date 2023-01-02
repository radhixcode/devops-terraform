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
}

# ---------------------------------------------------------
# cloud-hosting platform provider
# ---------------------------------------------------------
provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "vscode"
}
