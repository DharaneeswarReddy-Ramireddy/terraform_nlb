# Create VPC
resource "aws_vpc" "dharan_main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dharan-main-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "dharan_main_igw" {
  vpc_id = aws_vpc.dharan_main_vpc.id

  tags = {
    Name = "dharan-main-igw"
  }
}

# Create Subnet
resource "aws_subnet" "dharan_main_subnet" {
  vpc_id                  = aws_vpc.dharan_main_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "dharan-main-subnet"
  }
}

# Create Route Table
resource "aws_route_table" "dharan_main_route_table" {
  vpc_id = aws_vpc.dharan_main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dharan_main_igw.id
  }

  tags = {
    Name = "dharan-main-route-table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "dharan_main_rta" {
  subnet_id      = aws_subnet.dharan_main_subnet.id
  route_table_id = aws_route_table.dharan_main_route_table.id
}

# Create Network ACL
resource "aws_network_acl" "dharan_main_nacl" {
  vpc_id = aws_vpc.dharan_main_vpc.id

  # Inbound rules
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Outbound rules
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "dharan-main-nacl"
  }
}

# Associate NACL with Subnet
resource "aws_network_acl_association" "dharan_main_nacl_association" {
  subnet_id     = aws_subnet.dharan_main_subnet.id
  network_acl_id = aws_network_acl.dharan_main_nacl.id
}

# Create Security Group for Nginx and SSH
resource "aws_security_group" "dharan_nginx_sg" {
  name        = "dharan-nginx-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.dharan_main_vpc.id

  # Allow HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch EC2 Instance
resource "aws_instance" "dharan_nginx_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.dharan_nginx_sg.id]
  subnet_id              = aws_subnet.dharan_main_subnet.id

  user_data = file("${path.module}/nginx-setup.sh")

  tags = {
    Name = "dharan-nginx-instance"
  }
}

# Create Network Load Balancer
resource "aws_lb" "dharan_nlb" {
  name               = "dharan-nginx-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.dharan_main_subnet.id]

  enable_deletion_protection = false
}

# Create Target Group
resource "aws_lb_target_group" "dharan_nginx_tg" {
  name     = "dharan-nginx-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.dharan_main_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# Register Target with Target Group
resource "aws_lb_target_group_attachment" "dharan_nginx_attachment" {
  target_group_arn = aws_lb_target_group.dharan_nginx_tg.arn
  target_id        = aws_instance.dharan_nginx_instance.id
  port             = 80
}

# Create NLB Listener
resource "aws_lb_listener" "dharan_http_listener" {
  load_balancer_arn = aws_lb.dharan_nlb.arn
  port              = 80
  protocol          = "TCP" 

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dharan_nginx_tg.arn
  }
}

# Route53 Record for Subdomain
resource "aws_route53_record" "dharan_nginx_subdomain_record" {
  zone_id = var.zone_id
  name    = "dharan-nginx.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.dharan_nlb.dns_name
    zone_id                = aws_lb.dharan_nlb.zone_id
    evaluate_target_health = true
  }
}
