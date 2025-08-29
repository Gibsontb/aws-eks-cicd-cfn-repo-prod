# ============================================================
# Author: TGibson
# File: deploy/fetch-cosign-pubkey.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# NOTE: GovCloud-safe scaling = EKS Managed Node Groups + AWS Batch on EKS (no OSS autoscalers)
#!/usr/bin/env bash
# ============================================================
# Author: TGibson
# File: deploy/fetch-cosign-pubkey.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
set -euo pipefail
KEY="${1:-alias/myservice-cosign}"
REGION="${2:-${AWS_REGION:-}}"
if [ -z "$REGION" ]; then REGION="${AWS_DEFAULT_REGION:-us-east-1}"; fi
mkdir -p security
PUB_B64=$(aws kms get-public-key --key-id "$KEY" --region "$REGION" --query PublicKey --output text)
{
  echo "-----BEGIN PUBLIC KEY-----"
  echo "$PUB_B64" | fold -w 64
  echo "-----END PUBLIC KEY-----"
} > security/cosign_pubkey.pem
echo "Wrote security/cosign_pubkey.pem"
