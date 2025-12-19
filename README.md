# AWS Terraform Starter Kit – The 2-Week Shortcut

**Ship your SaaS MVP in 10 minutes, not 2 weeks.**

Built for solo founders and small teams who need production-ready AWS infrastructure without the DevOps rabbit hole.

---

## The Problem

You're a founder with a working prototype. You need to get it live. Fast.

But first you need:
- A VPC with proper subnets
- Load balancers and health checks
- Container orchestration
- Security groups that don't expose everything
- IAM roles (without giving away the keys to the kingdom)
- Logging and monitoring
- A deployment pipeline

**This takes 2-3 weeks.** Minimum.

During those weeks, you're not talking to customers. You're not iterating on your product. You're fighting Terraform documentation at 2 AM wondering why your NAT Gateway won't route traffic.

---

## The Solution

This starter kit gives you everything above in **10 minutes**.

It's the infrastructure foundation that I've deployed dozens of times for clients. The same patterns. The same security practices. The same cost optimizations.

You get to skip straight to the part where you're shipping features and talking to users.

---

## Architecture at a Glance

This is a **lean, production-ready stack**. No enterprise bloat. No compliance theater. Just what you need to launch.

```
┌─────────────────────────────────────────────────────────────┐
│                         INTERNET                             │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
                ┌──────────────────────┐
                │  Application Load    │  ← HTTP traffic from users
                │     Balancer         │
                └──────────┬───────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
   ┌─────────┐        ┌─────────┐      ┌─────────┐
   │   ECS   │        │   ECS   │      │   ECS   │  ← Your app
   │  Task   │        │  Task   │      │  Task   │     (Fargate)
   └─────────┘        └─────────┘      └─────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                           ▼
                   ┌───────────────┐
                   │ NAT Gateway   │  ← Outbound internet
                   └───────────────┘       (APIs, etc.)
```

**What you get:**
- **VPC** with public/private subnets across 2 availability zones
- **Application Load Balancer** with health checks
- **ECS Fargate** for running containers (no servers to manage)
- **Security Groups** with least-privilege access
- **IAM Roles** scoped correctly for ECS tasks
- **CloudWatch Logs** for debugging
- **Secrets Manager** for API keys (Stripe, OpenAI, etc.)
- **GitHub Actions** pipeline for one-click deploys
- **S3 Remote State** so you don't lose your infrastructure

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
cd aws-terraform-starter
```

### Step 2: Configure your project

Create `terraform.tfvars`:

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

### Step 3: Set up remote state (Safety Net)

This prevents you from losing your infrastructure if your laptop dies.

```bash
# Run these once
aws s3api create-bucket \
  --bucket myapp-terraform-state \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket myapp-terraform-state \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name terraform-state-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Then uncomment the backend block in `backend.tf` and update the bucket name.

```bash
terraform init -migrate-state
```

### Step 4: Deploy infrastructure

```bash
terraform plan
terraform apply
```

Type `yes`. Grab coffee. Takes 8-12 minutes.

### Step 5: Build and deploy your app

```bash
# Create ECR repository
aws ecr create-repository --repository-name myapp-production --region us-east-1

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR-ACCOUNT-ID.dkr.ecr.us-east-1.amazonaws.com

# Build and push
docker build -t myapp-production .
docker tag myapp-production:latest YOUR-ACCOUNT-ID.dkr.ecr.us-east-1.amazonaws.com/myapp-production:latest
docker push YOUR-ACCOUNT-ID.dkr.ecr.us-east-1.amazonaws.com/myapp-production:latest

# Update ECS to use new image
aws ecs update-service \
  --cluster myapp-production-cluster \
  --service myapp-production-service \
  --force-new-deployment
```

### Step 6: Get your URL

```bash
terraform output alb_url
```

Visit that URL. **Your app is live.**

---

## Setting Up CI/CD (Push to Deploy)

