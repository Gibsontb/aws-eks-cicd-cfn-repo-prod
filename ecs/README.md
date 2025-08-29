# ============================================================
# Author: TGibson
# File: ecs/README.md
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# ECS (Fargate) Alternative — No OSS Controllers

This stack replaces Kubernetes controllers with **fully managed AWS services**:
- **ECS on Fargate** (no cluster autoscaler, no node management)
- **ALB** directly managed by ECS
- **CloudFront + WAF** in front (re-use CloudFront/WAF templates)
- **Service Auto Scaling** via target tracking (CPU/Mem) or custom metrics

Use `ecs/templates/ecs-fargate-core.yaml` to stand up the cluster and a service.
