
variable "cluster_name" {
  default = "lab-01"
}

variable "vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "private_az_subnet_mapping" {
  type        = "list"
  description = "Private subnets to be created in their respective AZ."

  default = [
    {
      name = "lab-01-private-1a"
      az   = "eu-west-1a"
      cidr = "10.1.0.0/20"
    },
    {
      name = "lab-01-private-1b"
      az   = "eu-west-1b"
      cidr = "10.1.16.0/20"
    },
    {
      name = "lab-01-private-1c"
      az   = "eu-west-1c"
      cidr = "10.1.32.0/20"
    },
  ]
}

variable "public_az_subnet_mapping" {
  type        = "list"
  description = "Public subnets to be created in their respective AZ."

  default = [
    {
      name = "lab-01-public-1a"
      az   = "eu-west-1a"
      cidr = "10.1.48.0/20"
    },
    {
      name = "lab-01-public-1b"
      az   = "eu-west-1b"
      cidr = "10.1.64.0/20"
    },
    {
      name = "lab-01-public-1c"
      az   = "eu-west-1c"
      cidr = "10.1.80.0/20"
    },
  ]
}