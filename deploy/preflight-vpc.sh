# ============================================================
# Author: TGibson
# File: deploy/preflight-vpc.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# NOTE: GovCloud-safe scaling = EKS Managed Node Groups + AWS Batch on EKS (no OSS autoscalers)
#!/usr/bin/env bash
# ============================================================
# Author: TGibson
# File: deploy/preflight-vpc.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.0
# Date: 2025-08-27
# ============================================================
set -euo pipefail

# Usage:
#   deploy/preflight-vpc.sh <region> <vpc-id> "<subnet-a,subnet-b>" <codebuild-sg-id>
#
# Validates that required VPC endpoints exist (or warns) for VPC-only CodeBuild.
#
REGION="${1:?region required}"
VPC_ID="${2:?vpc id required}"
SUBNETS_CSV="${3:?comma-separated private subnet ids required}"
CB_SG="${4:?codebuild sg id required}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "[ERR] missing $1" >&2; exit 1; }; }
need aws
need jq

echo "[..] Checking VPC endpoints in $REGION for $VPC_ID"
services=( ecr.api ecr.dkr logs sts kms codecommit codebuild events ec2 eks )
missing=()

for svc in "${services[@]}"; do
  # Gateway endpoint for S3
  if [[ "$svc" == "s3" ]]; then
    continue
  fi
  vpce="com.amazonaws.${REGION}.${svc}"
  found=$(aws ec2 describe-vpc-endpoints --region "$REGION" \
      --filters "Name=vpc-id,Values=$VPC_ID" "Name=service-name,Values=$vpce" \
      --query 'VpcEndpoints[?State==`available`].VpcEndpointId' --output text || true)
  if [[ -z "$found" ]]; then
    missing+=("$vpce")
  fi
done

# S3 (gateway)
s3gw=$(aws ec2 describe-vpc-endpoints --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=service-name,Values=com.amazonaws.${REGION}.s3" \
    --query 'VpcEndpoints[?State==`available`].VpcEndpointId' --output text || true)
if [[ -z "$s3gw" ]]; then
  missing+=("com.amazonaws.${REGION}.s3 (gateway endpoint)")
fi

if (( ${#missing[@]} > 0 )); then
  echo "[WARN] Missing recommended endpoints:"
  for m in "${missing[@]}"; do echo "  - $m"; done
  echo "       Either create these endpoints or allow NAT egress for CodeBuild to reach AWS services."
else
  echo "[OK] All recommended endpoints present."
fi

# Basic SG and subnets existence checks
for sn in ${SUBNETS_CSV//,/ }; do
  aws ec2 describe-subnets --region "$REGION" --subnet-ids "$sn" >/dev/null || { echo "[ERR] subnet not found: $sn"; exit 1; }
done
aws ec2 describe-security-groups --region "$REGION" --group-ids "$CB_SG" >/dev/null || { echo "[ERR] SG not found: $CB_SG"; exit 1; }

echo "[OK] Preflight completed."
