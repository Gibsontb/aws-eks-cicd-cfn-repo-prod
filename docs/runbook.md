# ============================================================
# Author: TGibson
# File: docs/runbook.md
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# Runbook (SLOs, Alarms, On-Call)

**SLOs**
- API p95 < 1s
- 5xx error rate < 2%

**Alarms**
- CloudWatch Alarms in `templates/cloudwatch-slos.yaml` publish to SNS email.

**Debug Tips**
- Check ALB TargetResponseTime spikes → correlate with Pod CPU/mem (Grafana).
- Investigate 5xx → app logs via CloudWatch/FluentBit; verify DB connections.
