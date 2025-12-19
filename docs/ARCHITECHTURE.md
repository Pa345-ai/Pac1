# Infrastructure Architecture: Secure Lean Stack

## Core Security Decisions
- **Encryption at Rest:** We use **AWS KMS (Key Management Service)** to encrypt application logs and sensitive secrets. This ensures even if a disk was compromised, your data remains unreadable.
- **Scoped IAM Roles:** Instead of using `Resource: *`, our IAM policies are restricted to specific resource ARNs. This prevents "Lateral Movement" if a container is ever compromised.
- **Automated Security Gates:** We use `tfsec` in the deployment pipeline to ensure no developer accidentally opens a security hole.



## Traffic Flow
1. User -> ALB (Public Subnet)
2. ALB -> ECS Service (Private Subnet)
3. ECS Service -> KMS (Decrypt Secrets)
4. ECS Service -> CloudWatch (Encrypted Logs)
