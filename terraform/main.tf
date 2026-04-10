provider "aws" {
  region = "ap-south-1" # Mumbai Region
}

# 1. Security Group (Firewall)
resource "aws_security_group" "django_sg" {
  name        = "django-sg"
  description = "Allow SSH and Django port"

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Django Web Port
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules (Internet Access)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. EC2 Instance (Virtual Machine)
resource "aws_instance" "django_server" {
  ami           = "ami-0dee22c13ea7a9a67" 
  instance_type = "t3.micro"
  key_name      = "terraform-key"
  vpc_security_group_ids = [aws_security_group.django_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              EOF

  tags = {
    Name = "DjangoServer-AWS"
  }
}

# 3. Output (For showing the VM IP Adress)
output "instance_ip" {
  value = aws_instance.django_server.public_ip
}