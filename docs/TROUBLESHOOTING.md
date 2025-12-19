# Troubleshooting & Common Issues

### 1. "Task stopped" or "Task failed to start"
- **Check Logs:** Go to CloudWatch -> Log Groups -> /ecs/myapp-production.
- **Common Cause:** Missing environment variables or incorrect Secrets Manager ARNs.
- **Common Cause:** The Docker image in ECR does not match the architecture (Ensure you build for `linux/amd64`).

### 2. "Terraform Backend Error" (S3/DynamoDB)
- **Fix:** Ensure you ran `bin/setup.sh` first.
- **Fix:** Ensure your AWS CLI is logged in (`aws sts get-caller-identity`).

### 3. "Health Check Failed" (502 Bad Gateway)
- **Fix:** Ensure your app is actually listening on the `container_port` defined in `terraform.tfvars`. 
- **Fix:** Ensure your app has a `/` (root) route that returns a 200 OK status.

### 4. "Access Denied" on Secrets
- **Fix:** If you added new secrets manually, ensure the IAM Execution Role has permissions to the specific Secret ARN (Updated in `iam.tf`).
- 
