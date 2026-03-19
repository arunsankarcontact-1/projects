resource "aws_flow_log" "vpc_flowlogs" {
  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.flowlogs.arn
  iam_role_arn         = aws_iam_role.flowlogs_role.arn

  tags = {
    Name = "${var.project_name}-flowlogs"
  }
}
