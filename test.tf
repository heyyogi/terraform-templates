# --------------------------
# Provider Configuration
# --------------------------

provider "aws" {
  region = "ap-south-1"
}


# --------------------------
# Security Group
# --------------------------

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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


# --------------------------
# Launch Template
# --------------------------

resource "aws_launch_template" "web_template" {
  name_prefix   = "terraform-"
  image_id      = "ami-02d26659fd82cf299"  # Amazon Linux 2 AMI (us-west-1)
  instance_type = "t3.micro"
  key_name      = "linux"  # <-- Replace with your actual EC2 key pair name

  # HEREDOC + base64encode for UserData
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    echo "Hello from Terraform EC2 via Auto Scaling!" > /var/www/html/index.html
    systemctl enable httpd
    systemctl start httpd
  EOF
  )

  vpc_security_group_ids = [aws_security_group.web_sg.id]
}


# --------------------------
# Load Balancer
# --------------------------

resource "aws_lb" "web_lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = ["subnet-0d6eaa6d4a2b52f13"]  # Replace with valid subnets
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0703f392f3f3624d1"  # Replace with your actual VPC ID
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}


# --------------------------
# Auto Scaling Group
# --------------------------

resource "aws_autoscaling_group" "web_asg" {
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = ["subnet-0d6eaa6d4a2b52f13"]  # Replace with your subnets

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  tag {
    key                 = "Name"
    value               = "web-instance"
    propagate_at_launch = true
  }
}


# --------------------------
# Output
# --------------------------

output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web_lb.dns_name
}