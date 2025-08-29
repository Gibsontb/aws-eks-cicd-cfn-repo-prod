#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${1:-zt-eks}"
AWS_REGION="${2:-us-east-1}"
CHART_VERSION="${3:-v0.37.0}"

echo "[*] Installing Karpenter ${CHART_VERSION} into cluster ${CLUSTER_NAME} (${AWS_REGION})"

# Prereqs: kubectl, helm, aws, eksctl configured; OIDC/IAM roles created per templates

kubectl create namespace karpenter --dry-run=client -o yaml | kubectl apply -f -

helm repo add karpenter https://charts.karpenter.sh/
helm repo update

helm upgrade --install karpenter karpenter/karpenter \
  --namespace karpenter \
  --version "${CHART_VERSION}" \
  --set serviceAccount.annotations."eks\\.amazonaws\\.com/role-arn"="${KARPENTER_CONTROLLER_ROLE_ARN}" \
  --set settings.clusterName="${CLUSTER_NAME}" \
  --set settings.interruptionQueue="${CLUSTER_NAME}" \
  --set controller.resources.requests.cpu=200m

cat <<'EOF' | kubectl apply -f -
apiVersion: karpenter.sh/v1beta1
kind: NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2
  role: karpenter-node-role
  subnetSelector:
    karpenter.sh/discovery: ${CLUSTER_NAME}
  securityGroupSelector:
    karpenter.sh/discovery: ${CLUSTER_NAME}
EOF

cat <<'EOF' | kubectl apply -f -
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      nodeClassRef:
        name: default
      requirements:
        - key: "node.kubernetes.io/instance-type"
          operator: In
          values: ["m6i.large","m6a.large","m7i.large"]
  disruption:
    consolidationPolicy: WhenUnderutilized
    consolidateAfter: 30s
EOF

echo "[✓] Karpenter installed with default NodeClass/NodePool."
