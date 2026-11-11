resource "aws_security_group" "db" {
    name = "${var.environment}-db-sg"
    vpc_id = var.vpc_id

    ingress {
        description = "MySQL from the app server only"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [var.app_security_group_id]
    }
}

resource "aws_db_subnet_group" "main" {
    name = "${var.environment}-db-subnets"
    subnet_ids = var.private_subnet_ids
}
resource "aws_db_instance" "main" {
    identifier = "${var.environment}-mysql"
    engine = "mysql"
    engine_version = "8.4"
    instance_class = var.instance_class
    allocated_storage = 20
    storage_type = "gp3"
    db_name = var.db_name
    username = "appadmin"
    manage_master_user_password = true
    db_subnet_group_name = aws_db_subnet_group.main.name
    vpc_security_group_ids = [aws_security_group.db.id]
    publicly_accessible = false
    skip_final_snapshot = true
}


