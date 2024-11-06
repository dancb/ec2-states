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

# Lambda Function
resource "aws_lambda_function" "list_ec2_instances" {
  function_name = "list_ec2_instances"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  role         = aws_iam_role.lambda_exec_role.arn
  filename     = "${path.module}/files/lambda_function.zip"  # Ruta al archivo ZIP en la carpeta 'files'
  timeout      = 15 
  memory_size  = 256
}


# Crear el archivo ZIP con el código de Lambda
# Ejecuta este comando en el terminal para crear el archivo lambda.zip
# zip -j lambda.zip lambda_function.py

# Añadir permisos para que Lambda acceda a CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

output "lambda_function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.list_ec2_instances.arn
}
