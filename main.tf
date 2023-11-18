provider "aws" {
    region = "us-east-1"
}

variable cidr_blocks {
    description = "cidr blocks and name tags for vpc and subnets"
    type = list(object({
        cidr_block = string
        name = string
    }))
}

#variable avail_zone {
#    description = "List of availability zones name in the region"
#    type = list
#}

variable subnets_cidr_blocks {
    description = "list of subnets cidr block"
    type = list 
}

resource "aws_vpc" "my-vpc" {
    cidr_block = var.cidr_blocks[0].cidr_block 
    instance_tenancy = "default"
    tags = {
        Name = var.cidr_blocks[0].name
    }
}

resource "aws_subnet" "priv-subnet-1" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = var.subnets_cidr_blocks[0]
    availability_zone = data.aws_availability_zones.available.names[0]
    tags = {
        Name = var.cidr_blocks[0].name
    }
}

resource "aws_subnet" "pub-subnet-1" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = var.subnets_cidr_blocks[1]
    availability_zone = data.aws_availability_zones.available.names[0]
    tags = {
        Name = var.cidr_blocks[0].name
    }
}

resource "aws_subnet" "priv-subnet-2" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = var.subnets_cidr_blocks[2]
    availability_zone = data.aws_availability_zones.available.names[1]
    tags = {
        Name = var.cidr_blocks[0].name
    }
}

resource "aws_subnet" "pub-subnet-2" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = var.subnets_cidr_blocks[3]
    availability_zone = data.aws_availability_zones.available.names[1]
    tags = {
        Name = var.cidr_blocks[0].name
    }
}

data "aws_availability_zones" "available" {
  state = "available"
}

output "vpc-id" {
    value = aws_vpc.my-vpc.id
}

output "priv-subnet1-id" {
    value = aws_subnet.priv-subnet-1.id
}

output "priv-subnet2-id" {
    value = aws_subnet.priv-subnet-2.id
}

output "pub-subnet1-id" {
    value = aws_subnet.pub-subnet-1.id
}

output "pub-subnet2-id" {
    value = aws_subnet.pub-subnet-2.id
}

output "Azs" {
    value = data.aws_availability_zones.available.names
}




