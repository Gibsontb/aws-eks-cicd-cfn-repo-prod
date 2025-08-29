# ============================================================
# Author: TGibson
# File: services/scoring/main.py
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
from fastapi import FastAPI
app = FastAPI()
@app.get('/')
def root():
    return {'status':'ok'}
