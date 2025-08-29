# ============================================================
# Author: TGibson
# File: deploy/bootstrap-fill-and-deploy.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# NOTE: GovCloud-safe scaling = EKS Managed Node Groups + AWS Batch on EKS (no OSS autoscalers)
#!/usr/bin/env bash
# ============================================================
# Author: TGibson
# File: deploy/bootstrap-fill-and-deploy.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 2.1
# Date: 2025-08-27
# ============================================================
set -euo pipefail

# ---------- Helpers ----------
die() { echo "[ERR] $*" >&2; exit 1; }
ok()  { echo "[OK]  $*"; }
inf() { echo "[..]  $*"; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing required binary: $1"; }

usage() {
  cat <<'EOF'
Usage:
  deploy/bootstrap-fill-and-deploy.sh [--config deploy/bootstrap.conf] [--non-interactive] [--skip-gov] [--apply-kyverno]

What this does:
  1) Loads configuration from a single file.
  2) Writes params/*.json for CFN.
  3) AUTO-INJECTS prod ingress/DNS/TLS + identity into Helm (values-prod.yaml).
  4) AUTO-UPDATES tenant defaults (values-tenant-template.yaml).
  5) Deploys Commercial (and optional GovCloud) stacks in order.
  6) Optionally applies Kyverno and sets up pipeline notifications.

Flags:
  --config FILE       Config path (default: deploy/bootstrap.conf)
  --non-interactive   No prompts; require values in config/env
  --skip-gov          Skip GovCloud even if GOV_* present
  --apply-kyverno     Apply Kyverno policies after stacks
EOF
}

CONFIG_PATH="deploy/bootstrap.conf"
NON_INTERACTIVE=0
SKIP_GOV=0
APPLY_KYVERNO=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) CONFIG_PATH="$2"; shift 2;;
    --non-interactive) NON_INTERACTIVE=1; shift;;
    --skip-gov) SKIP_GOV=1; shift;;
    --apply-kyverno) APPLY_KYVERNO=1; shift;;
    -h|--help) usage; exit 0;;
    *) die "Unknown arg: $1 (use --help)";;
  esac
done

# ---------- Require tools & repo root ----------
need aws
need jq
[ -f "templates/tools-pipeline.yaml" ] || die "Run from repo root (templates/tools-pipeline.yaml not found)."

# ---------- Load config ----------
[ -f "$CONFIG_PATH" ] || die "Config file not found: $CONFIG_PATH"
# shellcheck disable=SC1090
source "$CONFIG_PATH"
ok "Loaded config from $CONFIG_PATH"

# ---------- Validate required Commercial inputs ----------
req() { local n="$1"; [[ -n "${!n:-}" ]] || die "Missing required config/env: $n"; }

req APP_NAME
req REPO_NAME
req ECR_REPO_NAME
SOURCE_BRANCH="${SOURCE_BRANCH:-main}"

req COMM_ACCOUNT_ID
req COMM_REGION
req COMM_VPC_ID
req COMM_PRIVATE_SUBNET_IDS
req COMM_CODEBUILD_SG_ID
req COSIGN_KMS_ALIAS

# Optional GovCloud
if [[ ${SKIP_GOV} -eq 0 && -n "${GOV_ACCOUNT_ID:-}" ]]; then
  req GOV_REGION
  req GOV_VPC_ID
  req GOV_PRIVATE_SUBNET_IDS
  req GOV_CODEBUILD_SG_ID
else
  SKIP_GOV=1
fi

# Cluster & namespaces
DEV_CLUSTER_NAME="${DEV_CLUSTER_NAME:-eks-dev}"
STG_CLUSTER_NAME="${STG_CLUSTER_NAME:-eks-stg}"
PRD_CLUSTER_NAME="${PRD_CLUSTER_NAME:-eks-prod}"
DEV_NAMESPACE="${DEV_NAMESPACE:-app-dev}"
STG_NAMESPACE="${STG_NAMESPACE:-app-stg}"
PRD_NAMESPACE="${PRD_NAMESPACE:-app-prod}"

# ---------- 1) Write params/*.json ----------
mkdir -p params

cat > params/tools-commercial.json <<JSON
[
  {"ParameterKey":"AppName","ParameterValue":"${APP_NAME}"},
  {"ParameterKey":"RepoName","ParameterValue":"${REPO_NAME}"},
  {"ParameterKey":"EcrRepoName","ParameterValue":"${ECR_REPO_NAME}"},
  {"ParameterKey":"IsCommercial","ParameterValue":"true"},
  {"ParameterKey":"GovAccountId","ParameterValue":"${GOV_ACCOUNT_ID:-}"},
  {"ParameterKey":"CosignKmsKeyAlias","ParameterValue":"${COSIGN_KMS_ALIAS}"},
  {"ParameterKey":"DevClusterName","ParameterValue":"${DEV_CLUSTER_NAME}"},
  {"ParameterKey":"StgClusterName","ParameterValue":"${STG_CLUSTER_NAME}"},
  {"ParameterKey":"ProdClusterName","ParameterValue":"${PRD_CLUSTER_NAME}"},
  {"ParameterKey":"DevNamespace","ParameterValue":"${DEV_NAMESPACE}"},
  {"ParameterKey":"StgNamespace","ParameterValue":"${STG_NAMESPACE}"},
  {"ParameterKey":"ProdNamespace","ParameterValue":"${PRD_NAMESPACE}"},
  {"ParameterKey":"VpcId","ParameterValue":"${COMM_VPC_ID}"},
  {"ParameterKey":"PrivateSubnetIds","ParameterValue":"${COMM_PRIVATE_SUBNET_IDS}"},
  {"ParameterKey":"CodeBuildSecurityGroupId","ParameterValue":"${COMM_CODEBUILD_SG_ID}"}
]
JSON

if [[ $SKIP_GOV -eq 0 ]]; then
  cat > params/tools-govcloud.json <<JSON
[
  {"ParameterKey":"AppName","ParameterValue":"${APP_NAME}"},
  {"ParameterKey":"RepoName","ParameterValue":"${REPO_NAME}"},
  {"ParameterKey":"EcrRepoName","ParameterValue":"${ECR_REPO_NAME}"},
  {"ParameterKey":"IsCommercial","ParameterValue":"false"},
  {"ParameterKey":"GovAccountId","ParameterValue":"${GOV_ACCOUNT_ID}"},
  {"ParameterKey":"CosignKmsKeyAlias","ParameterValue":"${COSIGN_KMS_ALIAS}"},
  {"ParameterKey":"DevClusterName","ParameterValue":"${DEV_CLUSTER_NAME}"},
  {"ParameterKey":"StgClusterName","ParameterValue":"${STG_CLUSTER_NAME}"},
  {"ParameterKey":"ProdClusterName","ParameterValue":"${PRD_CLUSTER_NAME}"},
  {"ParameterKey":"DevNamespace","ParameterValue":"${DEV_NAMESPACE}"},
  {"ParameterKey":"StgNamespace","ParameterValue":"${STG_NAMESPACE}"},
  {"ParameterKey":"ProdNamespace","ParameterValue":"${PRD_NAMESPACE}"},
  {"ParameterKey":"VpcId","ParameterValue":"${GOV_VPC_ID}"},
  {"ParameterKey":"PrivateSubnetIds","ParameterValue":"${GOV_PRIVATE_SUBNET_IDS}"},
  {"ParameterKey":"CodeBuildSecurityGroupId","ParameterValue":"${GOV_CODEBUILD_SG_ID}"}
]
JSON

  cat > params/gov-mirror-receiver.json <<JSON
[
  {"ParameterKey":"CommercialToolsAccountId","ParameterValue":"${COMM_ACCOUNT_ID}"},
  {"ParameterKey":"GovRepoName","ParameterValue":"${REPO_NAME}"}
]
JSON
fi

for env in dev stg prod; do
  cat > "params/workload-${env}-commercial.json" <<JSON
[
  {"ParameterKey":"ToolsAccountId","ParameterValue":"${COMM_ACCOUNT_ID}"},
  {"ParameterKey":"EnvName","ParameterValue":"${env}"}
]
JSON
  if [[ $SKIP_GOV -eq 0 ]]; then
    cat > "params/workload-${env}-govcloud.json" <<JSON
[
  {"ParameterKey":"ToolsAccountId","ParameterValue":"${GOV_ACCOUNT_ID}"},
  {"ParameterKey":"EnvName","ParameterValue":"${env}"}
]
JSON
  fi
done
ok "Parameter files generated."

# ---------- 2) AUTO-INJECT: Helm values for PROD (ingress/DNS/TLS/WAF + identity) ----------
mkdir -p ops/helm
cat > ops/helm/values-prod.yaml <<YAML
# ============================================================
# Author: TGibson
# File: ops/helm/values-prod.yaml
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: $(date +%F)
# ============================================================
replicaCount: 4

image:
  repository: 111111111111.dkr.ecr.${COMM_REGION}.amazonaws.com/${ECR_REPO_NAME}
  tag: "use-deploy-stage-tag"        # buildspec-deploy will overwrite via --set
  pullPolicy: IfNotPresent

ingress:
  enabled: ${PROD_DOMAIN:+true}${PROD_DOMAIN:+" # auto: domain provided"}${PROD_DOMAIN:=""}
  className: alb
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    ${PROD_CERT_ARN:+alb.ingress.kubernetes.io/certificate-arn: ${PROD_CERT_ARN}}
    ${PROD_WAF_ARN:+alb.ingress.kubernetes.io/waf-acl-arn: ${PROD_WAF_ARN}}
  hosts:
    - host: ${PROD_DOMAIN:-example.com}
      paths:
        - path: /
          pathType: Prefix
  tls: []  # TLS is terminated at ALB via certificate-arn

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

resources:
  requests: { cpu: "250m", memory: "256Mi" }
  limits:   { cpu: "1000m", memory: "1024Mi" }

# Optional identity settings exposed to the app
env:
  ${COGNITO_USER_POOL_ID:+- name: COGNITO_USER_POOL_ID
    value: "${COGNITO_USER_POOL_ID}"}
  ${COGNITO_USER_POOL_CLIENT_ID:+- name: COGNITO_CLIENT_ID
    value: "${COGNITO_USER_POOL_CLIENT_ID}"}
  ${COGNITO_ISSUER_URL:+- name: OIDC_ISSUER
    value: "${COGNITO_ISSUER_URL}"}
  ${OIDC_ISSUER_URL:+- name: OIDC_ISSUER
    value: "${OIDC_ISSUER_URL}"}
  ${OIDC_AUDIENCE:+- name: OIDC_AUDIENCE
    value: "${OIDC_AUDIENCE}"}
  ${OIDC_JWKS_URI:+- name: OIDC_JWKS_URI
    value: "${OIDC_JWKS_URI}"}
YAML
ok "Wrote ops/helm/values-prod.yaml (ingress/identity auto-injected)."

# ---------- 3) AUTO-INJECT: Tenant defaults template ----------
mkdir -p ops/tenant
cat > ops/tenant/values-tenant-template.yaml <<YAML
# ============================================================
# Author: TGibson
# File: ops/tenant/values-tenant-template.yaml
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: $(date +%F)
# ============================================================
tenant:
  id: REPLACE_AT_RUNTIME
  domain: REPLACE_AT_RUNTIME

image:
  repository: 111111111111.dkr.ecr.${COMM_REGION}.amazonaws.com/${ECR_REPO_NAME}
  tag: "use-deploy-stage-tag"
  pullPolicy: IfNotPresent

ingress:
  enabled: true
  className: alb
  hosts:
    - host: REPLACE_AT_RUNTIME
      paths:
        - path: /
          pathType: Prefix

resources:
  requests: { cpu: "${TENANT_CPU_REQUEST:-100m}", memory: "${TENANT_MEM_REQUEST:-128Mi}" }
  limits:   { cpu: "${TENANT_CPU_LIMIT:-500m}",  memory: "${TENANT_MEM_LIMIT:-512Mi}" }

env:
  - name: TENANT_ID
    value: REPLACE_AT_RUNTIME
YAML
ok "Wrote ops/tenant/values-tenant-template.yaml (tenant defaults injected)."

# ---------- 4) Deploy stacks ----------
chmod +x deploy/deploy-commercial-tools.sh deploy/deploy-workloads.sh || true
inf "Deploying Commercial tools pipeline…"
./deploy/deploy-commercial-tools.sh

if [[ $SKIP_GOV -eq 0 ]]; then
  chmod +x deploy/deploy-govcloud-tools.sh || true
  inf "Deploying GovCloud tools + mirror receiver…"
  ./deploy/deploy-govcloud-tools.sh "${GOV_REGION}"
fi

inf "Deploying workload IAM roles (commercial + gov if enabled)…"
./deploy/deploy-workloads.sh "${GOV_REGION:-us-gov-west-1}"

# ---------- 5) Notifications (optional) ----------
if [[ -n "${NOTIFY_EMAIL:-}" ]]; then
  inf "Deploying pipeline notifications to ${NOTIFY_EMAIL}…"
  aws cloudformation deploy \
    --stack-name pipeline-notify \
    --template-file templates/pipeline-notifications.yaml \
    --parameter-overrides PipelineName="${APP_NAME}-eks" Email="${NOTIFY_EMAIL}" \
    --capabilities CAPABILITY_NAMED_IAM
  ok "Notifications stack deployed. Confirm the SNS subscription email."
fi

# ---------- 6) Kyverno (optional) ----------
if [[ ${APPLY_KYVERNO:-0} -eq 1 ]]; then
  if [[ -f deploy/fetch-cosign-pubkey.sh && -f deploy/apply-kyverno.sh ]]; then
    inf "Fetching cosign KMS public key and applying Kyverno policies…"
    chmod +x deploy/fetch-cosign-pubkey.sh deploy/apply-kyverno.sh
    deploy/fetch-cosign-pubkey.sh "${COSIGN_KMS_ALIAS}" "${COMM_REGION}"
    deploy/apply-kyverno.sh
    ok "Kyverno verifyImages + PodSecurity policies applied."
  else
    inf "Kyverno helper scripts not found; skipping policy apply."
  fi
fi

ok "Bootstrap auto-inject + deployment flow complete."
echo
echo "Next:"
echo "  1) Push this repo to the CodeCommit URL from the tools stack output."
echo "  2) Map the created deploy roles into each cluster's aws-auth."
echo "  3) Confirm ALB controller + Metrics Server are installed in clusters."
echo "  4) Commit to '${SOURCE_BRANCH}' to trigger the pipeline."
