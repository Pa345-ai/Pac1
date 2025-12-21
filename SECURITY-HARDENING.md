# 🛡️ Security Architecture & Hardening Guide

This document explains the current security design of this Terraform kit and provides a step-by-step "Hardening" guide for enterprises requiring strict compliance (SOC2, ISO27001, etc.).

---

## 1. Public Connectivity (ALB)

### Current Design: "Startup-First"
In `alb.tf` and `security.tf`, the Load Balancer is set to `internal = false` and allows Port 80.
* **Why?** Most startups need their application to be reachable over the internet immediately for demos, users, and external webhooks.
* **Risk:** The endpoint is discoverable by the public internet.

### 🛡️ How to Harden
1.  **Enable Deletion Protection:** In `alb.tf`, change `enable_deletion_protection` to `true`.
2.  **Add HTTPS (SSL/TLS):** Register a domain in Route53, request an ACM Certificate, and update the `aws_lb_listener` to use Port 443 with the certificate ARN.
3.  **Restrict Ingress:** If using CloudFront, change the Security Group in `security.tf` to only allow traffic from CloudFront IP ranges instead of `0.0.0.0/0`.

---

## 2. Outbound Traffic (Egress)

### Current Design: "Developer-Friendly"
In `security.tf`, the Security Groups allow all outbound traffic (`0.0.0.0/0`).
* **Why?** Applications often depend on external APIs (Stripe, OpenAI, SendGrid). Restricting these manually can break your app during the early stages of development.
* **Risk:** If a container is compromised, it could theoretically communicate with a malicious external server.

### 🛡️ How to Harden
1.  **Pin Egress Rules:** Identify the specific CIDR blocks or Security Groups for your Database and known APIs.
2.  **Update `security.tf`:** Replace the `0.0.0.0/0` in the `egress` block with specific destination CIDRs.

---

## 3. IAM & Least Privilege

### Current Design: "Functional Scoping"
In `iam.tf` and `networking.tf`, some log resources use wildcards (e.g., `log-stream:*`).
* **Why?** AWS VPC Flow Logs and ECS generate dynamic stream names based on IDs that don't exist until the infrastructure is deployed. Wildcards ensure logs flow without manual intervention.
* **Risk:** The role has permission to write to any stream within that specific Log Group (though still limited to your account).

### 🛡️ How to Harden
1.  **Resource Limiting:** After your first deployment, identify the exact resource ARNs and replace the `*` in `iam.tf`.
2.  **Audit `tfsec:ignore`:** We have bypassed certain scanner alerts to prioritize speed. For a formal audit, address each `# tfsec:ignore` comment by adding a WAF or private links (PrivateLink).

---

## 4. Secrets Management

### Current Design: "Structure-Ready"
In `secrets.tf`, we use AWS Secrets Manager with KMS encryption and include placeholder keys.
* **Why?** This prevents developers from hardcoding keys in the app code. We use `lifecycle { ignore_changes = [secret_string] }` so Terraform won't overwrite your real keys once you enter them.
* **Risk:** Storing a "placeholder" string in code is safe, but accidentally committing a real key is not.

### 🛡️ How to Harden
1.  **Manual Input:** Always enter real production secrets via the **AWS Console** or **AWS CLI**—never type them into the `.tf` files.
2.  **Enable Rotation:** In the AWS Secrets Manager console, turn on "Automatic Rotation" for your database credentials.

---

## 5. Infrastructure State Logic

### Current Design: "Local to Remote"
The `backend.tf` file is currently commented out.
* **Why?** You cannot enable a remote backend until the S3 bucket and DynamoDB table actually exist. This "Two-Step" process prevents errors during the very first run.
* **Risk:** If your local machine crashes before moving to a remote backend, you lose the "map" of your infrastructure.

### 🛡️ How to Harden
1.  **Bootstrap Immediately:** Follow the instructions in `backend.tf` to create the S3 bucket.
2.  **Migrate:** Uncomment the backend block and run `terraform init -migrate-state`. This ensures your team can collaborate safely and prevents state corruption.

---



> **Note:** This architecture follows the AWS Well-Architected Framework. While the "Startup" defaults are safe for general use, hardening is a continuous process as your enterprise scales.

