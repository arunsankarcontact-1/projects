resource "aws_s3_bucket" "flowlogs" {
  bucket = "${var.project_name}-flowlogs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_lifecycle_configuration" "flowlogs_lifecycle" {
  bucket = aws_s3_bucket.flowlogs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = var.flowlog_retention_days
    }
  }
}

resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.project_name}-athena-results-${data.aws_caller_identity.current.account_id}"
}
