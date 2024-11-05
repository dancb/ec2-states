# Asegúrate de tener un rol en cada cuenta que Lambda pueda asumir. 
# El rol EC2ReadOnlyRole en cada cuenta debe tener permisos para leer las instancias EC2. 
# Este rol se puede crear manualmente o mediante Terraform en cada cuenta:

resource "aws_iam_role" "EC2ReadOnlyRole" {
  name = "EC2ReadOnlyRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          AWS = "<account_id_of_main_account>" // Aqui va el account_id_of_main_account
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_read_only" {
  role       = aws_iam_role.EC2ReadOnlyRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}
