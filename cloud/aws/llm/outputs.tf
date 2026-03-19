data "aws_caller_identity" "current" {}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "flowlogs_bucket" {
  value = aws_s3_bucket.flowlogs.bucket
}

output "glue_database" {
  value = aws_glue_catalog_database.this.name
}

output "glue_table" {
  value = aws_glue_catalog_table.flowlogs.name
}
