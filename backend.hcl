bucket         = "fraud-detection-dev-terraform-state"
key            = "terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "fraud-detection-dev-terraform-lock"
encrypt        = true 