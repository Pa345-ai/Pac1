# Infrastructure Architecture: The Lean SaaS Stack

This infrastructure is designed for the "Growth Phase." It balances high security and reliability with cost-efficiency for early-stage startups.

## Core Decisions
- **ECS Fargate:** We use Fargate (Serverless) instead of EC2. Why? Because as a founder, you should not be patching Linux kernels or managing SSH keys at 3 AM.
- **Single NAT Gateway:** We use one NAT Gateway shared across private subnets. This saves ~$64/month compared to the "Enterprise" multi-AZ NAT setup, with 99.9% availability.
- **Private Networking:** Your app runs in private subnets. It is physically impossible for the public internet to touch your containers. Only the Load Balancer has a public face.
- **Target Tracking Scaling:** The foundation is ready for auto-scaling. It is currently set to a fixed count to keep your AWS bill predictable during launch.

## Traffic Flow
1. User (HTTPS/HTTP) -> Application Load Balancer (Public Subnet)
2. ALB -> ECS Service (Private Subnet)
3. ECS Service -> NAT Gateway (Outbound Only) -> Internet APIs (Stripe/OpenAI)


