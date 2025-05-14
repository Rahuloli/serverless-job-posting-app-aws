import json
import os
import boto3

sqs = boto3.client('sqs')
QUEUE_URL = os.environ['QUEUE_URL']

def lambda_handler(event, context):
    body = json.loads(event['body'])
    job_id = body.get('job_id')
    job_name = body.get('job_name')

    if not job_id or not job_name:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Missing job_id or job_name'})
        }

    message = json.dumps({
        'job_id': job_id,
        'job_name': job_name
    })

    response = sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=message
    )

    return {
        'statusCode': 200,
        'body': json.dumps({'messageId': response['MessageId']})
    }
