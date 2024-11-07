import boto3
import json

def lambda_handler(event, context):
    # Deserializar el JSON en el cuerpo de la solicitud
    body = json.loads(event.get("body", "{}"))

    # Inicializar cliente de EC2 en la región deseada
    region = body.get("region", "us-east-1")  # Usa us-east-1 como predeterminado
    ec2_client = boto3.client("ec2", region_name=region)
    
    # Obtener la lista de instancias del JSON
    instances = body.get("instances", [])
    
    # Validar el arreglo de instancias
    if not instances:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "No instances provided"})
        }
    
    results = []

    for instance in instances:
        instance_id = instance.get("id_instance")
        action = instance.get("action", "").lower()

        # Verificar que los parámetros estén completos
        if not instance_id or action not in ["terminate", "stop"]:
            results.append({
                "instance_id": instance_id,
                "status": "error",
                "message": "Invalid parameters: id_instance and action are required with valid values"
            })
            continue
        
        # Ejecutar la acción solicitada
        try:
            if action == "terminate":
                ec2_client.terminate_instances(InstanceIds=[instance_id])
                results.append({
                    "instance_id": instance_id,
                    "status": "terminated"
                })
            elif action == "stop":
                ec2_client.stop_instances(InstanceIds=[instance_id])
                results.append({
                    "instance_id": instance_id,
                    "status": "stopped"
                })
        except Exception as e:
            results.append({
                "instance_id": instance_id,
                "status": "error",
                "message": str(e)
            })

    return {
        "statusCode": 200,
        "body": json.dumps(results)
    }
