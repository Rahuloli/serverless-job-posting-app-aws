import json
import csv
import os
import boto3
from io import StringIO
from datetime import datetime

s3 = boto3.client('s3')
BUCKET_NAME = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    rows = []
    for record in event['Records']:
        body = json.loads(record['body'])
        job_id = body.get('job_id')
        job_name = body.get('job_name')
        if job_id and job_name:
            rows.append([job_id, job_name])

    if rows:
        csv_buffer = StringIO()
        writer = csv.writer(csv_buffer)
        writer.writerow(['JobID', 'JobName'])
        writer.writerows(rows)
        
        timestamp = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
        key = f"jobs/job-{timestamp}.csv"
        
        s3.put_object(Bucket=BUCKET_NAME, Key=key, Body=csv_buffer.getvalue())
        print(f"Uploaded CSV to s3://{BUCKET_NAME}/{key}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Jobs processed and stored in S3.')
    }
