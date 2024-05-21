provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-11"
    key    = "path/to/your/terraform.tfstate"
    region = "us-east-2"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}




resource "aws_db_instance" "mysql" {
  identifier        = "mysql-instance"
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  username          = "admin"
  password          = "password"
  db_subnet_group_name = "my-db-subnet-group"
  skip_final_snapshot = true

  monitoring_interval = 60
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
}

resource "aws_db_instance" "postgresql" {
  identifier        = "postgresql-instance"
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "postgres"
  engine_version    = "13.3"
  instance_class    = "db.t3.micro"
  username          = "admin"
  password          = "password"
  db_subnet_group_name = "my-db-subnet-group"
  skip_final_snapshot = true

  monitoring_interval = 60
  enabled_cloudwatch_logs_exports = ["postgresql"]
}




resource "aws_cloudwatch_log_group" "rds_log_group" {
  name              = "/aws/rds/instance/logs"
  retention_in_days = 30
}

resource "aws_cloudtrail" "main" {
  name                          = "main"
  s3_bucket_name                = "cloudtrail-logs-bucket-11"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
}



resource "aws_dms_replication_instance" "ambrose" {
  replication_instance_id   = "ambrose-dms"
  replication_instance_class = "dms.t3.micro"
  allocated_storage         = 50
  publicly_accessible       = true
}



resource "aws_dms_endpoint" "source" {
  endpoint_id   = "mysql-source"
  endpoint_type = "source"
  engine_name   = "mysql"
  username      = "admin"
  password      = "password"
  server_name   = aws_db_instance.mysql.endpoint
  port          = 3306
  database_name = "mydatabase"
}

resource "aws_dms_endpoint" "target" {
  endpoint_id   = "postgresql-target"
  endpoint_type = "target"
  engine_name   = "postgres"
  username      = "admin"
  password      = "password"
  server_name   = aws_db_instance.postgresql.endpoint
  port          = 5432
  database_name = "mydatabase"
}


resource "aws_dms_replication_task" "ambrose" {
  replication_task_id          = "ambrose-task"
  replication_instance_arn     = aws_dms_replication_instance.ambrose.replication_instance_arn
  source_endpoint_arn          = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn          = aws_dms_endpoint.target.endpoint_arn
  migration_type               = "full-load-and-cdc"
  table_mappings               = <<EOF
{
  "rules": [{
    "rule-type": "selection",
    "rule-id": "1",
    "rule-name": "1",
    "object-locator": {
      "schema-name": "%",
      "table-name": "%"
    },
    "rule-action": "include"
  }]
}
EOF
  replication_task_settings = <<EOF
{
  "TargetMetadata": {
    "TargetSchema": "",
    "SupportLobs": true,
    "FullLobMode": false,
    "LobChunkSize": 64,
    "LimitedSizeLobMode": true,
    "LobMaxSize": 32,
    "InlineLobMaxSize": 0,
    "LoadMaxFileSize": 0,
    "ParallelLoadThreads": 0,
    "ParallelLoadBufferSize": 0,
    "BatchApplyEnabled": true,
    "TaskRecoveryTableEnabled": false
  }
}
EOF
}
