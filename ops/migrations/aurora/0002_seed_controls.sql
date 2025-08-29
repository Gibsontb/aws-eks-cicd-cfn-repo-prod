# ============================================================
# Author: TGibson
# File: ops/migrations/aurora/0002_seed_controls.sql
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
-- Control catalog mapped to NIST 800-207 & CISA ZTMM 2.0 pillars

CREATE TABLE IF NOT EXISTS control_catalog (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  pillar text NOT NULL,               -- Identity, Devices, Network, Application, Data, Visibility/Analytics, Automation
  control_code text NOT NULL,         -- e.g., ID-01
  title text NOT NULL,
  description text NOT NULL,
  weight numeric NOT NULL DEFAULT 1.0,
  maturity_map jsonb NOT NULL         -- e.g., {"Traditional":0, "Initial":0.4, "Advanced":0.7, "Optimal":1.0}
);

INSERT INTO control_catalog (pillar, control_code, title, description, weight, maturity_map) VALUES
('Identity','ID-01','Central IdP','All workforce identities governed by centralized IdP with MFA enforced',1.0,'{"Traditional":0,"Initial":0.4,"Advanced":0.7,"Optimal":1.0}'),
('Devices','DV-02','Device Posture','Device compliance posture checked before granting access',1.2,'{"Traditional":0,"Initial":0.3,"Advanced":0.7,"Optimal":1.0}'),
('Network','NW-03','Microsegmentation','Workloads isolated via security groups and policies; east-west traffic governed',1.1,'{"Traditional":0,"Initial":0.5,"Advanced":0.8,"Optimal":1.0}');
