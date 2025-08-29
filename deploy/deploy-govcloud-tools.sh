# ============================================================
# Author: TGibson
# File: deploy/deploy-govcloud-tools.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# NOTE: GovCloud-safe scaling = EKS Managed Node Groups + AWS Batch on EKS (no OSS autoscalers)
#!/usr/bin/env bash
# ============================================================
# Author: TGibson
# File: deploy/deploy-govcloud-tools.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 2.1
# Date: 2025-08-27
# ============================================================
set -euo pipefail
REGION_GOV=${1:-us-gov-west-1}

aws --region "$REGION_GOV" cloudformation deploy   --stack-name mirror-receiver   --template-file templates/gov-mirror-receiver.yaml   --parameter-overrides file://params/gov-mirror-receiver.json   --capabilities CAPABILITY_NAMED_IAM

aws --region "$REGION_GOV" cloudformation deploy   --stack-name eks-cicd-tools-gov   --template-file templates/tools-pipeline.yaml   --parameter-overrides file://params/tools-govcloud.json   --capabilities CAPABILITY_NAMED_IAM

aws --region "$REGION_GOV" cloudformation describe-stacks --stack-name eks-cicd-tools-gov --query "Stacks[0].Outputs"
