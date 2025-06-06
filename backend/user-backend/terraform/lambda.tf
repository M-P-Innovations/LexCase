data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../src"
  output_path = "${path.module}/lambda_source.zip"
  excludes = [
    "**/.env/**",
    "**/otpStore.json/**",
    "**/test-logger/**",
    # "**/node_modules/**"
  ]
}

# Deploy the Lambda function
resource "aws_lambda_function" "cats-user-management-backend-lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.app-component}-lambda"
  role             = aws_iam_role.cats_user_management_backend_lambda_exec_role.arn
  handler          = "index.handler"
  layers           = [data.terraform_remote_state.logging_layer.outputs.lambda-layer]
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs20.x" # Replace with your runtime
  description      = "User management lambda"
  timeout          = 30

  environment {
    variables = {
      "JWT_SECRET"       = "Mysecret"
      "REGION"           = var.region
      "DYNAMODB_NAME"    = aws_dynamodb_table.users.id
      "DEPENDENCY_PATH"  = "/opt/"
      "LOGGING_TABLE"    = "cats-event-logging"
      "LOGGER_ENABLED"   = true
      "DOCS_BUCKET_NAME" = "cats-cases-documents"

    }
  }
}


