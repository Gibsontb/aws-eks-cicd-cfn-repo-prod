# ============================================================
# Author: TGibson
# File: app/Dockerfile
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.0
# Date: 2025-08-27
# ============================================================

FROM public.ecr.aws/docker/library/python:3.11-slim
WORKDIR /app
COPY main.py /app/main.py
RUN pip install --no-cache-dir fastapi uvicorn
EXPOSE 8080
CMD ["uvicorn","main:app","--host","0.0.0.0","--port","8080"]
