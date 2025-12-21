🔒 Infrastructure Hardening Guide
This guide provides step-by-step instructions to transition your infrastructure from a "Startup-Ready" (flexible) state to an "Enterprise-Grade" (hardened) state.
1. Application Load Balancer (ALB) Hardening
By default, the ALB is open for easy testing. For production environments, apply these changes in alb.tf and security.tf:
 * Enable Deletion Protection: Prevent accidental deletion via the CLI or Console.
   # alb.tf
enable_deletion_protection = true

 * Enforce HTTPS Only: Remove the Port 80 listener and ensure all traffic is encrypted.
 * Restrict Ingress: If your app is behind a WAF or CloudFront, change the ALB Security Group to only allow traffic from those specific CIDR ranges rather than 0.0.0.0/0.
2. Network Egress Control (Least Privilege)
To prevent "data exfiltration" (where a compromised container sends data to an unknown server), restrict outbound traffic in security.tf.
 * Current State: Allows all outbound (0.0.0.0/0).
 * Hardened State: Identify the specific IP ranges for your database, Stripe API, or OpenAI endpoints, and allow outbound traffic only to those destinations.
3. IAM Policy Tightening
The current kit uses some wildcards (e.g., * for log stream ARNs) to ensure logs work immediately as AWS generates dynamic IDs.
 * Refine Resources: Once your CloudWatch Log Groups are stable, update iam.tf to replace resource wildcards with the specific ARNs of your resources.
 * Audit "tfsec" Ignores: Review every line marked with # tfsec:ignore. These were added to prioritize "Speed to Market." For an enterprise audit, you should resolve the underlying warning and remove the ignore tag.
4. Secrets Lifecycle Management
While the kit uses AWS Secrets Manager (Best Practice), you can further harden secrets.tf:
 * Rotate Secrets: Enable "Rotation" in the AWS Console for your Database and API keys.
 * Remove Placeholders: Ensure that no developer ever commits a real key to the secret_string block. We recommend managing secret values directly in the AWS Console after the initial terraform apply.
5. Production State Management
Before going live, finalize your backend.tf:
 * Initialize the Backend: Follow the bootstrap commands in backend.tf to create your S3 bucket and DynamoDB table.
 * Uncomment & Migrate: Uncomment the terraform { backend "s3" {...} } block.
 * Run Migration: Execute terraform init -migrate-state. This moves your infrastructure "memory" from your local machine to the encrypted AWS cloud, preventing state loss or corruption.
✨ This hardening guide was prepared by the project maintainers to assist in meeting compliance requirements (SOC2/ISO27001).
