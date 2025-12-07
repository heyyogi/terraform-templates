terraform {
  backend "s3" {
    bucket         = "heyyogi-bucket"
    key            = "env/terraform.tstate"
    region         = "ap-south-1"
    dynamodb_table = "heyyogi-table"
  }
}