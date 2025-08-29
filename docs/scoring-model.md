# ============================================================
# Author: TGibson
# File: docs/scoring-model.md
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# Scoring Model

**Pillars**: Identity, Devices, Network, Application, Data, Visibility/Analytics, Automation (CISA ZTMM 2.0).  
**Tiers**: Traditional → Initial → Advanced → Optimal.  
**Weights**: control-level weights in `control_catalog.weight`.

**Flow**
1. Assessment created → evidence S3 uploads (pre-signed URLs).
2. App POST `/assessments/{id}/score` → EventBridge `ScoringRequested`.
3. Step Functions executes: Gather → Run Checks → Compute → Persist → Notify.
4. Results persisted to `scores` with breakdown JSON.

**Next**: replace StepFunction `Pass` states with Lambdas, add Athena queries for evidence analytics.
