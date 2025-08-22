# Aurora MySQL Cluster
resource "aws_rds_cluster" "aurora_mysql" {
  cluster_identifier      = "${var.project_name}-aurora-mysql"
  engine                 = "aurora-mysql"
  database_name          = "dev"
  master_username        = "admin"
  master_password        = "Skill53##"

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = {
    Name = "${var.project_name}-aurora-mysql"
  }
}

# Writer Instance
resource "aws_rds_cluster_instance" "aurora_writer" {
  identifier         = "${var.project_name}-aurora-writer"
  cluster_identifier = aws_rds_cluster.aurora_mysql.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.aurora_mysql.engine
  engine_version     = aws_rds_cluster.aurora_mysql.engine_version
  
  tags = {
    Name = "${var.project_name}-aurora-writer"
  }
}

# Reader Instance (Multi-AZ)
resource "aws_rds_cluster_instance" "aurora_reader" {
  identifier         = "${var.project_name}-aurora-reader"
  cluster_identifier = aws_rds_cluster.aurora_mysql.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.aurora_mysql.engine
  engine_version     = aws_rds_cluster.aurora_mysql.engine_version
  availability_zone  = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-aurora-reader"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  
  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}