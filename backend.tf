terraform {
  backend "s3" {
    bucket = "vpro-terra-state"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "vpro-lock"
  }
}
