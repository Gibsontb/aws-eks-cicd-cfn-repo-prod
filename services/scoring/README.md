# ============================================================
# Author: TGibson
# File: services/scoring/README.md
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# Scoring Service

FastAPI microservice for Zero-Trust scoring. Exposes:
- `POST /assessments/{id}/score` to trigger scoring
- `GET /assessments/{id}` to fetch results

Env:
- DB_*
- S3_EVIDENCE_BUCKET
- EVENT_BUS_NAME
- TENANT_CLAIM (JWT claim containing tenant_id)


## Update
Now submits scoring tasks as AWS Batch jobs on EKS, instead of relying on cluster autoscaling.
