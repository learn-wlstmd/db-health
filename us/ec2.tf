resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "keypair" {
  key_name   = var.key_name
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "bastion_local" {
  filename = "${pathexpand("~\\Downloads\\${var.key_name}")}"  
  content  = tls_private_key.key.private_key_pem
}

resource "aws_security_group" "ec2_secgroup" {
  name   = "${var.project_name}-${var.security_groups_ec2_name}"
  vpc_id = module.vpc.vpc_id
  description = "MyIP SSH Connect Inbound Security Groups"
 
  ingress {
    protocol    = var.ec2_ingress.protocol
    from_port   = var.ec2_ingress.from_port
    to_port     = var.ec2_ingress.to_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 5000
    to_port          = 5000
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    protocol    = var.ec2_egress.protocol
    from_port   = var.ec2_egress.from_port
    to_port     = var.ec2_egress.to_port
    cidr_blocks = var.ec2_egress.cidr_blocks
  }

  tags = {
    Name = "${var.project_name}-${var.security_groups_ec2_name}"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.aws_iam_role_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = var.aws_iam_role_name
    Environment = "dev"
  }
}

resource "aws_iam_policy_attachment" "ec2_role_policy_attachment" {
  name       = "ec2-admin-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  roles      = [aws_iam_role.ec2_role.name]
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name        = "${var.project_name}-ec2-instance-profile"
    Environment = "dev"
  }
}

data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name                   = "${var.project_name}-${var.ec2_name}"
  instance_type          = var.instance_type
  key_name               = aws_key_pair.keypair.key_name
  monitoring             = var.monitoring
  vpc_security_group_ids = [aws_security_group.ec2_secgroup.id]
  subnet_id              = element(module.vpc.public_subnets, 0)
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  ami                    = data.aws_ami.amzn-linux-2023-ami.id

  metadata_options = {
    "http_endpoint"               = "enabled"
    "http_tokens"                 = "required"
    "http_put_response_hop_limit" = 2
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  user_data = <<-EOF
  #!/bin/bash
  sudo yum install python-pip -y
  sudo pip3 install flask pymysql
  cat << EOPYTHON > /home/ec2-user/db-health.py
  from flask import Flask
  import pymysql
  from pymysql import OperationalError

  app = Flask(__name__)

  @app.route('/ap/health')
  def ap_health_check():
    try:
      connection = pymysql.connect(
        db='dev',  
        user='admin',  
        password='Skill53##',  
        host='AP_ENDPOINT',  
        port=3306  
      )
      connection.close()
      return "healthy", 200
    except OperationalError:
      return "unhealthy", 404

  @app.route('/us/health')
  def us_health_check():
    try:
      connection = pymysql.connect(
        db='dev',  
        user='admin',  
        password='Skill53##',  
        host='US_ENDPOINT',  
        port=3306  
      )
      connection.close()
      return "healthy", 200
    except OperationalError:
      return "unhealthy", 404

  if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True, port=5000)
  EOPYTHON
EOF
}