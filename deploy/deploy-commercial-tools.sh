# ============================================================
# Author: TGibson
# File: deploy/deploy-commercial-tools.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# NOTE: GovCloud-safe scaling = EKS Managed Node Groups + AWS Batch on EKS (no OSS autoscalers)
#!/usr/bin/env bash
# ============================================================
# Author: TGibson
# File: deploy/deploy-commercial-tools.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 2.1
# Date: 2025-08-27
# ============================================================
set -euo pipefail
aws cloudformation deploy   --stack-name eks-cicd-tools-comm   --template-file templates/tools-pipeline.yaml   --parameter-overrides file://params/tools-commercial.json   --capabilities CAPABILITY_NAMED_IAM
aws cloudformation describe-stacks --stack-name eks-cicd-tools-comm --query "Stacks[0].Outputs"
