<!--
AWS Terraform Starter Kit
Copyright (c) 2025 RUWANPURAGE PAVITHRA PARAMI RANASINGHE
Licensed for single commercial use - See LICENSE.txt
-->

# AWS Terraform Starter Kit – The 2-Week Shortcut
**Version 1.0.0** | Released December 2025
**Ship your SaaS MVP in 10 minutes, not 2 weeks.**

Built for solo founders and small teams who need production-ready AWS infrastructure without the DevOps rabbit hole.

---

## The Problem

You're a founder with a working prototype. You need to get it live. Fast.

But first you need:
- **Enterprise-Grade Encryption:** Application logs and secrets are encrypted at rest with AWS KMS Customer Managed Keys.
- **Zero-Trust Networking:** Your application is isolated in Private Subnets, accessible only through a hardened Load Balancer.
- **Secure Secret Management:** Production keys are managed via AWS Secrets Manager with automatic decryption for your ECS tasks.
- **Least-Privilege IAM:** Security roles are strictly scoped to your project name to ensure "Zero-Trust" access control.

**This takes 2-3 weeks.** Minimum.

During those weeks, you're not talking to customers. You're not iterating on your product. You're fighting Terraform documentation at 2 AM wondering why your NAT Gateway won't route traffic.

---

## The Solution

This starter kit gives you everything above in **10 minutes**.

---

## ⚡ Built for Speed & Scalability

This kit is designed to get startups and small enterprises launched in minutes. By default, it prioritizes **"Fast-to-Market"** configurations to ensure your app and third-party integrations (like Stripe and OpenAI) work out of the box without complex networking hurdles.

* **Public Load Balancing:** Accessible via the internet immediately for demos and users.
* **Open Outbound Connectivity:** Connect to any external API without manual firewall configuration.

> 🔒 **Need higher security?** If you are deploying for a large enterprise or require strict compliance (SOC2/ISO27001), please follow the step-by-step instructions in [HARDENING.md](./SECURITY-HARDENING.md) to transition to a locked-down production environment.

---





It's the infrastructure foundation that I've deployed dozens of times for clients. The same patterns. The same security practices. The same cost optimizations.

You get to skip straight to the part where you're shipping features and talking to users.

---

## Architecture at a Glance

This is a **lean, production-ready stack**. No enterprise bloat. No compliance theater. Just what you need to launch.

```
┌─────────────────────────────────────────────────────────────┐
│                         INTERNET                             │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
             [ Hardened Load Balancer (Public) ]
                           │
             ┌─────────────┴─────────────┐
             ▼                           ▼
      [ ECS Service ]             [ ECS Service ]
      (Private Subnet)            (Private Subnet)
             │                           │
             └─────────────┬─────────────┘
                           ▼
           [ KMS & AWS Secrets Manager (Encrypted) ]

```

**What you get:**
- **VPC** with public/private subnets across 2 availability zones
- **Application Load Balancer** with health checks
- **ECS Fargate** for running containers (no servers to manage)
- **Security Groups** with least-privilege access
- **IAM Roles** scoped correctly for ECS tasks
- **CloudWatch Logs** for debugging (encrypted with KMS)
- **VPC Flow Logs** for network monitoring (encrypted with KMS)
- **Secrets Manager** for API keys (Stripe, OpenAI, etc.) with KMS encryption
- **GitHub Actions** pipeline for one-click deploys with security scanning
- **S3 Remote State** so you don't lose your infrastructure
- **tfsec Security Scanning** built into CI/CD pipeline

**What's NOT included** (and why):
- ❌ HTTPS/SSL – You need a domain first (add ACM certificate when ready)
- ❌ Auto-scaling – Start with fixed capacity, add later if needed
- ❌ Database – Use managed services (Supabase, PlanetScale, RDS)
- ❌ Multi-region – You don't need this on day one
- ❌ WAF/DDoS protection – Add when you have real traffic
- ❌ Compliance certifications – Not relevant for MVPs

---

## The 10-Minute Launch

### Prerequisites

- AWS account (free tier eligible)
- AWS CLI installed and configured (`aws configure`)
- Terraform installed (>= 1.5.0)
- Docker installed
- A Dockerfile for your application

### Step 1: Clone this repository

```bash
git clone <your-repo-url>
cd aws-terraform-starter
```

### Step 2: Run the automated setup script

