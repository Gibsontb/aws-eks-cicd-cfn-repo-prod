# ============================================================
# Author: TGibson
# File: deploy/deploy-addons-prod.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# NOTE: GovCloud-safe scaling = EKS Managed Node Groups + AWS Batch on EKS (no OSS autoscalers)
#!/usr/bin/env bash
set -euo pipefail

# Required env vars: CLUSTER_NAME, AWS_REGION, PRIMARY_DOMAIN, VPC_ID, VELERO_BUCKET, ENV_NAME
: "${CLUSTER_NAME:?Set CLUSTER_NAME}"
: "${AWS_REGION:?Set AWS_REGION}"
: "${PRIMARY_DOMAIN:?Set PRIMARY_DOMAIN}"
: "${VPC_ID:?Set VPC_ID}"
: "${VELERO_BUCKET:?Set VELERO_BUCKET}"
: "${ENV_NAME:?Set ENV_NAME}"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

# Populate Helm values with env vars
envsubst < ops/addons/aws-load-balancer-controller/values.yaml > /tmp/alb-values.yaml
envsubst < ops/addons/external-dns/values.yaml > /tmp/external-dns-values.yaml
envsubst < ops/addons/velero/values.yaml > /tmp/velero-values.yaml
envsubst < ops/addons/external-secrets/values.yaml > /tmp/es-values.yaml

echo "[*] Ensuring namespaces"
kubectl get ns kube-system >/dev/null

echo "[*] Add Helm repos"
helm repo add eks https://aws.github.io/eks-charts >/dev/null
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/ >/dev/null
helm repo add velero https://vmware-tanzu.github.io/helm-charts >/dev/null
helm repo add external-secrets https://charts.external-secrets.io >/dev/null
helm repo update >/dev/null

echo "[*] Deploy AWS Load Balancer Controller"
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller   -n kube-system -f /tmp/alb-values.yaml

echo "[*] Deploy ExternalDNS"
helm upgrade --install external-dns external-dns/external-dns   -n kube-system -f /tmp/external-dns-values.yaml

echo "[*] Deploy Cluster Autoscaler"

echo "[*] Deploy External Secrets Operator"
helm upgrade --install external-secrets external-secrets/external-secrets   -n kube-system -f /tmp/es-values.yaml

echo "[*] Deploy Velero"
helm upgrade --install velero velero/velero   -n kube-system -f /tmp/velero-values.yaml

echo "[✓] Core production add-ons deployed"
