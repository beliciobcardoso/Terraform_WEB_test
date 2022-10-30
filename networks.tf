resource "aws_vpc" "VPC_Belicio" {
  cidr_block           = "172.16.0.0/20"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC_Belicio"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.VPC_Belicio.id
  cidr_block              = "172.16.15.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Sub-rede pública ${var.aluno}"
  }
}

resource "aws_route_table_association" "Public_RT_Association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.Public_RT.id
}

resource "aws_network_interface" "card_Belicio" {
  count           = var.size
  subnet_id       = aws_subnet.public_subnet.id
  private_ips     = ["172.16.15.1${count.index}"]
  security_groups = [aws_security_group.SG_Belicio.id]

  tags = {
    Name = "primary_network_interface_${count.index}"
  }
}

resource "aws_route_table" "Public_RT" {
  vpc_id = aws_vpc.VPC_Belicio.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
  tags = {
    Name = "Public Routing Table"
  }
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.VPC_Belicio.id
  tags = {
    Name = "IGW"
  }
}
