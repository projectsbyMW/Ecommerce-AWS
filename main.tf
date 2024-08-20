terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.51.1"
    }
  }
}


provider "aws" {
  profile = "prod"
  region = "us-east-1"
               }

############### VARIABLES ################

variable "web_subnet_cidr" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]

}

# Application Subnet CIDR

variable "application_subnet_cidr" {
  type    = list(string)
  default = ["10.0.2.0/24", "10.0.3.0/24"]
}

# Database Subnet CIDR

variable "database_subnet_cidr" {
  type    = list(string)
  default = ["10.0.4.0/24", "10.0.5.0/24"]

}

############### VPC CREATION ################

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "3 Tier VPC"
  }
}

############### SUBNETS CREATION ################

resource "aws_subnet" "public-subnet-web-1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.web_subnet_cidr[0]
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-web-1"
  }
}

resource "aws_subnet" "public-subnet-web-2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.web_subnet_cidr[1]
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-web-2"
  }
}

resource "aws_subnet" "private-subnet-app-1" {
  vpc_id     = aws_vpc.main.id
  availability_zone = "us-east-1a"
  cidr_block = var.application_subnet_cidr[0]

  tags = {
    Name = "private-subnet-app-1"
  }
}

resource "aws_subnet" "private-subnet-app-2" {
  vpc_id     = aws_vpc.main.id
  availability_zone = "us-east-1b"
  cidr_block = var.application_subnet_cidr[1]

  tags = {
    Name = "private-subnet-app-2"
  }
}

resource "aws_subnet" "private-subnet-db-1" {
  vpc_id     = aws_vpc.main.id
  availability_zone = "us-east-1a"
  cidr_block = var.database_subnet_cidr[0]

  tags = {
    Name = "private-subnet-db-1"
  }
}

resource "aws_subnet" "private-subnet-db-2" {
  vpc_id     = aws_vpc.main.id
  availability_zone = "us-east-1b"
  cidr_block = var.database_subnet_cidr[1]

  tags = {
    Name = "private-subnet-db-2"
  }
}

############### INTERNET GATEWAY CREATION ################

resource "aws_internet_gateway" "igw-tf" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

############### ROUTE TABLES CREATION ################

resource "aws_route_table" "public_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-tf.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public-route-1" {
  subnet_id      = aws_subnet.public-subnet-web-1.id
  route_table_id = aws_route_table.public_table.id
}

resource "aws_route_table_association" "public-route-2" {
  subnet_id      = aws_subnet.public-subnet-web-2.id
  route_table_id = aws_route_table.public_table.id
}

############### NAT GATEWAY CREATION ################

resource "aws_eip" "eipfornat" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "nat-tf" {
  allocation_id = aws_eip.eipfornat.id
  subnet_id     = aws_subnet.public-subnet-web-1.id

  tags = {
    Name = "gw NAT"
  }
}

resource "aws_route_table" "private_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-tf.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "private-route-app-1" {
  subnet_id      = aws_subnet.private-subnet-app-1.id
  route_table_id = aws_route_table.private_table.id
}

resource "aws_route_table_association" "private-route-app-2" {
  subnet_id      = aws_subnet.private-subnet-app-2.id
  route_table_id = aws_route_table.private_table.id
}


resource "aws_route_table_association" "private-route-db-1" {
  subnet_id      = aws_subnet.private-subnet-db-1.id
  route_table_id = aws_route_table.private_table.id
}

resource "aws_route_table_association" "private-route-db-2" {
  subnet_id      = aws_subnet.private-subnet-db-2.id
  route_table_id = aws_route_table.private_table.id
}

############### WEB TIER LOAD BALANCER SECURITY GROUP ################

resource "aws_security_group" "lbsg" {
  name        = "Load Balancer Security Group"
  description = "Allow HTTP/HTTPs Traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_http"
  }
}

