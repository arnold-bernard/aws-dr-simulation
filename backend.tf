# terraform {
#   backend "s3" {
#     bucket       = "StateLockingBucket615243"
#     key          = "terraform.tfstate"
#     region       = "us-east-1"
#     encrypt      = true
#     use_lockfile = true
#   }
# }
