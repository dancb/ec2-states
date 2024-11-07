import boto3
import json
from datetime import datetime, timezone

def lambda_handler(event, context):
    # Deserializar el JSON en el cuerpo de la solicitud
    body = json.loads(event.get("body", "{}"))
    instance_id = body.get("id_instance")
    region = body.get("region", "us-east-1")  # Usa us-east-1 como predeterminado

    if not instance_id:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "No instance ID provided"})
        }

    ec2_client = boto3.client("ec2", region_name=region)
    cloudwatch_client = boto3.client("cloudwatch", region_name=region)

    # Obtener el historial de estados de la instancia
    try:
        state_changes = ec2_client.describe_instance_status(InstanceIds=[instance_id], IncludeAllInstances=True)
        status_history = state_changes["InstanceStatuses"][0]["Events"]
    except Exception as e:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": f"Error fetching instance status: {str(e)}"})
        }

    # Contar las veces que la instancia estuvo detenida y almacenar los periodos
    stop_events = []
    stop_count = 0
    total_cost_running = 0.0
    total_cost_stopped = 0.0
    cost_per_hour_running = 0.02  # Tarifa por hora cuando está en ejecución
    cost_per_hour_stopped = 0.005  # Tarifa por hora cuando está detenida (almacenamiento de EBS)

    # Obtener las métricas de inicio y parada desde CloudWatch
    metric_data = cloudwatch_client.get_metric_data(
        MetricDataQueries=[
            {
                'Id': 'stopMetric',
                'MetricStat': {
                    'Metric': {
                        'Namespace': 'AWS/EC2',
                        'MetricName': 'StatusCheckFailed_Instance',
                        'Dimensions': [{'Name': 'InstanceId', 'Value': instance_id}]
                    },
                    'Period': 3600,
                    'Stat': 'Sum'
                },
                'ReturnData': True
            }
        ],
        StartTime=datetime(2023, 1, 1, tzinfo=timezone.utc),
        EndTime=datetime.now(timezone.utc)
    )

    for data_point in metric_data['MetricDataResults'][0]['Timestamps']:
        if metric_data['MetricDataResults'][0]['Values'][0] > 0:
            stop_count += 1
            stop_events.append({
                "start_time": data_point.isoformat(),
                "end_time": (data_point + timedelta(hours=1)).isoformat()
            })
            # Calcula el costo del periodo detenido
            total_cost_stopped += cost_per_hour_stopped

    # Calcular el tiempo de ejecución total
    uptime_hours = len(metric_data['MetricDataResults'][0]['Values']) - stop_count
    total_cost_running = uptime_hours * cost_per_hour_running

    result = {
        "instance_id": instance_id,
        "stop_count": stop_count,
        "stop_periods": stop_events,
        "total_cost_running": round(total_cost_running, 2),
        "total_cost_stopped": round(total_cost_stopped, 2),
        "total_cost": round(total_cost_running + total_cost_stopped, 2)
    }

    return {
        "statusCode": 200,
        "body": json.dumps(result)
    }
