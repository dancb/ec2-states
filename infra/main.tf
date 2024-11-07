provider "aws" {
  region = "us-east-1"  # Cambia a la región de tu preferencia
}

# Crear el rol para Lambda con permiso para asumir otros roles
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

# Política para permitir que Lambda asuma roles en otras cuentas
resource "aws_iam_role_policy" "lambda_assume_policy" {
  name = "lambda_assume_policy"
  role = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Resource = "arn:aws:iam::*:role/EC2ReadOnlyRole"  # Rol que debe existir en las otras cuentas
      }
    ]
  })
}

# ==========================================
# Lambda Function: list_ec2_instances
# ==========================================
resource "aws_lambda_function" "list_ec2_instances" {
  function_name = "list_ec2_instances"
  handler       = "list_instances.lambda_handler"  # Cambiado para coincidir con el nuevo nombre del archivo
  runtime       = "python3.8"

  role         = aws_iam_role.lambda_exec_role.arn
  filename     = "${path.module}/files/list_instances.zip"  # Ruta al archivo ZIP en la carpeta 'files'
  timeout      = 20 
  memory_size  = 256
}

# Crear URL de función Lambda para list_ec2_instances
resource "aws_lambda_function_url" "lambda_function_url" {
  function_name      = aws_lambda_function.list_ec2_instances.function_name
  authorization_type = "NONE"  # Sin autenticación

  depends_on = [aws_lambda_function.list_ec2_instances]
}

# Añadir permisos para que Lambda acceda a CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

output "lambda_function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.list_ec2_instances.arn
}
output "lambda_function_url" {
  description = "URL pública de la función Lambda"
  value       = aws_lambda_function_url.lambda_function_url.function_url
}

# ==========================================
# Lambda Function: manage_ec2_instances
# ==========================================
# Política para que Lambda pueda detener y terminar instancias EC2
resource "aws_iam_role_policy" "lambda_ec2_policy" {
  name = "lambda_ec2_policy"
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

# Lambda Function para detener y terminar instancias EC2
resource "aws_lambda_function" "manage_ec2_instances" {
  function_name = "manage_ec2_instances"
  handler       = "manage_instances.lambda_handler"
  runtime       = "python3.8"

  role         = aws_iam_role.lambda_exec_role.arn
  filename     = "${path.module}/files/manage_instances.zip"  # Ruta al archivo ZIP en la carpeta 'files'
  timeout      = 20 
  memory_size  = 256
}

# Crear URL de función Lambda para manage_ec2_instances
resource "aws_lambda_function_url" "manage_lambda_function_url" {
  function_name      = aws_lambda_function.manage_ec2_instances.function_name
  authorization_type = "NONE"  # Sin autenticación

  depends_on = [aws_lambda_function.manage_ec2_instances]
}

output "manage_lambda_function_arn" {
  description = "ARN de la función Lambda para detener y terminar instancias"
  value       = aws_lambda_function.manage_ec2_instances.arn
}
output "manage_lambda_function_url" {
  description = "URL pública de la función Lambda para detener y terminar instancias"
  value       = aws_lambda_function_url.manage_lambda_function_url.function_url
}

# ==========================================
# Lambda Function: analyze_ec2_instance_usage
# ==========================================
# Política para que Lambda acceda a CloudWatch y describa estados de instancias EC2
resource "aws_iam_role_policy" "lambda_ec2_analyze_policy" {
  name = "lambda_ec2_analyze_policy"
  role = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:DescribeInstanceStatus",
          "cloudwatch:GetMetricData"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Lambda Function para analizar el uso y costos de una instancia EC2
resource "aws_lambda_function" "analyze_ec2_instance_usage" {
  function_name = "analyze_ec2_instance_usage"
  handler       = "analyze_instance_usage.lambda_handler"
  runtime       = "python3.8"

  role         = aws_iam_role.lambda_exec_role.arn
  filename     = "${path.module}/files/analyze_instance_usage.zip"  # Ruta al archivo ZIP en la carpeta 'files'
  timeout      = 20 
  memory_size  = 256
}

# Crear URL de función Lambda para analyze_ec2_instance_usage
resource "aws_lambda_function_url" "analyze_lambda_function_url" {
  function_name      = aws_lambda_function.analyze_ec2_instance_usage.function_name
  authorization_type = "NONE"  # Sin autenticación

  depends_on = [aws_lambda_function.analyze_ec2_instance_usage]
}

output "analyze_lambda_function_arn" {
  description = "ARN de la función Lambda para analizar el uso de la instancia y costos"
  value       = aws_lambda_function.analyze_ec2_instance_usage.arn
}
output "analyze_lambda_function_url" {
  description = "URL pública de la función Lambda para analizar el uso de la instancia y costos"
  value       = aws_lambda_function_url.analyze_lambda_function_url.function_url
}
