# ============================================================
# Author: TGibson
# File: app/main.py
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.0
# Date: 2025-08-27
# ============================================================

from fastapi import FastAPI
app = FastAPI()
@app.get("/")
def ok():
    return {"status":"ok","service":"myservice"}
