# ============================================================
# Author: TGibson
# File: ops/tenant/tenant-onboard.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
#!/usr/bin/env bash
set -euo pipefail
if ! command -v jq >/dev/null; then
  echo "jq is required"; exit 1
fi
CFG="${1:?usage: tenant-onboard.sh config/tenants/<tenant>.json}"

TENANT=$(jq -r .tenant "$CFG")
NS=$(jq -r .namespace "$CFG")

echo "[*] Creating namespace: $NS"
kubectl create ns "$NS" --dry-run=client -o yaml | kubectl apply -f -

echo "[*] Applying resource quota"
cat ops/k8s/tenant-resourcequota.yaml | sed "s/{{NAMESPACE}}/$NS/g" | kubectl apply -n "$NS" -f -

echo "[*] Applying network policy"
cat ops/k8s/tenant-networkpolicy.yaml | sed "s/{{NAMESPACE}}/$NS/g" | kubectl apply -n "$NS" -f -

echo "[*] Applying limit ranges"
cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
spec:
  limits:
    - type: Container
      default:
        cpu: 500m
        memory: 512Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
EOF

echo "[✓] Tenant $TENANT onboarded to namespace $NS"
