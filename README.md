# vpro-infra

Terraform infrastructure for provisioning an Amazon EKS cluster on AWS, with GitOps delivery via ArgoCD and a GitHub Actions CI/CD pipeline.

## Architecture

- VPC with 2 public and 2 private subnets across 2 availability zones (`us-east-1a`, `us-east-1b`)
- Internet Gateway + NAT Gateway for outbound traffic from private subnets
- EKS cluster with managed node group in private subnets
- EBS CSI Driver addon with IRSA (IAM Roles for Service Accounts) via OIDC
- Remote state stored in S3 (`vpro-terra-state`) with DynamoDB locking (`vpro-lock`)

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- AWS CLI configured with appropriate permissions
- S3 bucket `vpro-terra-state` and DynamoDB table `vpro-lock` already created

## Usage

```bash
terraform init
terraform plan
terraform apply
```

To trigger a manual apply via GitHub Actions, dispatch the workflow and type `APPLY` in the `apply_now` input.

## Variables

| Name | Description | Default |
|---|---|---|
| `region` | AWS region | `us-east-1` |
| `cluster_name` | EKS cluster name | `vpro-eks-cluster` |
| `kubernetes_version` | Kubernetes version | `1.33` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `node_instance_type` | Worker node instance type | `t3.small` |
| `node_min_size` | Min worker nodes | `3` |
| `node_max_size` | Max worker nodes | `4` |
| `node_desired_size` | Desired worker nodes | `3` |

## Outputs

| Name | Description |
|---|---|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | Kubernetes API server endpoint |
| `cluster_arn` | EKS cluster ARN |

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/terraform-main.yml`) runs:

- **On PR / push to main:** `terraform fmt`, `validate`, and `plan`
- **On schedule (every 6h):** drift detection with Slack notification
- **On manual dispatch with `APPLY`:** `terraform apply` against the `production` environment

Requires the following GitHub repository variables:
- `AWS_ROLE_TO_ASSUME` — IAM role ARN for OIDC authentication
- `AWS_REGION` — AWS region
- `SLACK_WEBHOOK_URL` — Slack webhook for drift notifications

## ArgoCD

The `argocd/` directory contains:
- `argocd-ingress.yml` — Ingress resource for the ArgoCD UI
- `vpro-project.yml` — ArgoCD AppProject definition
- `vpro-app.yaml` — ArgoCD Application manifest
