provider "aws" {
  region = "ap-south-1"
}

# Security Group
resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow SSH and HTTP"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance with Apache
resource "aws_instance" "web" {
  ami                    = "ami-01760eea5c574eb86"
  instance_type          = "t3.micro"
  key_name               = "linux"
  subnet_id              = "subnet-08dbbb43dfb6df023" # Replace with your subnet
  vpc_security_group_ids = [aws_security_group.example.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Welcome to the Web Server</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "web-server"
  }
}

# Load Balancer
resource "aws_lb" "example" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.example.id]
  subnets            = ["subnet-08dbbb43dfb6df023", "subnet-004fc57ee3a304edc"]
}

# Target Group
resource "aws_lb_target_group" "example" {
  name     = "example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0703f392f3f3624d1"
}

# Listener
resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

# Attach EC2 to Target Group
resource "aws_lb_target_group_attachment" "example" {
  target_group_arn = aws_lb_target_group.example.arn
  target_id        = aws_instance.web.id
  port             = 80
}

# Outputs
output "load_balancer_dns_name" {
  value = aws_lb.example.dns_name
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}