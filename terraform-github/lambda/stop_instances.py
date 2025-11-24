import boto3
import os

ec2 = boto3.client('ec2')


def lambda_handler(event, context):
    # Look for instances with tag Key=shutdown Value=true (case-insensitive)
    filters = [
        {
            'Name': 'tag:shutdown',
            'Values': ['true', 'True']
        },
        {
            'Name': 'instance-state-name',
            'Values': ['running']
        }
    ]

    resp = ec2.describe_instances(Filters=filters)
    instance_ids = []
    for reservation in resp.get('Reservations', []):
        for inst in reservation.get('Instances', []):
            instance_ids.append(inst['InstanceId'])

    if not instance_ids:
        print('No running instances found with tag shutdown=true')
        return {'stopped': []}

    print(f'Stopping instances: {instance_ids}')
    stop_resp = ec2.stop_instances(InstanceIds=instance_ids)
    stopped = [i['InstanceId'] for i in stop_resp.get('StoppingInstances', [])]

    return {'stopped': stopped}


if __name__ == '__main__':
    print('This module is intended for AWS Lambda; run tests by invoking lambda_handler({}, {})')
