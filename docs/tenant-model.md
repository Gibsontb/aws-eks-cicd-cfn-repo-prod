# ============================================================
# Author: TGibson
# File: docs/tenant-model.md
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# Tenant Model (JWT -> RLS)

**Identity**: Amazon Cognito issues JWTs that include `custom:tenant_id` claim.  
**App**: extracts `tenant_id` and sets `SET app.tenant_id = '<uuid>'` per DB session.  
**Database**: Postgres RLS policies ensure every SELECT/INSERT/UPDATE/DELETE is restricted to `current_tenant_id()`.

**SKUs**
- **Pooled**: shared schema + RLS.
- **Silo**: schema-per-tenant (RLS still enforced).
- **Dedicated**: isolated deployment stamp.

**External Secrets** pulls DB and SMTP creds into cluster via Kubernetes `ExternalSecret`.
