terraform {
  required_version = "1.3.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.36.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc_WebSite" {
  cidr_block           = "172.16.0.0/20"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc_WebSite"
  }
}

resource "aws_security_group" "SG_WebSite" {
  name        = "SG_WebSite"
  description = "Firewal"
  vpc_id      = aws_vpc.vpc_WebSite.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "SG_WebSite"
  }
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.vpc_WebSite.id
  tags = {
    Name = "IGW"
  }
}

# ************* Sub Redes Prublicas **************

resource "aws_subnet" "public_subnet_1e" {
  vpc_id                  = aws_vpc.vpc_WebSite.id
  cidr_block              = "172.16.15.0/24"
  availability_zone       = "us-east-1e"
  map_public_ip_on_launch = true
  tags = {
    Name = "Sub-rede pública"
  }
}

# ************* Route Prublica **************

resource "aws_route_table" "Public_RT" {
  vpc_id = aws_vpc.vpc_WebSite.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = "Public Routing Table"
  }
}

resource "aws_route_table_association" "Public_RT_Association" {
  subnet_id      = aws_subnet.public_subnet_1e.id
  route_table_id = aws_route_table.Public_RT.id
}

resource "aws_network_interface" "card1_app_WebSite" {
  subnet_id       = aws_subnet.public_subnet_1e.id
  private_ips     = ["172.16.15.10"]
  security_groups = [aws_security_group.SG_WebSite.id]

  tags = {
    Name = "primary_network_interface"
  }
}

# ********** instancias ***********

resource "aws_key_pair" "deployer" {
  key_name   = "backend_key"
  public_key = file("./keys/key_rsa.pub")
}

data "aws_ami" "ubuntu_last" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "app_WebSite" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.ubuntu_last.id
  key_name      = aws_key_pair.deployer.key_name
  monitoring    = true

  network_interface {
    network_interface_id = aws_network_interface.card1_app_WebSite.id
    device_index         = 0
  }

  tags = {
    Name        = "app_WebSite"
    Provisioner = "TerraForm"
  }
}

resource "null_resource" "run-install" {
  connection {
    host        = aws_instance.app_WebSite.public_ip
    user        = "ubuntu"
    type        = "ssh"
    private_key = file("./keys/key_rsa")
  }
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "curl -fsSL https://get.docker.com -o get-docker.sh",       # Baixa o docker
      "sudo sh get-docker.sh",                                    # Instalar o docker
      "sudo docker run -d -p 80:80 --name web belloinfo/devops:3" # Executar o container
    ]
  }
}

output "public_ip" {
  value = aws_instance.app_WebSite.public_ip
}

