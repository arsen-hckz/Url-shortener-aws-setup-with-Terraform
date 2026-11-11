variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
   type = string
   default = "t3.micro"
}

variable "image" {
    type = string
    default = "ghcr.io/arsen-hckz/shortener:latest"
}
variable "db_host" {
    type = string
}

variable "db_name" {
    type =string
}

variable "db_secret_arn" {
    type = string
}


