provider "aws" {
  profile = "default"
  region  = "us-east-1"
  default_tags {
    tags = {
      Challenge = 01
      Environment = "DNX"
    }
  }
}

resource "aws_vpc" "vpc-10_0_0_0-16" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-challenge-01",
  }
}

resource "aws_subnet" "subnet-10_0_10_0-24" {
  vpc_id            = aws_vpc.vpc-10_0_0_0-16.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-challenge-01"
  }
}

resource "aws_internet_gateway" "ig-10_0_0_0-16" {
  vpc_id = aws_vpc.vpc-10_0_0_0-16.id

  tags = {
    Name = "ig-challenge-01"
  }
}

resource "aws_route_table" "public_rt-10_0_0_0-16" {
  vpc_id = aws_vpc.vpc-10_0_0_0-16.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig-10_0_0_0-16.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.ig-10_0_0_0-16.id
  }

  tags = {
    Name = "pr-challenge-01"
  }
}

resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.subnet-10_0_10_0-24.id
  route_table_id = aws_route_table.public_rt-10_0_0_0-16.id
}

resource "aws_security_group" "web_sg" {
  name   = "HTTP, HTTPS, LARAVEL, MySQL and SSH"
  vpc_id = aws_vpc.vpc-10_0_0_0-16.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_instance" {
  ami           = "ami-0557a15b87f6559cf"
  instance_type = "t2.micro"
  key_name      = "abaruchi_dev_aws_KeyPair"

  subnet_id                   = aws_subnet.subnet-10_0_10_0-24.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  provisioner "file" {
    source      = "./appl_install_challenge-01.sh"
    destination = "/tmp/appl_install_challenge-01.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/appl_install_challenge-01.sh",
      "sudo /tmp/appl_install_challenge-01.sh",
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    password    = ""
    private_key = file("/Users/abaruchi/abaruchi_dev_aws_KeyPair.pem")
    host        = self.public_ip
  }

  tags = {
    "Name" : "EC2-DNX-Challenge-01"
  }
}