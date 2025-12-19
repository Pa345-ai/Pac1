# Troubleshooting

### 1. "Access Denied" to Logs or Secrets
- **Reason:** Your `project_name` in `variables.tf` might not match the ARN in `iam.tf`.
- **Fix:** Ensure `project_name` and `environment` variables are consistent. The IAM policy is strictly scoped to these names.

### 2. "KMS Key Not Found"
- **Reason:** You may have deleted and recreated the infrastructure, but the old KMS key is still in a "Pending Deletion" state.
- **Fix:** Use a new `project_name` or wait for the deletion window to clear.

### 3. "tfsec Failure" in GitHub Actions
- **Reason:** You added a resource (like an S3 bucket or a Security Group rule) that violates security best practices.
- **Fix:** Read the `tfsec` output in the GitHub Action logs. It will tell you exactly which line is "insecure."
- 
