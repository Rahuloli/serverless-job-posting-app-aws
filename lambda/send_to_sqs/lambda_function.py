import json
import os
import boto3

sqs = boto3.client('sqs')
QUEUE_URL = os.environ['QUEUE_URL']

def lambda_handler(event, context):
    body = json.loads(event['body'])
    message = body.get('message', 'Hello from Lambda!')

    response = sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=message
    )

    return {
        'statusCode': 200,
        'body': json.dumps({'messageId': response['MessageId']})
    }
