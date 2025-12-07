provider "aws" {
        region = "ap-south-1"
}

resource "aws_instance" "my-instance" {
        ami = "ami-0305d3d91b9f22e84"
        instance_type = "t3.micro"
}



resource "aws_s3_bucket" "my-buck" {
        bucket = "heyyogi-bucket"
}

resource "aws_dynamodb_table" "my_db_table" {
  name         = "heyyogi-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}