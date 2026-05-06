terraform {
  backend "s3" {
    bucket       = "eks-devops-platform-tfstate-820242908024"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}