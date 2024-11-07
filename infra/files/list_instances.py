import boto3
import json
from datetime import datetime, timezone

def lambda_handler(event, context):
    # Deserializar el JSON en el cuerpo de la solicitud
    body = json.loads(event.get("body", "{}"))
    
    # Obtener los parámetros de account_ids y region
    account_ids = body.get("account_ids", [])
    region = body.get("region", "us-east-1")

    ec2_data = []

    for account_id in account_ids:
        sts_client = boto3.client("sts")
        # Asume un rol en la cuenta especificada
        assumed_role = sts_client.assume_role(
            RoleArn=f"arn:aws:iam::{account_id}:role/EC2ReadOnlyRole",
            RoleSessionName="EC2StatusSession"
        )
        
        # Crea una sesión con las credenciales asumidas
        session = boto3.Session(
            aws_access_key_id=assumed_role["Credentials"]["AccessKeyId"],
            aws_secret_access_key=assumed_role["Credentials"]["SecretAccessKey"],
            aws_session_token=assumed_role["Credentials"]["SessionToken"],
        )

        ec2_client = session.client("ec2", region_name=region)

        # Listar instancias EC2 y sus tags
        instances = ec2_client.describe_instances()
        for reservation in instances["Reservations"]:
            for instance in reservation["Instances"]:
                # Obtener el tipo de instancia y el tiempo de ejecución
                instance_type = instance["InstanceType"]
                launch_time = instance["LaunchTime"]
                
                # Calcular tiempo de ejecución en horas
                current_time = datetime.now(timezone.utc)
                uptime_hours = (current_time - launch_time).total_seconds() / 3600

                # Definir costo por hora (tarifa de ejemplo)
                cost_per_hour = 0.02  # Cambiar según el tipo de instancia o tarifa actual de AWS

                # Calcular costo total
                total_cost = uptime_hours * cost_per_hour

                ec2_info = {
                    "InstanceId": instance["InstanceId"],
                    "State": instance["State"]["Name"],
                    "InstanceType": instance_type,
                    "UptimeHours": round(uptime_hours, 2),
                    "TotalCost": round(total_cost, 2),
                    "Tags": instance.get("Tags", [])
                }
                ec2_data.append(ec2_info)

    return {
        "statusCode": 200,
        "body": json.dumps(ec2_data)
    }
