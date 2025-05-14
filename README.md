# Serverless SQS Application (AWS Lambda + API Gateway + SQS)

## 📌 Purpose: Job Post Processing

This serverless application processes job posting requests using AWS Lambda, API Gateway, and SQS. It is designed to demonstrate a decoupled architecture for handling asynchronous job submissions and processing.

### 🔄 Flow Overview

````markdown

1. **Receives Job Posting via HTTP API**  
   A client sends a POST request to API Gateway with a JSON body:

   ```json
   {
     "job_id": "12345",
     "job_name": "Software Engineer",
     "company_name": "Tech Corp"
   }
   ```
````

2. **Sends the Job Data to an SQS Queue**

   * API Gateway invokes a Lambda function (`sendToSQS`)
   * This function validates the input and pushes the job data into an Amazon SQS queue

3. **Processes Job Data from the Queue**

   * A second Lambda function (`processSQS`) is triggered automatically when a new message arrives in the queue
   * It:

     * Extracts `job_id` and `job_name`.
     * Generates a CSV file containing the job data
     * Uploads the CSV to an Amazon S3 bucket with a timestamped filename

4. **Stores the File in S3**
   Files are saved with a path structure like:

   ```
   s3://your-bucket-name/jobs/job-20250514-153012.csv
   ```

---

## 🛠️ Stack

* AWS Lambda
* API Gateway (HTTP API)
* Amazon SQS
* Amazon S3
* Terraform (Infrastructure as Code)
* Python 3.9

---

## 🚀 Deployment

Follow these steps to deploy the project using Terraform and Python:

### 1. Install Lambda Dependencies

```bash
cd lambda/send_to_sqs
pip install -r requirements.txt -t .
cd ../..
```

### 2. Initialize and Apply Terraform

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

> Terraform will output the API Gateway URL and other important info after successful deployment.

### 3. Test the API

Replace `https://your-api-endpoint/send` with the actual URL provided by Terraform:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"job_id": "12345", "job_name": "Software Engineer", "company_name": "Tech Corp"}' \
  https://your-api-endpoint/send
```

### 4. Check the S3 Bucket

You should see a new CSV file in the configured S3 bucket under the `jobs/` directory with a timestamp in the filename.

---

## 📦 Notes

* **Security**: Lambda functions follow the principle of least privilege and can only access specific AWS services they need.
* **Configuration**: Environment variables are used to dynamically manage the SQS queue URL and S3 bucket name.
* **Reliability**: The decoupled design allows for retry logic, failure handling, and scaling.

---

## 🔁 Cleanup

To destroy all deployed AWS resources:

```bash
cd terraform
terraform destroy -auto-approve
```

---

## 📁 Project Structure

```
.
├── lambda
│   ├── send_to_sqs
│   │   ├── send_to_sqs.py
│   │   └── requirements.txt
│   └── process_sqs
│       └── process_sqs.py
├── terraform
│   └── main.tf
├── README.md
```

---

## 📬 Contact

For questions, suggestions, or contributions, feel free to open an issue or create a pull request.

---
