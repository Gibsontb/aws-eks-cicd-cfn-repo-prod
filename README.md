# ============================================================
# Author: TGibson
# File: README.md
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 6.0
# Date: 2025-08-27
# ============================================================
# AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation

##  Project Overview
AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation is a **multi-tenant SaaS reference architecture** that enforces **FedRAMP High, FIPS 140-2, RMF, and Zero Trust** requirements.

- Deploys into **AWS Commercial** and/or **GovCloud**.
- Supports **pooled, siloed, and dedicated stamp** tenant isolation.
- Full **CI/CD with supply chain security** (SBOM, Trivy, cosign).
- Built for **secure, auditable, production-ready SaaS delivery**.

---

##  Core Features
- **Multi-Tenant SaaS:** Namespace isolation, Helm templating, IRSA-based IAM roles.
- **GovCloud Parity:** Signed artifacts mirrored from Commercial into GovCloud.
- **Secure CI/CD:** CodePipeline + CodeBuild → Build → SBOM → Scan → Sign/Attest → Approval → Deploy.
- **Zero Trust:** Network (FIPS endpoints), Identity (OIDC + IAM least privilege), Runtime (Kyverno policies).
- **Observability:** CloudWatch, AMP, AMG, X-Ray, OTel.
- **Resilience:** AWS Backup + Velero for DR, cross-region replication for S3/ECR.
- **Cost Guardrails:** AWS Budgets, tagging (TenantID, Env, CostCenter), lifecycle policies.

---

##  Repository Structure

```
/deploy
  bootstrap-fill-and-deploy.sh
  deploy-commercial-tools.sh
  deploy-govcloud-tools.sh
  deploy-workloads.sh
  preflight-vpc.sh
  fetch-cosign-pubkey.sh
  apply-kyverno.sh

/ops
  /helm        → Helm charts, values-dev/stg/prod.yaml
  /pipeline    → buildspec-build.yml, buildspec-deploy.yml, buildspec-mirror-gov.yml
  /policies    → kyverno-verifyimages.yaml, kyverno-podsecurity.yaml
  /tenant      → values-tenant-template.yaml
  /k8s         → tenant-networkpolicy.yaml, tenant-resourcequota.yaml, otelsidecar.yaml, backup-policies.yaml
  /migrations  → aurora init + seed scripts

/templates
  tools-pipeline.yaml
  workload-deploy-iam.yaml
  aurora-postgres-slsv2.yaml
  cloudfront-alb.yaml
  waf-managed-rules.yaml
  pipeline-notifications.yaml
  gov-mirror-receiver.yaml

/docs
  tenant-model.md
  scoring-model.md

/dashboards
  grafana + CloudWatch JSON dashboards
```

---

##  Deployment Flow

1. **Preflight Validation**
   ```bash
   ./deploy/preflight-vpc.sh <region> <vpc-id> <subnets> <sg-id>
   ```
   Ensures all FIPS VPC endpoints exist (ECR, S3, KMS, STS, CodeBuild, Logs).

2. **Bootstrap + Tools Deployment**
   ```bash
   ./deploy/bootstrap-fill-and-deploy.sh
   ./deploy/deploy-commercial-tools.sh
   ./deploy/deploy-govcloud-tools.sh   # optional
   ```

3. **Workload Deployment**
   ```bash
   ./deploy/deploy-workloads.sh
   ```

4. **Kyverno Policies**
   ```bash
   ./deploy/fetch-cosign-pubkey.sh alias/myservice-cosign us-east-1
   ./deploy/apply-kyverno.sh
   ```

5. **Pipeline Operation**
   - Build → SBOM (Syft) → Trivy → cosign sign + attest
   - Deploy dev → Manual approval → stg → Manual approval → prod
   - Mirror to GovCloud ECR

---

##  Security Highlights
- Immutable ECR repos, scan-on-push.
- S3 buckets with **KMS, TLS-only, object lock optional**.
- IRSA for pod-level IAM, no static secrets.
- External Secrets Operator integrates with Secrets Manager.
- Kyverno verifyImages + pod security baseline enforced.

---

##  Observability & Ops
- Logging: CloudWatch + optional Fluent Bit → ELK.
- Metrics: AMP + Grafana dashboards (`/dashboards`).
- Tracing: X-Ray + OpenTelemetry (`/ops/k8s/otelsidecar.yaml`).
- Cost: CUR + tagging (TenantID, Env, CostCenter).
- DR: Velero + AWS Backup (`/ops/k8s/backup-policies.yaml`).

---

##  Compliance & Audit Readiness
- **FedRAMP High:** AWS-native services + audit logs.
- **FIPS 140-2:** All service calls restricted to FIPS endpoints.
- **RMF Alignment:** Controls mapped to repo artifacts (see `/docs`).
- **Zero Trust:** OMB M-22-09 implemented across layers.

---

##  Next Steps
- Clone this repo into **CodeCommit**.
- Run `bootstrap-fill-and-deploy.sh`.
- Push code → pipeline builds → secure SaaS deploy.

---
