#-------------------------------------------------------------
#Create S3 bucket as ETL processes workspace
#-------------------------------------------------------------
resource "aws_s3_bucket" "airflow_workbucket" {
  bucket = "${var.db_name}-workbucket"
  force_destroy = true
  region = var.aws_region
  tags = var.tags
}

#--------------------------------------------------------------
#Create RDS Database as ETL Target
#--------------------------------------------------------------
resource "aws_security_group" "db_security_group" {
  name = "db_security_group"
  description = "Security group for target database"
  //  vpc_id = module.redb-platform.cluster_vpc_id
  tags = var.tags

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "postgresql-tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_db_instance" "db_database" {
  identifier              = "${var.db_name}-db"
  instance_class          = var.db_instance_type
  engine                  = "postgres"
  engine_version          = "11.5"
  name                    = var.db_name
  username                = var.db_username
  password                = var.db_password
  storage_type            = "gp2"
  backup_retention_period = 7
  multi_az                = false
  publicly_accessible     = true
  apply_immediately       = true
  skip_final_snapshot     = true
  vpc_security_group_ids  = ["${aws_security_group.db_security_group.id}"]
  port                    = 5432
  //  db_subnet_group_name    = module.redb-platform.db_subnet_group
  allocated_storage       = 20
}