The included GitHub Actions workflow lets you deploy by pushing to `main`.

### One-time setup:

1. Add secrets to your GitHub repo (Settings → Secrets → Actions):
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `ECR_REPOSITORY_NAME` (e.g., `myapp-production`)
   - `ECS_SERVICE_NAME` (e.g., `myapp-production-service`)
   - `ECS_CLUSTER_NAME` (e.g., `myapp-production-cluster`)
   - `CONTAINER_NAME` (e.g., `myapp-container`)

2. Push to `main`:

```bash
git add .
git commit -m "Deploy to production"
git push origin main
```

GitHub Actions will:
1. Build your Docker image
2. Push to ECR
3. Run `terraform apply`
4. Deploy to ECS

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
  }'
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

---

## Monitoring Your App

### View logs:

```bash
aws logs tail /ecs/myapp-production --follow
```

### Check ECS service health:

```bash
aws ecs describe-services \
  --cluster myapp-production-cluster \
  --services myapp-production-service
```

### CloudWatch dashboard:

Go to AWS Console → CloudWatch → Log groups → `/ecs/myapp-production`

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
| Secrets Manager | $0.50 |
| ECR storage (~500 MB) | $0.05 |
| S3 + DynamoDB (state) | $0.60 |
| **Total** | **~$70-75/month** |

**Ways to reduce costs:**
- Use a smaller Fargate task (0.25 vCPU / 0.5 GB is the minimum)
- Delete the NAT Gateway if you don't need outbound internet (~$32 saved)
- Use free tier RDS or external database providers

---

## Scaling When You're Ready

### Vertical scaling (bigger tasks):

Update `terraform.tfvars`:
```hcl
cpu    = 512
memory = 1024
```

Run `terraform apply`.

### Horizontal scaling (more tasks):

```hcl
desired_count = 3
```

Run `terraform apply`.

### Add auto-scaling:

Add this to `ecs.tf`:

```hcl
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "cpu-autoscaling"
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

---

## Adding HTTPS

Once you have a domain:

1. **Register domain** (Route53, Namecheap, etc.)

2. **Request SSL certificate** in ACM:
```bash
aws acm request-certificate \
  --domain-name myapp.com \
  --validation-method DNS