```bash
chmod +x bin/setup.sh
./bin/setup.sh
```

This script will:
- Create S3 bucket for Terraform state (with versioning and encryption)
- Create DynamoDB table for state locking
- Create ECR repository for your Docker images
- Update `backend.tf` with your bucket name
- Create a starter `terraform.tfvars` file

**IMPORTANT:** Edit the variables at the top of `bin/setup.sh` first:
```bash
PROJECT_NAME="myapp"  # Change this to your project name
REGION="us-east-1"    # Change if you want a different region
```

### Step 3: Configure your project

Edit `terraform/terraform.tfvars`:

```hcl
project_name = "myapp"
environment  = "production"
aws_region   = "us-east-1"

# Your Docker image (we'll build this in step 5)
container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp-production:latest"
container_port  = 3000

# Start small, scale later
cpu            = 256
memory         = 512
desired_count  = 1

# Environment variables for your app
app_environment_variables = [
  {
    name  = "NODE_ENV"
    value = "production"
  },
  {
    name  = "PORT"
    value = "3000"
  }
]
```

### Step 4: Enable remote state backend

Uncomment the backend block in `terraform/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state-1234567890"  # Updated by setup.sh
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
```

Then initialize:
```bash
cd terraform
terraform init
```

### Step 5: Deploy infrastructure

```bash
# Preview changes
terraform plan -var="project_name=myapp"

# Deploy (takes 8-12 minutes)
terraform apply -var="project_name=myapp"
```

Type `yes` when prompted. Grab coffee. ☕

### Step 6: Build and deploy your app

```bash
# Get your AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and push
docker build -t myapp-production .
docker tag myapp-production:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/myapp-production:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/myapp-production:latest

# Update ECS to use new image
aws ecs update-service \
  --cluster myapp-production-cluster \
  --service myapp-production-service \
  --force-new-deployment \
  --region us-east-1
```

### Step 7: Get your URL

```bash
terraform output alb_url
```

Visit that URL. **Your app is live.** 🚀

---

## Setting Up CI/CD (Push to Deploy)

The included GitHub Actions workflow lets you deploy by pushing to `main`.

### One-time setup:

1. **Add secrets to your GitHub repo** (Settings → Secrets and variables → Actions → New repository secret):

   **CRITICAL SECRETS (Required):**
   - `AWS_ACCESS_KEY_ID` - Your AWS access key
   - `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
   - `PROJECT_NAME` - **MUST match the name you used in `terraform apply`** (e.g., `myapp`)
   
   **Infrastructure Secrets:**
   - `ECR_REPOSITORY_NAME` - e.g., `myapp-production`
   - `ECS_SERVICE_NAME` - e.g., `myapp-production-service`
   - `ECS_CLUSTER_NAME` - e.g., `myapp-production-cluster`

   > ⚠️ **CRITICAL:** The `PROJECT_NAME` secret is required for IAM security policies to work. If this is missing or incorrect, your deployment will fail with "Access Denied" errors.

2. **Get the exact values** from Terraform outputs:
   ```bash
   cd terraform
   echo "ECS_CLUSTER_NAME: $(terraform output -raw ecs_cluster_name)"
   echo "ECS_SERVICE_NAME: $(terraform output -raw ecs_service_name)"
   ```

3. **Push to deploy:**

```bash
git add .
git commit -m "Deploy to production"
git push origin main
```

GitHub Actions will:
1. ✅ Run security scan with tfsec
2. 🐳 Build your Docker image
3. 📤 Push to ECR
4. 🔧 Run `terraform apply`
5. 🚀 Deploy to ECS
6. ⏳ Wait for service stability
7. ✅ Output deployment URL

**5-8 minutes later, your changes are live.**

---

## Managing Secrets (Stripe, OpenAI, etc.)

**Never hardcode API keys.** Use AWS Secrets Manager instead.

### Update your secrets:

```bash
aws secretsmanager put-secret-value \
  --secret-id myapp-production-app-secrets \
  --secret-string '{
    "STRIPE_SECRET_KEY": "sk_live_YOUR_KEY",
    "OPENAI_API_KEY": "sk-YOUR_KEY",
    "JWT_SECRET": "your-random-string",
    "DATABASE_URL": "postgresql://..."
  }' \
  --region us-east-1
```

### Access in your app (Node.js example):

```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager({ region: 'us-east-1' });

