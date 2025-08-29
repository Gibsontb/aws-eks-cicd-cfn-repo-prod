# ============================================================
# Author: TGibson
# File: deploy/apply-kyverno.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# NOTE: GovCloud-safe scaling = EKS Managed Node Groups + AWS Batch on EKS (no OSS autoscalers)
#!/usr/bin/env bash
# ============================================================
# Author: TGibson
# File: deploy/apply-kyverno.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.2
# Date: 2025-08-27
# ============================================================
set -euo pipefail
kubectl apply -f ops/policies/kyverno-verifyimages.yaml
kubectl apply -f ops/policies/kyverno-podsecurity.yaml
echo "Kyverno policies applied."
