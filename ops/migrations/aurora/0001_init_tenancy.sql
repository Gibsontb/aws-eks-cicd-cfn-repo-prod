# ============================================================
# Author: TGibson
# File: ops/migrations/aurora/0001_init_tenancy.sql
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
-- Tenancy bootstrap with Row-Level Security (RLS)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Helper: current tenant from session setting
CREATE OR REPLACE FUNCTION current_tenant_id() RETURNS uuid AS $$
DECLARE
  tid text;
BEGIN
  tid := current_setting('app.tenant_id', true);
  IF tid IS NULL THEN
    RAISE EXCEPTION 'app.tenant_id is not set for this session';
  END IF;
  RETURN tid::uuid;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE TABLE tenants (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app_users (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email text NOT NULL,
  role text NOT NULL CHECK (role IN ('TenantAdmin','Analyst')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE assessments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  title text NOT NULL,
  status text NOT NULL CHECK (status IN ('draft','running','complete','failed')),
  requested_by uuid REFERENCES app_users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE evidence (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  assessment_id uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  s3_uri text NOT NULL,
  content_sha256 text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE scores (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  assessment_id uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  total numeric NOT NULL,
  tier text NOT NULL CHECK (tier IN ('Traditional','Initial','Advanced','Optimal')),
  breakdown jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE scores ENABLE ROW LEVEL SECURITY;

-- Policies: only rows matching current_tenant_id
CREATE POLICY tenant_isolation_tenants ON tenants
  USING (id = current_tenant_id());

CREATE POLICY tenant_isolation_app_users ON app_users
  USING (tenant_id = current_tenant_id());

CREATE POLICY tenant_isolation_assessments ON assessments
  USING (tenant_id = current_tenant_id());

CREATE POLICY tenant_isolation_evidence ON evidence
  USING (tenant_id = current_tenant_id());

CREATE POLICY tenant_isolation_scores ON scores
  USING (tenant_id = current_tenant_id());

-- App should set: SELECT set_config('app.tenant_id', '<uuid-from-jwt-claim>', false);