const getSecrets = async () => {
  const secret = await secretsManager.getSecretValue({
    SecretId: 'myapp-production-app-secrets'
  }).promise();
  return JSON.parse(secret.SecretString);
};

// Use in your app
const secrets = await getSecrets();
const stripe = require('stripe')(secrets.STRIPE_SECRET_KEY);
```

**The secrets are automatically injected into your ECS containers** through the task definition. No code changes needed!

---

## Monitoring Your App

### View logs:

```bash
aws logs tail /ecs/myapp-production --follow --region us-east-1
```

### Check ECS service health:

```bash
aws ecs describe-services \
  --cluster myapp-production-cluster \
  --services myapp-production-service \
  --region us-east-1 \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Deployments:deployments[*].status}'
```

### CloudWatch dashboard:

Go to AWS Console → CloudWatch → Log groups → `/ecs/myapp-production`

All logs are encrypted at rest with KMS for security compliance.

---

## Cost Breakdown

Running 24/7 with minimal traffic:

| Service | Monthly Cost |
|---------|--------------|
| ECS Fargate (1 task, 0.25 vCPU, 0.5 GB) | $12 |
| Application Load Balancer | $18 |
| NAT Gateway | $32 |
| Data transfer (light usage) | $5-10 |
| CloudWatch Logs (7-day retention) | $3 |
| VPC Flow Logs (30-day retention) | $2 |
| Secrets Manager | $0.50 |
| KMS Keys (2 keys) | $2 |
| ECR storage (~500 MB) | $0.05 |
| S3 + DynamoDB (state) | $0.60 |
| **Total** | **~$75-80/month** |

**Ways to reduce costs:**
- Use a smaller Fargate task (0.25 vCPU / 0.5 GB is the minimum)
- Delete the NAT Gateway if you don't need outbound internet (~$32 saved, but loses ability to call external APIs)
- Reduce log retention periods
- Use free tier RDS or external database providers

---

## Scaling When You're Ready

### Vertical scaling (bigger tasks):

Update `terraform/terraform.tfvars`:
```hcl
cpu    = 512
memory = 1024
```

Run `terraform apply -var="project_name=myapp"`.

### Horizontal scaling (more tasks):

```hcl
desired_count = 3
```

Run `terraform apply -var="project_name=myapp"`.

### Add auto-scaling:

Create `terraform/autoscaling.tf`:

```hcl
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.project_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
```

Run `terraform apply -var="project_name=myapp"`.

---

## Adding HTTPS

Once you have a domain:

1. **Register domain** (Route53, Namecheap, etc.)

2. **Request SSL certificate** in ACM:
```bash
aws acm request-certificate \
  --domain-name myapp.com \
  --domain-name *.myapp.com \
  --validation-method DNS \
  --region us-east-1
```

3. **Add DNS validation records** (ACM console will show you what to add)

4. **Wait for validation** (usually 5-30 minutes)

5. **Update ALB listener** in `terraform/alb.tf`:

```hcl
# Get the certificate ARN
data "aws_acm_certificate" "main" {
  domain   = "myapp.com"
  statuses = ["ISSUED"]
}

# Add HTTPS listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Update HTTP listener to redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

6. **Update security group** in `terraform/security.tf`:

```hcl
# Add to aws_security_group.alb
ingress {
  description = "HTTPS from internet"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

7. **Apply changes:**
```bash
terraform apply -var="project_name=myapp"
```

---

## Troubleshooting

### 1. "Access Denied" when ECS tasks start

**Problem:** Your ECS containers can't read secrets or write logs.

**Fix:** Ensure the `project_name` in your `terraform.tfvars` matches the name you used in `terraform apply`. The IAM policies are scoped to this specific project name for security.

```bash
# Check your current project name
grep project_name terraform/terraform.tfvars

