terraform {
  required_version = "~>1.3.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.36.1"
    }
  }
}

provider "aws" {
  region  = "us-east-2"
  profile = "pt5aluno9"
}

# ********** instancias ***********

resource "aws_key_pair" "deployer" {
  key_name   = "belicio_key"
  public_key = file("./keys/key_rsa.pub")
}

resource "aws_instance" "app_WebSite" {
  count         = var.size
  instance_type = "t2.micro"
  ami           = data.aws_ami.ubuntu_last.id
  key_name      = aws_key_pair.deployer.key_name
  monitoring    = true

  network_interface {
    network_interface_id = aws_network_interface.card_Belicio[count.index].id
    device_index         = 0
  }

  tags = {
    Name        = "${var.aluno}_${var.name_instacia}_${count.index}"
    Provisioner = "TerraForm"
  }
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt upgrade -y
    sleep 10
    sudo apt update
    EOF
}

output "public_ip" {
  value = aws_instance.app_WebSite.*.public_ip
}

output "private_ip" {
  value = aws_instance.app_WebSite.*.private_ip
}
