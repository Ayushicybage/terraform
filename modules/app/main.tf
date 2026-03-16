resource "aws_security_group" "app_sg" {
  vpc_id = var.vpc_id
  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # internal only
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  count         = 2
  ami           = "ami-05efc83cb5512477c"
  instance_type = "t3.micro"
  subnet_id     = var.private_subnets[count.index]
  key_name      = var.key_name
  security_groups = [aws_security_group.app_sg.id]
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nodejs

    cat <<APP > /home/ec2-user/app.js
    const http = require('http');

    const server = http.createServer((req, res) => {
      res.writeHead(200, {'Content-Type': 'text/plain'});
      res.end("Hello from App Server");
    });

    server.listen(8080);
    APP

    node /home/ec2-user/app.js &
    EOF

      tags = { Name = "app-${count.index + 1}" }
    }
