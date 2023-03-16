provider "aws" {
  profile = "default"
  region  = "us-east-1"
  default_tags {
    tags = {
      Challenge = 02
      Environment = "DNX"
    }
  }
}

resource "aws_vpc" "vpc-10_0_0_0-16" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-challenge-02",
  }
}

# Creates two Subnets in different Availability Zones
resource "aws_subnet" "subnet-10_0_10_0-24" {
  vpc_id            = aws_vpc.vpc-10_0_0_0-16.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-challenge-02"
  }
}

resource "aws_subnet" "subnet-10_0_20_0-24" {
  vpc_id            = aws_vpc.vpc-10_0_0_0-16.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet-challenge-02"
  }
}

resource "aws_internet_gateway" "ig-10_0_0_0-16" {
  vpc_id = aws_vpc.vpc-10_0_0_0-16.id

  tags = {
    Name = "ig-challenge-02"
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
    Name = "pr-challenge-02"
  }
}

resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.subnet-10_0_10_0-24.id
  route_table_id = aws_route_table.public_rt-10_0_0_0-16.id
}

resource "aws_route_table_association" "public_1_rt_b" {
  subnet_id      = aws_subnet.subnet-10_0_20_0-24.id
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
    from_port   = var.internal_appl_port
    to_port     = var.internal_appl_port
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

resource "aws_security_group" "db_sg" {
  name   = "MySQL_RDS"
  vpc_id = aws_vpc.vpc-10_0_0_0-16.id

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

resource "aws_security_group" "listener_sg" {
  name   = "HTTP"
  vpc_id = aws_vpc.vpc-10_0_0_0-16.id

  ingress {
    from_port   = var.external_appl_port
    to_port     = var.external_appl_port
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
    source      = "./appl_install_challenge-02.sh"
    destination = "/tmp/appl_install_challenge-02.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/appl_install_challenge-02.sh",
      "sudo /tmp/appl_install_challenge-02.sh",
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
    "Name" : "EC2-DNX-challenge-02"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"

  subnet_ids = [
    aws_subnet.subnet-10_0_10_0-24.id,
    aws_subnet.subnet-10_0_20_0-24.id
  ]

  tags = {
    Name = "SubnetGroup-DNX-challenge-02"
  }
}

resource "aws_db_instance" "db_rds" {
  allocated_storage    = 10
  db_name              = "laravel_db"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot  = true

  tags = {
    "Name" : "DB-RDS-DNX-challenge-02"
  }
}

## ALB Configurations
resource "aws_lb" "appl_lb" {
  name               = "ApplLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.listener_sg.id]
  subnets            = [aws_subnet.subnet-10_0_10_0-24.id, aws_subnet.subnet-10_0_20_0-24.id]
  enable_cross_zone_load_balancing = "true"
  tags = {
    "Name" : "APPL-LB-DNX-challenge-02"
  }
}

resource "aws_lb_target_group" "instance_tg" {
  name               = "applTG"
  target_type        = "instance"
  port               = var.internal_appl_port
  protocol           = "HTTP"
  vpc_id             = aws_vpc.vpc-10_0_0_0-16.id

  tags = {
    "Name" : "APPL-TG-DNX-challenge-02"
  }
}

resource "aws_lb_target_group_attachment" "instance_tg_attachment" {
  target_group_arn = aws_lb_target_group.instance_tg.arn
  target_id        = aws_instance.web_instance.id
  port             = var.internal_appl_port
}

resource "aws_lb_listener" "lb_listener_http" {
   load_balancer_arn    = aws_lb.appl_lb.id
   port                 = var.external_appl_port
   protocol             = "HTTP"
   default_action {
    target_group_arn = aws_lb_target_group.instance_tg.id
    type             = "forward"
  }

    tags = {
    "Name" : "LISTENER-APPL-DNX-challenge-02"
  }
}
