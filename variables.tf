variable "region" {
  description = "The AWS region to deploy in"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "The instance type for EC2"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "The ID of the AMI to use for the instance"
  type        = string
  default     = "ami-04dd23e62ed049936"
}

variable "domain_name" {
  description = "The domain name registered in Route53"
  type        = string
  default     = "snehith-dev.com"
}

variable "zone_id" {
  description = "The ID of the hosted zone in Route53"
  type        = string
  default     = "Z02643105FG2WWSOWHBY"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "21.2.0.0/16"
}

variable "subnet_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "21.2.1.0/24"
}
