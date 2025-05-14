# Serverless SQS Application (AWS Lambda + API Gateway + SQS)

This project creates a serverless application where an API Gateway endpoint invokes a Lambda function that sends messages to an SQS queue.

## 🛠️ Stack

- AWS Lambda
- API Gateway (HTTP API)
- Amazon SQS
- Terraform (IaC)
- Python 3.9

## 🚀 Deployment

1. **Install dependencies**

```bash
cd lambda/send_to_sqs
pip install -r requirements.txt -t .
cd ../..
```

2. **Initialize Terraform**

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

3. **Test the API**

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from my client!"}' \
  https://your-api-endpoint/send
```

4. **Check Outputs**

Terraform will output the API Gateway URL.

## 📦 Notes

- Lambda permissions are restricted to sending messages only to the specific SQS queue.
- Environment variables are used for dynamic queue URLs.

## 🔁 Cleanup

```bash
terraform destroy -auto-approve
```