```

3. **Add DNS validation records** (ACM will tell you what to add)

4. **Update ALB listener** in `alb.tf`:

```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = "arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Redirect HTTP to HTTPS
resource "aws_lb_listener" "http_redirect" {
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

5. **Update security group** to allow 443:

```hcl
ingress {
  description = "HTTPS from internet"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

Run `terraform apply`.

---

## Why This Costs $1,000

### What you're really buying:

**40+ hours of infrastructure work** compressed into a 10-minute setup.

If you hired a DevOps engineer at $150/hour, this would cost **$6,000+**.

### What makes this valuable:

1. **Opinionated decisions made for you**
   - Single NAT Gateway (cost vs. HA trade-off)
   - 7-day log retention (not 30 days)
   - Fargate over EC2 (simplicity over cost optimization)
   - No auto-scaling by default (you don't need it yet)

2. **Battle-tested patterns**
   - Security groups that don't expose everything
   - IAM roles with actual least-privilege
   - Health checks that actually work
   - Logging that helps you debug

3. **No decision paralysis**
   - You don't need to spend 3 days researching whether to use ECS or EKS
   - You don't need to debate subnet sizing
   - You don't need to compare 17 different NAT Gateway architectures

4. **Zero-to-production in hours, not weeks**
   - Time saved: 2-3 weeks of full-time work
   - Focus regained: You're building features, not configuring route tables
   - Revenue gained: You're talking to customers sooner

### What you're NOT paying for:

- Enterprise features you don't need
- Compliance certifications
- Multi-region architectures
- 24/7 support
- Custom modifications

---

## What's Included

✅ Complete Terraform codebase (9 files, ~600 lines)
✅ VPC with public/private subnets across 2 AZs
✅ Application Load Balancer with health checks
✅ ECS Fargate cluster and service
✅ Security groups (least-privilege configured)
✅ IAM roles (no wildcard permissions)
✅ CloudWatch logging (7-day retention)
✅ Secrets Manager setup
✅ GitHub Actions CI/CD pipeline
✅ S3 remote state configuration
✅ Complete README with deployment guide

---

## What's NOT Included

❌ **HTTPS/SSL** – You need to add ACM certificate (10 minutes)
❌ **Database** – Use RDS, Supabase, or PlanetScale
❌ **Domain/DNS** – Register separately and point to ALB
❌ **Auto-scaling** – Fixed task count (easy to add later)
❌ **Multi-region** – Single region deployment
❌ **High availability** – Single NAT Gateway (cost trade-off)
❌ **WAF/DDoS protection** – Add when you have real traffic
❌ **Monitoring dashboards** – Basic CloudWatch only
❌ **Backups** – Set up database backups separately
❌ **Support** – No support included
❌ **Compliance** – No SOC2, HIPAA, PCI guarantees

---

## Known Limitations

### 1. Single NAT Gateway
- **Impact:** If the NAT Gateway fails, your tasks lose outbound internet access for ~5 minutes while AWS replaces it
- **Why:** Saves $32/month. For MVP traffic, this is acceptable
- **When to fix:** When uptime becomes critical (add 2nd NAT Gateway)

### 2. No Auto-Scaling
- **Impact:** Your app runs a fixed number of tasks regardless of load
- **Why:** Keeps costs predictable and configuration simple
- **When to fix:** When you see sustained high CPU or need burst capacity

### 3. HTTP Only (No HTTPS)
- **Impact:** Traffic is unencrypted, browsers show "Not Secure"
- **Why:** HTTPS requires a domain and SSL certificate setup
- **When to fix:** Before you go live with real users (add ACM certificate)

### 4. 7-Day Log Retention
- **Impact:** You can only search logs from the past week
- **Why:** Reduces CloudWatch costs (~$3/month vs ~$10-20/month)
- **When to fix:** When you need audit trails or longer debugging windows

### 5. Single Region
- **Impact:** If `us-east-1` has an outage, your app is down
- **Why:** Multi-region is complex and expensive
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

If you need enterprise support, hire a DevOps consultant.

---

## Who This Is For

### ✅ Great fit:
- Solo founders launching an MVP
- Freelancers building client apps
- Small teams (1-5 engineers)
- Non-technical founders with some AWS knowledge
- Developers who want to focus on product, not infrastructure
- Teams with budgets under $5k/month for infrastructure

### ❌ Not a fit:
- Enterprise companies with compliance requirements
- Banks, healthcare, or government projects
- Teams needing SOC2, HIPAA, or PCI certification
- Applications requiring 99.99%+ uptime SLAs
- Multi-tenant SaaS with complex isolation requirements
- Projects with >$50k/month infrastructure budgets

---

## License

All rights reserved. Licensed for single commercial use per purchase.

You may modify this code for your own projects. You may NOT resell, redistribute, or share this code with others.

---

## Final Thoughts

DevOps is a **time sink** for founders.

Every hour you spend configuring subnets is an hour you're not:
- Talking to customers
- Shipping features
- Iterating on your product
- Making revenue

This starter kit gives you those hours back.

It's not perfect. It's not enterprise-grade. It's not designed for banks.

But it's **good enough** to launch. And launching is what matters.

The best infrastructure is the infrastructure that gets out of your way so you can build your product.

**Ready to ship?** 🚀

---

**One final reminder:**

After you deploy, immediately do these three things:

1. **Set up billing alerts** in AWS Console (set at $100/month)
2. **Update the placeholder secrets** in Secrets Manager
3. **Add your domain and HTTPS certificate** before going live

Then get back to building your product.
