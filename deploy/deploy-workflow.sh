# ============================================================
# Author: TGibson
# File: deploy/deploy-workflow.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# NOTE: GovCloud-safe scaling = EKS Managed Node Groups + AWS Batch on EKS (no OSS autoscalers)
#!/usr/bin/env bash
set -euo pipefail
APP_NAME="${1:-zt}"
STACK_NAME="${APP_NAME}-workflow"
REGION="${2:-us-east-1}"

echo "[*] Building SAM app..."
sam build -t templates/sam-scoring-workflow.yaml

echo "[*] Deploying SAM app..."
sam deploy \
  --stack-name "${STACK_NAME}" \
  --resolve-s3 \
  --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
  --parameter-overrides AppName="${APP_NAME}" \
  --region "${REGION}"
