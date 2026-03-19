data "aws_iam_policy_document" "flowlogs_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flowlogs_role" {
  name               = "${var.project_name}-flowlogs-role"
  assume_role_policy = data.aws_iam_policy_document.flowlogs_assume.json
}

resource "aws_iam_role_policy" "flowlogs_policy" {
  role = aws_iam_role.flowlogs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.flowlogs.arn}/*"
      }
    ]
  })
}
