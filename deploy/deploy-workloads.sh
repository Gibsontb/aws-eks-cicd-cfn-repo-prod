# ============================================================
# Author: TGibson
# File: deploy/deploy-workloads.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# NOTE: GovCloud-safe scaling = EKS Managed Node Groups + AWS Batch on EKS (no OSS autoscalers)
#!/usr/bin/env bash
# ============================================================
# Author: TGibson
# File: deploy/deploy-workloads.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 2.1
# Date: 2025-08-27
# ============================================================
set -euo pipefail
for ENV in dev stg prod; do
  aws cloudformation deploy     --stack-name eks-deploy-iam-$ENV-comm     --template-file templates/workload-deploy-iam.yaml     --parameter-overrides file://params/workload-$ENV-commercial.json     --capabilities CAPABILITY_NAMED_IAM
done

REGION_GOV=${1:-us-gov-west-1}
for ENV in dev stg prod; do
  aws --region "$REGION_GOV" cloudformation deploy     --stack-name eks-deploy-iam-$ENV-gov     --template-file templates/workload-deploy-iam.yaml     --parameter-overrides file://params/workload-$ENV-govcloud.json     --capabilities CAPABILITY_NAMED_IAM
done

echo "Map each created deploy role into each cluster's aws-auth."
