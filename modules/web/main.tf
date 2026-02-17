resource "aws_security_group" "web_sg" {
  vpc_id = var.vpc_id
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0c1fe732b5494dc14" # Amazon Linux 2 (us-east-1)
  instance_type = "t3.micro"
  subnet_id     = var.public_subnets[count.index]
  key_name      = var.key_name
  security_groups = [aws_security_group.web_sg.id]
  user_data = <<-EOF
    #!/bin/bash
    sudo yum install -y httpd
    echo "Hello from Web Server ${count.index + 1}" > /var/www/html/index.html
    sudo systemctl enable httpd
    sudo systemctl start httpd
  EOF
  tags = { Name = "web-${count.index + 1}" }
}

resource "aws_lb" "alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.web_sg.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port     = 80
  protocol = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "attach" {
  count             = 2
  target_group_arn  = aws_lb_target_group.tg.arn
  target_id         = aws_instance.web[count.index].id
  port              = 80
}
