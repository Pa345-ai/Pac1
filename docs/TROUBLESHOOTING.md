<!--
AWS Terraform Starter Kit
Copyright (c) 2025 RUWANPURAGE PAVITHRA PARAMI RANASINGHE
Licensed for single commercial use - See LICENSE.txt
-->

# Customer Troubleshooting Guide

### 1. "Access Denied" when starting the App
- **The Problem:** Your ECS containers can't read secrets or write logs.
- **The Fix:** Ensure the `project_name` in your `terraform.tfvars` matches the name you used during `./setup.sh`. The security roles are locked to this specific name.

### 2. "502 Bad Gateway" (ALB Error)
- **The Problem:** The Load Balancer can't find your app.
- **The Fix:** Ensure your Dockerfile exposes the same port as `container_port` in your variables (default is 3000). Also, ensure your app has a health check route at `/` that returns 200 OK.

### 3. "KMS Key Pending Deletion"
- **The Problem:** You ran `terraform destroy` and immediately tried to `apply` again.
- **The Fix:** AWS keeps KMS keys for 7 days before deleting. If you are testing, change your `project_name` to create a fresh set of keys.

### 4. "GitHub Action Failed at Security Scan"
- **The Problem:** You modified the Terraform code and introduced a security risk.
- **The Fix:** Check the logs of the "Security Audit" step. It will pinpoint the line. This kit is designed to block insecure deployments.
- 
