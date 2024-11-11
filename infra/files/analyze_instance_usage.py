import boto3
import json
from datetime import datetime, timezone, timedelta

def get_instance_price(instance_type, region, is_running=True):
    # Cliente de la API de Pricing (usaremos la región us-east-1, que es el endpoint principal de Pricing)
    pricing_client = boto3.client('pricing', region_name='us-east-1')
    
    # Definir el filtro para la consulta de precios
    product_filters = [
        {'Type': 'TERM_MATCH', 'Field': 'instanceType', 'Value': instance_type},
        {'Type': 'TERM_MATCH', 'Field': 'location', 'Value': region},
        {'Type': 'TERM_MATCH', 'Field': 'operatingSystem', 'Value': 'Linux'},  # Suponiendo que se usa Linux
        {'Type': 'TERM_MATCH', 'Field': 'preInstalledSw', 'Value': 'NA'},
        {'Type': 'TERM_MATCH', 'Field': 'tenancy', 'Value': 'Shared'},
        {'Type': 'TERM_MATCH', 'Field': 'capacitystatus', 'Value': 'Used'}
    ]
    
    # Tipo de precio basado en si la instancia está corriendo o detenida
    usage_type = "BoxUsage" if is_running else "StoppedUsage"
    
    # Obtener el precio
    try:
        response = pricing_client.get_products(
            ServiceCode='AmazonEC2',
            Filters=product_filters,
            MaxResults=1
        )
        # Parsear el precio de la respuesta
        price_list = json.loads(response['PriceList'][0])
        terms = price_list["terms"]["OnDemand"]
        for term in terms.values():
            for price_dimension in term["priceDimensions"].values():
                price_per_hour = float(price_dimension["pricePerUnit"]["USD"])
                return price_per_hour
    except Exception as e:
        print(f"Error fetching instance price: {str(e)}")
        return None

def lambda_handler(event, context):
    # Obtener los parámetros desde el evento
    if "body" in event and isinstance(event["body"], str):
        body = json.loads(event["body"])
    else:
        body = event

    instance_id = body.get("id_instance")
    region = body.get("region")

    if not instance_id:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "No instance ID provided"})
        }

    if not region:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "No region provided"})
        }

    ec2_client = boto3.client("ec2", region_name=region)

    try:
        # Obtener el tipo de instancia y el estado actual
        instance_info = ec2_client.describe_instances(InstanceIds=[instance_id])
        instance_type = instance_info['Reservations'][0]['Instances'][0]['InstanceType']
        instance_state = instance_info['Reservations'][0]['Instances'][0]['State']['Name']
        
        print(f"Instance Type: {instance_type}, State: {instance_state}")

        # Obtener precios dinámicos
        if instance_state == "running":
            cost_per_hour = get_instance_price(instance_type, region, is_running=True)
            total_cost_running = round(cost_per_hour, 2) if cost_per_hour else "Pricing unavailable"
            stop_count = 0
            stop_events = []
            total_cost_stopped = 0.0
        elif instance_state == "stopped":
            cost_per_hour = get_instance_price(instance_type, region, is_running=False)
            total_cost_stopped = round(cost_per_hour, 2) if cost_per_hour else "Pricing unavailable"
            stop_count = 1
            stop_events = [{
                "start_time": datetime.now(timezone.utc).isoformat(),
                "end_time": (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
            }]
            total_cost_running = 0.0
        else:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": f"Instance is in an unsupported state: {instance_state}"})
            }
        
        total_cost = (total_cost_running or 0.0) + (total_cost_stopped or 0.0)

        # Resultado final
        result = {
            "instance_id": instance_id,
            "instance_type": instance_type,
            "state": instance_state,
            "stop_count": stop_count,
            "stop_periods": stop_events,
            "total_cost_running": total_cost_running,
            "total_cost_stopped": total_cost_stopped,
            "total_cost": total_cost
        }

        return {
            "statusCode": 200,
            "body": json.dumps(result)
        }

    except Exception as e:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": f"Error fetching instance state or pricing: {str(e)}"})
        }
