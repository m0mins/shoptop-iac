# Shoptop IaC

Terraform infrastructure-as-code for the Shoptop project, deployed on AWS in the `ap-southeast-1` (Singapore) region.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Stacks](#stacks)
  - [tf-backend](#1-tf-backend)
  - [shared](#2-shared)
  - [root (main)](#3-root-main)
- [Getting Started](#getting-started)
- [Environments](#environments)
- [Variables Reference](#variables-reference)
- [Outputs](#outputs)
- [Naming Convention](#naming-convention)
- [Important Notes](#important-notes)

---

## Overview

This repository manages the cloud infrastructure for Shoptop using Terraform. It provisions:

- A VPC with public/private subnets across multiple availability zones
- A CloudFront-backed S3 frontend for a Single Page Application (SPA)
- An S3 static content bucket with CORS support
- ACM SSL/TLS certificates (us-east-1 for CloudFront compatibility)
- Shared resources (certificates, DNS) used across environments
- Remote Terraform state stored in S3

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Route 53 (DNS)                   │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              CloudFront Distribution                │
│         (PriceClass_100, SNI, TLSv1.2_2021)        │
└──────────────────────┬──────────────────────────────┘
                       │ OAI
┌──────────────────────▼──────────────────────────────┐
│            S3 Frontend Bucket (private)             │
│     SPA hosting — index.html / error.html           │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│           S3 Static Content Bucket                  │
│      CORS enabled — GET/PUT from any origin         │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                  VPC (10.0.0.0/16)                  │
│   3× public subnets — ap-southeast-1a/b/c           │
└─────────────────────────────────────────────────────┘
```

**Multi-stack state separation:**

| Stack       | State key                       | Purpose                              |
|-------------|----------------------------------|--------------------------------------|
| `tf-backend`| *(local — bootstraps state)*     | Creates the S3 state bucket          |
| `shared`    | `terraform.shared.tfstate`       | Shared ACM certs, DNS zones          |
| root (main) | `terraform.tfstate`              | VPC, CloudFront, S3, app resources   |

---

## Prerequisites

| Tool           | Version        |
|----------------|---------------|
| Terraform      | `>=1.1, <=2.0` |
| AWS CLI        | v2+            |
| AWS credentials| configured     |

Ensure your AWS credentials have sufficient permissions to create IAM policies, S3, CloudFront, ACM, VPC, and Route53 resources.

---

## Repository Structure

```
shoptop-iac/
├── tf-backend/             # Bootstrap — creates the S3 state bucket
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── terraform.tfvars
│
├── shared/                 # Shared resources (certs, DNS)
│   ├── main.tf
│   ├── cloudfront-certs.tf
│   ├── route53.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   ├── versions.tf
│   └── terraform.tfvars
│
├── main.tf                 # Label/context module
├── frontend.tf             # S3 + CloudFront frontend
├── static-content-bucket.tf
├── vpc.tf                  # VPC + subnets
├── acm.tf                  # ACM (backend cert, commented out)
├── variables.tf
├── outputs.tf
├── backend.tf
├── versions.tf
└── config.dev.tfvars       # Dev environment variable values
```

---

## Stacks

### 1. tf-backend

> Run this **once** before any other stack. It creates the S3 bucket that stores Terraform state for all other stacks.

```bash
cd tf-backend
terraform init
terraform apply
```

After apply, note the output `bucket` name and ensure it matches the `bucket` value in `backend.tf` files in the root and `shared/` directories.

**Key resource:** `aws_s3_bucket.s3_backend` with versioning enabled.

---

### 2. shared

> Run this **before the root stack**. It provisions shared resources such as the ACM certificate used by CloudFront.

```bash
cd shared
terraform init
terraform apply -var-file="terraform.tfvars"
```

Note the output `acm_cert_frontend_arn` and pass it as `acm_cert_frontend_arn` in your environment tfvars for the root stack.

**Key resources:**
- ACM certificate in `us-east-1` (required for CloudFront) via `cloudposse/acm-request-certificate/aws`

---

### 3. root (main)

> The main application infrastructure stack.

```bash
# Initialize
terraform init

# Plan for dev environment
terraform plan -var-file="config.dev.tfvars"

# Apply for dev environment
terraform apply -var-file="config.dev.tfvars"
```

**Key resources:**
- VPC (`10.0.0.0/16`) with dynamic subnets across 3 AZs
- S3 frontend bucket (private) + CloudFront distribution
- CloudFront Origin Access Identity (OAI)
- S3 static content bucket with CORS
- CloudPosse label module for consistent naming/tagging

---

## Environments

Currently one environment config is present:

| Environment | Config file          | Domain                   | AWS Region       |
|-------------|----------------------|--------------------------|-----------------|
| `dev`       | `config.dev.tfvars`  | `demo.strativ-support.se`| `ap-southeast-1` |
| `prod`      | *(to be created)*    | `strativ-support.se`     | `ap-southeast-1` |

Domain aliases are workspace-dependent in `frontend.tf`:
- Terraform workspace `default` (prod) → `strativ-support.se`
- Any other workspace (dev) → `demo.strativ-support.se`

To create and use a named workspace:

```bash
terraform workspace new dev
terraform workspace select dev
terraform apply -var-file="config.dev.tfvars"
```

---

## Variables Reference

### Root stack (`variables.tf`)

| Variable                 | Type         | Description                                       |
|--------------------------|--------------|---------------------------------------------------|
| `region`                 | `string`     | AWS region to deploy into                         |
| `stage`                  | `string`     | Deployment stage (`dev`, `prod`)                  |
| `project_namespace`      | `string`     | Project identifier used in resource naming        |
| `availability_zones`     | `list(string)` | List of AZs for subnet creation                 |
| `zone_id`                | `string`     | Route53 hosted zone ID (backend domain)           |
| `zone_id_frontend`       | `string`     | Route53 hosted zone ID (frontend domain)          |
| `aws_account_id`         | `string`     | AWS account ID                                    |
| `acm_cert_frontend_arn`  | `string`     | ACM certificate ARN for the CloudFront distribution (must be in us-east-1) |
| `cluster_domain`         | `string`     | Base domain for the cluster                       |

### shared stack (`shared/variables.tf`)

| Variable             | Type     | Description                      |
|----------------------|----------|----------------------------------|
| `project_namespace`  | `string` | Project identifier               |
| `domain`             | `string` | Primary domain name              |

### tf-backend stack (`tf-backend/variables.tf`)

| Variable       | Type     | Description              |
|----------------|----------|--------------------------|
| `project_name` | `string` | Used to name the S3 bucket |

---

## Outputs

### Root stack

| Output                      | Description                              |
|-----------------------------|------------------------------------------|
| `static_content_bucket_name`| Name of the static content S3 bucket    |

### shared stack

| Output                  | Description                                          |
|-------------------------|------------------------------------------------------|
| `acm_cert_frontend_arn` | ARN of the ACM certificate for CloudFront (us-east-1)|

### tf-backend stack

| Output   | Description                          |
|----------|--------------------------------------|
| `bucket` | Name of the created S3 state bucket  |

---

## Naming Convention

All resources use [CloudPosse's `null-label`](https://github.com/cloudposse/terraform-null-label) module to produce consistent names:

```
{namespace}-{stage}-{name}-{random_suffix}
# e.g. shoptop-dev-frontend-apt-bear
```

Tags are applied automatically from the label context.

---

## Important Notes

- **ACM certificates for CloudFront must be in `us-east-1`**, regardless of where the rest of the infrastructure lives. The `shared/` stack uses an aliased AWS provider (`aws.virginia`) for this purpose.
- **Deploy order matters:** `tf-backend` → `shared` → root. The root stack reads the ACM cert ARN from `config.*.tfvars`, which you must populate from the `shared` stack output.
- **SPA error handling:** The CloudFront distribution returns the root `index.html` with HTTP 200 for 403 errors, enabling client-side routing.
- **NAT Gateway is disabled** in the VPC module — workloads requiring outbound internet access from private subnets will need it enabled or an alternative approach.
- **Route53 zone IDs** (`zone_id`, `zone_id_frontend`) are not yet set in `config.dev.tfvars` and must be filled in when DNS records are needed.
- The `acm.tf` backend certificate is currently **commented out** and not active.
- The S3 state bucket name (`shoptop-tf-backend-shrew`) includes a random pet suffix generated during `tf-backend` apply. Update `backend.tf` files if you recreate the backend bucket.
