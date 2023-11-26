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

variable keypair-path {}

#variable avail_zone {
#    description = "List of availability zones name in the region"
#    type = list
#}

variable subnets_cidr_blocks {
    description = "list of subnets cidr block"
    type = list 
}

variable private_key {}

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

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = var.cidr_blocks[0].name
  }
}

resource "aws_route_table" "my-rtb" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id 
  }

  tags = {
    Name = var.cidr_blocks[0].name
  }
}

resource "aws_eip" "my-eip" {
  domain   = "vpc"

  tags = {
    Name = var.cidr_blocks[0].name
  }
}

resource "aws_nat_gateway" "my-nat" {
  allocation_id = aws_eip.my-eip.id
  subnet_id     = aws_subnet.pub-subnet-2.id

  tags = {
    Name = var.cidr_blocks[0].name
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.my-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-nat.id
  }

  tags = {
    Name = var.cidr_blocks[0].name
  }
}

resource "aws_route_table_association" "rtb-ass" {
  subnet_id      = aws_subnet.pub-subnet-2.id
  route_table_id = aws_route_table.my-rtb.id
}

resource "aws_route_table_association" "rtb-ass2" {
  subnet_id      = aws_subnet.pub-subnet-1.id
  route_table_id = aws_route_table.my-rtb.id
}

resource "aws_security_group" "my-sg" {
  name        = "testing-sg"
  description = "Allow ssh and http inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description      = "Allow ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   ingress {
    description      = "Open port 8080"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.cidr_blocks[0].name
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.pub-subnet-2.id
  associate_public_ip_address = true 
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.my-sg.id]
  # user_data = file("entry.sh")
  count = 1 

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ubuntu"
    private_key = file(var.private_key)
  }

  provisioner "file" {
    source = "entry.sh" #absolute/relative path on local machine
    destination = "/home/ubuntu/entry.sh" #absolute path on remote machine
  }


  provisioner "remote-exec" {
    inline = [ "export ENV=dev", "mkdir Newdir", "chmod +x entry.sh", "./entry.sh"]
    # script = file("entry.sh")
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > ~/output.txt"
  }
                
  tags = {
    Name = var.cidr_blocks[0].name
  }
}

resource "aws_key_pair" "keypair" {
  key_name   = "keypair"
  public_key =  file(var.keypair-path)
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20230919"]
  }

  owners = ["099720109477"] 
}

output "ami-id" {
    value = data.aws_ami.ubuntu
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

output "public_ip" {
    value = aws_instance.web.public_ip
}




