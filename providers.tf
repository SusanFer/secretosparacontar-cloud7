terraform{
    required_providers {
        aws={
            source="hashicorp/aws"
            version="~> 5.0"
        }
    }
}

provider "aws" {
    region=var.aws_region
    access_key = "<ACCESS_KEY>"
    secret_key = "<SECRET_KEY>"
}