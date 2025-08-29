# ============================================================
# Author: TGibson
# File: services/scoring/Dockerfile
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
FROM public.ecr.aws/lambda/python:3.11
# Using Lambda base for smaller footprint; alternatively use python:3.11-slim and run with gunicorn/uvicorn
COPY requirements.txt /var/task/
RUN pip install -r /var/task/requirements.txt
COPY app /var/task/app
CMD ["app.main.handler"]
