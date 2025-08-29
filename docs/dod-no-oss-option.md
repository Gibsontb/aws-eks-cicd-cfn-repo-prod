============================================================

Author: TGibson

File: docs/dod-no-oss-option.md

Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation

Version: 1.1

Date: 2025-08-27

============================================================

DoD "No Open Source Controllers" Option

This path avoids Kubernetes controllers like Karpenter and AWS Load Balancer Controller by using ECS on Fargate and native AWS integrations.

Components

•	ECS Fargate: serverless containers, no node management

•	ALB: natively integrated with ECS

•	CloudFront + WAF: edge + protection

•	EventBridge, Step Functions, SES/SNS: workflows and notifications

•	Aurora PostgreSQL Serverless v2: OLTP

•	S3: evidence

•	CodePipeline/CodeBuild: CI/CD

Why

•	Eliminates reliance on open-source Kubernetes controllers.

•	Reduces ATO surface area (all managed AWS services with FedRAMP baselines available).



