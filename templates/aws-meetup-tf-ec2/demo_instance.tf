terraform {
  backend "s3" {
    key = "aws-meetup-vienna-demo-tf-state/demo_instance"
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh-key"
  public_key = "${var.ssh_pub_key}"
}


provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.tf_role
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "ssh-key"
  tags = {
    Name = "${var.env}"
  }
}