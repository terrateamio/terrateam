// Storage for core services
resource "aws_db_subnet_group" "core_storage_subnet_group" {
  name       = "core_storage_subnet_group"
  subnet_ids = [aws_subnet.main_vpc_subnet_1.id, aws_subnet.main_vpc_subnet_2.id, aws_subnet.main_vpc_subnet_3.id]

  tags = local.tags
}

resource "aws_security_group" "core_storage_security_group" {
  name = "Core storage Security group"

  vpc_id = aws_vpc.main_vpc.id

  tags = local.tags
}

resource "aws_security_group_rule" "core_storage_sg_rule" {
  type              = "ingress"
  from_port         = var.core_storage_port
  to_port           = var.core_storage_port
  cidr_blocks       = var.local_ips
  protocol          = "tcp"
  security_group_id = aws_security_group.core_storage_security_group.id
  description       = "Connection from local machine"
}

resource "aws_db_instance" "core_storage" {
  identifier                 = "celsus-core-storage"
  skip_final_snapshot        = "true"
  allocated_storage          = 20
  auto_minor_version_upgrade = "true"
  storage_type               = "gp2"
  engine                     = "postgres"
  instance_class             = "db.t2.micro"
  db_subnet_group_name       = aws_db_subnet_group.core_storage_subnet_group.name
  apply_immediately          = "true"
  availability_zone          = data.aws_availability_zones.available.names[0]
  publicly_accessible        = "true"
  vpc_security_group_ids     = [aws_vpc.main_vpc.default_security_group_id, aws_security_group.core_storage_security_group.id]
  multi_az                   = "false"
  username                   = var.core_storage_username
  password                   = var.core_storage_password
  port                       = var.core_storage_port
  copy_tags_to_snapshot      = "true"
  backup_retention_period    = "7"
  backup_window              = "03:00-06:00"
  tags                       = local.tags
}