# Ensure you're using the same name
terraform apply -var="project_name=myapp"
```

### 2. "502 Bad Gateway" from ALB

**Problem:** The Load Balancer can't reach your app.

**Fixes:**
- Ensure your Dockerfile `EXPOSE`s the same port as `container_port` in variables (default is 3000)
- Ensure your app has a health check route at `/` that returns 200 OK
- Check logs: `aws logs tail /ecs/myapp-production --follow`

### 3. "KMS Key Pending Deletion"

**Problem:** You ran `terraform destroy` and immediately tried to `apply` again.

**Fix:** AWS keeps KMS keys for 7-30 days before deleting. Options:
- Wait for deletion to complete
- Change your `project_name` to create fresh keys
- Cancel the deletion in AWS Console → KMS

### 4. GitHub Action fails at "Security Audit"

**Problem:** You modified Terraform code and introduced a security risk.

**Fix:** 
- Check the tfsec output in the GitHub Actions logs
- It will show the exact file and line number
- Fix the security issue (usually overly permissive IAM policies or unencrypted resources)

### 5. GitHub Action fails with "PROJECT_NAME not set"

**Problem:** The `PROJECT_NAME` secret is missing from GitHub.

**Fix:**
1. Go to your repo → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `PROJECT_NAME`
4. Value: Your project name (must match what you used in `terraform apply`)

### 6. Terraform errors about missing resources

**Problem:** Resources referenced before they're created.

**Fix:** This starter kit has proper `depends_on` blocks. If you've modified files, ensure dependencies are correct:
- IAM roles before policies
- KMS keys before encrypted resources
- Log groups before services that write to them

---

## Security Best Practices

This starter kit follows AWS security best practices:

✅ **Encryption at Rest:** All logs and secrets encrypted with KMS Customer Managed Keys
✅ **Encryption in Transit:** HTTPS support ready (requires domain)
✅ **Network Isolation:** ECS tasks in private subnets, no public IPs
✅ **Least Privilege IAM:** All policies scoped to specific resources and project name
✅ **VPC Flow Logs:** Network monitoring enabled and encrypted
✅ **Security Scanning:** tfsec runs on every deployment
✅ **Secrets Management:** No hardcoded credentials, all managed by Secrets Manager
✅ **Key Rotation:** KMS keys have automatic rotation enabled
✅ **Audit Trail:** CloudWatch logs with 7-day retention (adjustable)

### Post-deployment security checklist:

- [ ] Update all placeholder secrets in Secrets Manager
- [ ] Set up AWS billing alerts ($100/month threshold)
- [ ] Enable MFA on your AWS root account
- [ ] Create IAM users for team members (never share root credentials)
- [ ] Add HTTPS certificate before going live with real users
- [ ] Review CloudWatch logs weekly
- [ ] Update Terraform and provider versions monthly
- [ ] Rotate secrets quarterly

---

## What's Included

✅ Complete Terraform codebase (9 files, ~800 lines)
✅ VPC with public/private subnets across 2 AZs
✅ Application Load Balancer with health checks
✅ ECS Fargate cluster and service
✅ Security groups (least-privilege configured)
✅ IAM roles (project-scoped, no wildcards)
✅ CloudWatch logging (7-day retention, KMS encrypted)
✅ VPC Flow Logs (30-day retention, KMS encrypted)
✅ Secrets Manager setup (KMS encrypted)
✅ 2 KMS Customer Managed Keys (logs + secrets)
✅ GitHub Actions CI/CD pipeline with tfsec security scanning
✅ S3 remote state configuration (versioned, encrypted)
✅ DynamoDB state locking
✅ Automated setup script
✅ Complete documentation

---

## What's NOT Included

❌ **HTTPS/SSL** – You need to add ACM certificate (10 minutes, instructions above)
❌ **Database** – Use RDS, Supabase, or PlanetScale (external)
❌ **Domain/DNS** – Register separately and point to ALB
❌ **Auto-scaling** – Fixed task count (easy to add, example above)
❌ **Multi-region** – Single region deployment
❌ **High availability** – Single NAT Gateway (cost trade-off)
❌ **WAF/DDoS protection** – Add when you have real traffic
❌ **Custom monitoring dashboards** – Basic CloudWatch only
❌ **Automated backups** – Set up database backups separately
❌ **24/7 Support** – No support included
❌ **Compliance certifications** – No SOC2, HIPAA, PCI guarantees

---

## Known Limitations

### 1. Single NAT Gateway
- **Impact:** If the NAT Gateway fails, your tasks lose outbound internet access for ~5 minutes while AWS replaces it
- **Why:** Saves $32/month. For MVP traffic, this is acceptable
- **When to fix:** When uptime becomes critical (add 2nd NAT Gateway in other AZ)

### 2. No Auto-Scaling
- **Impact:** Your app runs a fixed number of tasks regardless of load
- **Why:** Keeps costs predictable and configuration simple
- **When to fix:** When you see sustained high CPU or need burst capacity

### 3. HTTP Only (No HTTPS)
- **Impact:** Traffic is unencrypted, browsers show "Not Secure"
- **Why:** HTTPS requires a domain and SSL certificate setup
- **When to fix:** Before you go live with real users (see instructions above)

### 4. 7-Day Log Retention
- **Impact:** You can only search logs from the past week
- **Why:** Reduces CloudWatch costs (~$3/month vs ~$10-20/month)
- **When to fix:** When you need audit trails or longer debugging windows

### 5. Single Region
- **Impact:** If `us-east-1` has an outage, your app is down
- **Why:** Multi-region is complex and expensive for MVPs
- **When to fix:** When you need 99.99%+ uptime guarantees

---

## Support & Warranty

**There is no support.** There is no warranty. There is no refund.

This is a starting point. You're responsible for:
- Configuring your AWS account correctly
- Securing your credentials
- Managing costs
- Monitoring your application
- Compliance with laws and regulations
- Adding HTTPS, databases, and other production requirements
- Keeping dependencies updated

If you need enterprise support, hire a DevOps consultant.

---

## Who This Is For

### ✅ Great fit:
- Solo founders launching an MVP
- Freelancers building client apps
- Small teams (1-5 engineers)
- Non-technical founders with basic AWS knowledge
- Developers who want to focus on product, not infrastructure
- Teams with budgets under $5k/month for infrastructure
- Projects that need production-ready security from day one

### ❌ Not a fit:
- Enterprise companies with compliance requirements
- Banks, healthcare, or government projects
- Teams needing SOC2, HIPAA, or PCI certification
- Applications requiring 99.99%+ uptime SLAs
- Multi-tenant SaaS with complex isolation requirements
- Projects with >$50k/month infrastructure budgets
- Teams that need 24/7 support

---

## License

All rights reserved. Licensed for single commercial use per purchase.

You may modify this code for your own projects. You may NOT resell, redistribute, or share this code with others.

See `LICENSE.txt` for full details.

---

## Final Thoughts

DevOps is a **time sink** for founders.

Every hour you spend configuring subnets is an hour you're not:
- Talking to customers
- Shipping features
- Iterating on your product
- Making revenue

This starter kit gives you those hours back.

It's not perfect. It's not enterprise-grade. It won't scale to 100 million users.

But it's **good enough** to launch. And launching is what matters.

The best infrastructure is the infrastructure that gets out of your way so you can build your product.

**Ready to ship?** 🚀

---

## Quick Start Summary

```bash
# 1. Setup AWS resources
./bin/setup.sh