resource "aws_vpc_security_group_ingress_rule" "lb_http_access" {
  security_group_id = aws_security_group.lbsg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "https_access" {
  security_group_id = aws_security_group.lbsg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_lb_traffic_ipv4" {
  security_group_id = aws_security_group.lbsg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

############### WEB TIER INSTANCE SECURITY GROUP ################

resource "aws_security_group" "wbsg" {
  name        = "Web Server Security Group"
  description = "Allow HTTP Traffic from LB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_http"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_http_access" {
  security_group_id = aws_security_group.wbsg.id
  referenced_security_group_id = aws_security_group.lbsg.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ec2_https_access" {
  security_group_id = aws_security_group.wbsg.id
  referenced_security_group_id = aws_security_group.lbsg.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "ssh_ec2_access" {
  security_group_id = aws_security_group.wbsg.id
  referenced_security_group_id = aws_security_group.lbsg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_vpc_security_group_egress_rule" "allow_all_ec2_traffic_ipv4" {
  security_group_id = aws_security_group.wbsg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

############### APP TIER INSTANCE SECURITY GROUP ################

resource "aws_security_group" "bhsg" {
  name        = "Bastion Host Security Group"
  description = "Allow SSH access for private instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_access" {
  security_group_id = aws_security_group.bhsg.id
  cidr_ipv4         = "122.172.86.145/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_app_traffic_ipv4" {
  security_group_id = aws_security_group.bhsg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

############### DB TIER INSTANCE SECURITY GROUP ################

resource "aws_security_group" "dbsg" {
  name        = "Database Security Group"
  description = "Allow DB access"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_db_access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_access" {
  security_group_id = aws_security_group.dbsg.id
  referenced_security_group_id         = aws_security_group.wbsg.id
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

resource "aws_vpc_security_group_egress_rule" "allow_all_db_traffic_ipv4" {
  security_group_id = aws_security_group.dbsg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

############### INSTANCES ################

resource "aws_instance" "webservertemplate" {
  ami           = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.wbsg.id]
  subnet_id              = aws_subnet.public-subnet-web-1.id
  key_name               = "Jenkins"
  user_data              = "${base64encode(file("${path.module}/install_apache.sh"))}"

  tags = {
    Name = "Web Server"
  }
}

resource "aws_instance" "appservertemplate" {
  ami           = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.bhsg.id]
  subnet_id              = aws_subnet.private-subnet-app-1.id
  key_name               = "Jenkins"

  tags = {
    Name = "App Server"
  }
}


############### AUTOSCALING GROUPS ################

resource "aws_launch_template" "asgtemplateweb" {
  name_prefix   = "asgtemplateweb"
  image_id      = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  key_name               = "Jenkins"
  user_data              = "${base64encode(file("${path.module}/install_apache.sh"))}"
  network_interfaces {
    subnet_id            = aws_subnet.public-subnet-web-1.id
    security_groups      = [aws_security_group.wbsg.id]
  }
  tags = {
    Name = "ASG Web Server"
  }
}

resource "aws_autoscaling_group" "asg01" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 0

  launch_template {
    id      = aws_launch_template.asgtemplateweb.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "asgtemplateapp" {
  name_prefix   = "asgtemplateapp"
  image_id      = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  key_name               = "Jenkins"
  network_interfaces {
    subnet_id            = aws_subnet.private-subnet-app-1.id
    security_groups      = [aws_security_group.bhsg.id]
  }
  tags = {
    Name = "ASG App Server"
  }
}

resource "aws_autoscaling_group" "asg02" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1

  launch_template {
    id      = aws_launch_template.asgtemplateapp.id
    version = "$Latest"
  }
}

############### APPLICATION LOAD BALANCER ################

resource "aws_lb" "app-lb" {
  name               = "web-external-alb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lbsg.id]
  subnets            = [aws_subnet.public-subnet-web-1.id, aws_subnet.public-subnet-web-2.id]
  enable_deletion_protection = false

  tags = {
    Name = "External Web App Load Balancer"
    Environment = "production"
  }
}

resource "aws_lb_target_group" "lbtg" {
  name     = "load-balancer-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "lbtga" {
  target_group_arn = aws_lb_target_group.lbtg.arn
  target_id        = aws_instance.webservertemplate.id
  port             = 80
}

resource "aws_lb_listener" "httplistener" {
  load_balancer_arn = aws_lb.app-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbtg.arn
  }
  }

############### RDS DATABASE INSTANCE ################

resource "aws_db_subnet_group" "database_subnet_group" {
  name       = "main"
  subnet_ids = [aws_subnet.private-subnet-db-1.id,aws_subnet.private-subnet-db-2.id]


  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "rds-db-instance" {
  allocated_storage    = 10
  db_name              = "sqldb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "testuser"
  password             = "password"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.database_subnet_group.name
  multi_az             = true
  vpc_security_group_ids = [aws_security_group.dbsg.id]
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer is: "
  value       = aws_lb.app-lb.dns_name
}

