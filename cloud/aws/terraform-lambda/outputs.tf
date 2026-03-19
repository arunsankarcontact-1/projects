output "lambda_name" {
  value = aws_lambda_function.demo_lambda.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.demo_lambda.arn
}
