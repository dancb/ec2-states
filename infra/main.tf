provider "aws" {
  region = "us-east-1"
}

# Rol para Lambda con políticas personalizadas para cada función
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# ==========================================
# Lambda Function: list_ec2_instances
# ==========================================

# Política para permitir que la Lambda liste instancias EC2
resource "aws_iam_role_policy" "lambda_list_policy" {
  name = "lambda_list_policy"
  role = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "list_ec2_instances" {
  function_name = "list_ec2_instances"
  handler       = "list_instances.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = "${path.module}/files/list_instances.zip"
  timeout       = 20 
  memory_size   = 256
}

resource "aws_lambda_function_url" "lambda_function_url" {
  function_name      = aws_lambda_function.list_ec2_instances.function_name
  authorization_type = "NONE"
  depends_on         = [aws_lambda_function.list_ec2_instances]
}

output "lambda_function_url" {
  description = "URL pública de la función Lambda para listar instancias EC2"
  value       = aws_lambda_function_url.lambda_function_url.function_url
}

# ==========================================
# Lambda Function: manage_ec2_instances
# ==========================================

# Política para que Lambda pueda detener y terminar instancias EC2
resource "aws_iam_role_policy" "lambda_ec2_manage_policy" {
  name = "lambda_ec2_manage_policy"
  role = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:StopInstances",
          "ec2:TerminateInstances"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "manage_ec2_instances" {
  function_name = "manage_ec2_instances"
  handler       = "manage_instances.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = "${path.module}/files/manage_instances.zip"
  timeout       = 20 
  memory_size   = 256
}

resource "aws_lambda_function_url" "manage_lambda_function_url" {
  function_name      = aws_lambda_function.manage_ec2_instances.function_name
  authorization_type = "NONE"
  depends_on         = [aws_lambda_function.manage_ec2_instances]
}

output "manage_lambda_function_url" {
  description = "URL pública de la función Lambda para detener y terminar instancias"
  value       = aws_lambda_function_url.manage_lambda_function_url.function_url
}

# ==========================================
# Lambda Function: analyze_ec2_instance_usage
# ==========================================

# Política para que Lambda acceda a CloudWatch, describa estados de instancias EC2 y obtenga precios de instancias
resource "aws_iam_role_policy" "lambda_ec2_analyze_policy" {
  name = "lambda_ec2_analyze_policy"
  role = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstances",
          "cloudwatch:GetMetricData",
          "pricing:GetProducts"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "analyze_ec2_instance_usage" {
  function_name = "analyze_ec2_instance_usage"
  handler       = "analyze_instance_usage.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = "${path.module}/files/analyze_instance_usage.zip"
  timeout       = 20 
  memory_size   = 256
}

resource "aws_lambda_function_url" "analyze_lambda_function_url" {
  function_name      = aws_lambda_function.analyze_ec2_instance_usage.function_name
  authorization_type = "NONE"
  depends_on         = [aws_lambda_function.analyze_ec2_instance_usage]
}

output "analyze_lambda_function_url" {
  description = "URL pública de la función Lambda para analizar el uso de la instancia y costos"
  value       = aws_lambda_function_url.analyze_lambda_function_url.function_url
}

# ==========================================
# Permisos para CloudWatch Logs en todas las funciones Lambda
# ==========================================
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