# 2. Initialize Terraform
cd terraform
terraform init

# 3. Deploy infrastructure
terraform apply -var="project_name=myapp"

# 4. Build and push Docker image
docker build -t myapp .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
docker tag myapp:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/myapp-production:latest
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/myapp-production:latest

# 5. Force ECS deployment
aws ecs update-service --cluster myapp-production-cluster --service myapp-production-service --force-new-deployment

# 6. Get your URL
terraform output alb_url
```

**Three critical post-deployment tasks:**

1. **Set up billing alerts** in AWS Console (set at $100/month)
2. **Update the placeholder secrets** in Secrets Manager:
   ```bash
   aws secretsmanager put-secret-value --secret-id myapp-production-app-secrets --secret-string '{"STRIPE_SECRET_KEY":"sk_live_...","OPENAI_API_KEY":"sk-...","JWT_SECRET":"...","DATABASE_URL":"..."}'
   ```
3. **Add your domain and HTTPS certificate** before going live with real users

4. **Set up GitHub Secrets for CI/CD:**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `PROJECT_NAME` (must match terraform project_name)
   - `ECR_REPOSITORY_NAME`
   - `ECS_SERVICE_NAME`
   - `ECS_CLUSTER_NAME`

Then get back to building your product. 🚀

---


---

## 📧 Support & Licensing

**Created by:** RUWANPURAGE PAVITHRA PARAMI RANASINGHE  
**License:** Single Commercial Use (see LICENSE.txt)  
**Contact:** parameeranasinghe33@gmail.com  
**Documentation:** See `/docs` folder for architecture and troubleshooting guides

© 2025 RUWANPURAGE PAVITHRA PARAMI RANASINGHE. All Rights Reserved.
```

For licensing inquiries: [parameeranasinghe33@gmail.com.com]
