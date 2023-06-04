# Configure the provider software version
terraform {
  backend "s3" {
    bucket = "solimanbuckett"             
    key    = "state"
    region = "us-east-1"
    
    dynamodb_table = "terraform"       
    encrypt        = true
  
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
} 
