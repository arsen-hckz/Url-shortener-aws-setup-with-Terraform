terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "6.0"
    }
  }
  backend "s3" {
    bucket = "yiannis-tfstate-1998"
    key = "capstone/dev/terraform.tfstate"
    region = "eu-north-1"
    use_lockfile = true
    encrypt = true
  }
}

provider "aws" {
    region = "eu-north-1"
    default_tags {
      tags = {
      environment = "dev"
      Project = "terraform-aws-infra"
    }
    }
}

module "vpc" {
    source = "../../modules/vpc"
    vpc_cidr = "10.0.0.0/16"
    environment = "dev"
    private_subnets = { "eu-north-1a" = "10.0.11.0/24", "eu-north-1b" = "10.0.12.0/24" }
    public_subnets = { "eu-north-1a" = "10.0.1.0/24",  "eu-north-1b" = "10.0.2.0/24" }
}

module "db" {
    source = "../../modules/db"
    environment = "dev"
    vpc_id = module.vpc.vpc_id
    private_subnet_ids = module.vpc.private_subnets_ids
    app_security_group_id = module.app.security_group_id
}

module "app" {
    source = "../../modules/app"
    environment = "dev"
    vpc_id = module.vpc.vpc_id
    subnet_id = module.vpc.public_subnets_ids[0]
    db_host = module.db.db_host
    db_name = module.db.db_name
    db_secret_arn = module.db.db_secret_arn

}