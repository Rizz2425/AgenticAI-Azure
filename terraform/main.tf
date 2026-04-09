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
  ami           = "ami-0dee22c13ea7a9a67" # Ubuntu 22.04 LTS in Mumbai
  instance_type = "t2.micro"             # Free tier eligible
  
  vpc_security_group_ids = [aws_security_group.django_sg.id]

  tags = {
    Name = "DjangoServer-AWS"
  }
}

# 3. Output (VM ka IP address dikhane ke liye)
output "instance_ip" {
  value = aws_instance.django_server.public_ip
}