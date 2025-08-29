# ============================================================
# Author: TGibson
# File: services/scoring/app/main.py
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
import os, json, jwt, boto3
from fastapi import FastAPI, Header, HTTPException
from typing import Optional

app = FastAPI(title="ZT Scoring Service")

JOB_QUEUE = os.getenv("JOB_QUEUE")
JOB_DEFINITION = os.getenv("JOB_DEFINITION")
TENANT_CLAIM = os.getenv("TENANT_CLAIM","custom:tenant_id")

batch = boto3.client("batch")

def get_tenant_id(auth_header: Optional[str]) -> str:
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split(" ",1)[1]
    try:
        decoded = jwt.decode(token, options={"verify_signature": False})  # JWKS verification should be added
        tid = decoded.get(TENANT_CLAIM)
        if not tid:
            raise ValueError("tenant claim missing")
        return tid
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

@app.post("/assessments/{assessment_id}/score")
def score(assessment_id: str, authorization: Optional[str] = Header(None)):
    tenant_id = get_tenant_id(authorization)
    detail = {"tenant_id": tenant_id, "assessment_id": assessment_id}
    events.put_events(Entries=[{
        "Source": "zt.app",
        "DetailType": "ScoringRequested",
        "Detail": json.dumps(detail),
        "EventBusName": EVENT_BUS
    }])
    return {"status":"queued","detail":detail}

@app.get("/healthz")
def health():
    return {"ok": True}
