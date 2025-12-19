# Architecture Overview

## The Security Layers
1. **The Vault (Secrets Manager + KMS):** Your API keys (Stripe, OpenAI) are encrypted at rest with a dedicated KMS key. 
2. **The Fortress (VPC):** Traffic enters through an ALB, but the ECS containers live in a Private Subnet with no direct internet access.
3. **The Audit Trail (CloudWatch + KMS):** Every log line emitted by your app is encrypted before being stored.



## Connectivity
Your app uses a **NAT Gateway** for outbound requests (calling Stripe/OpenAI). This ensures your app has a stable outbound IP while staying hidden from inbound attacks.
