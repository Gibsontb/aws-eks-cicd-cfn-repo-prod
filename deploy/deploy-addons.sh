# ============================================================
# Author: TGibson
# File: deploy/deploy-addons.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.1
# Date: 2025-08-27
# ============================================================
# NOTE: GovCloud-safe scaling = EKS Managed Node Groups + AWS Batch on EKS (no OSS autoscalers)
# ============================================================
# Author: TGibson
# File: deploy/deploy-addons.sh
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.0
# Date: 2025-08-27
# ============================================================
#!/usr/bin/env bash
set -euo pipefail

CFG="${1:-config/addons-config.json}"

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
require jq
require aws

val(){ jq -r "$1" "$CFG"; }
is_true(){ [[ "$(val "$1")" == "true" ]]; }

PROJECT=$(val .Global.Project)
ENVIRON=$(val .Global.Environment)
REGION=$(val .Global.Region)
PROFILE=$(val .Global.Profile)

STACK() { echo "${PROJECT}-${ENVIRON}-$1"; }

aws() {
  command aws --region "$REGION" --profile "$PROFILE" "$@"
}

echo "Using config: $CFG"
echo "Project: $PROJECT  Env: $ENVIRON  Region: $REGION  Profile: $PROFILE"

deploy_stack() {
  local name="$1"; shift
  echo ">> Deploying stack: $name"
  aws cloudformation deploy --stack-name "$name" --template-file "$@" --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
}

# --- DNS (Route53)
if is_true .DNS.Enable; then
  deploy_stack "$(STACK dns-route53)" templates/dns-route53.yaml \
    --parameter-overrides \
      HostedZoneId="$(val .DNS.HostedZoneId)" \
      RecordName="$(val .DNS.RecordName)" \
      AlbDnsName="$(val .DNS.AlbDnsName)" \
      AlbHostedZoneId="$(val .DNS.AlbHostedZoneId)" \
      TTL="$(val .DNS.TTL)" \
      CreateAAAA="$(val .DNS.CreateAAAA)"
fi

# --- WAF WebACL
if is_true .WAF.Enable; then
  deploy_stack "$(STACK waf-webacl)" templates/waf-webacl.yaml \
    --parameter-overrides \
      WebAclName="$(val .WAF.WebAclName)" \
      AlbArn="$(val .WAF.AlbArn)" \
      EnableCommonRuleSet="$(val .WAF.EnableCommonRuleSet)" \
      EnableKnownBadInputs="$(val .WAF.EnableKnownBadInputs)" \
      OptionalIpSetArn="$(val .WAF.OptionalIpSetArn)" \
      EnableLogging="$(val .WAF.EnableLogging)" \
      LogDestinationArn="$(val .WAF.LogDestinationArn)"
fi

# --- CloudWatch Observability
if is_true .CloudWatch.Enable; then
  deploy_stack "$(STACK observability-cw)" templates/observability-cloudwatch.yaml \
    --parameter-overrides \
      ClusterName="$(val .CloudWatch.ClusterName)" \
      LogGroupPrefix="$(val .CloudWatch.LogGroupPrefix)" \
      LogRetentionDays="$(val .CloudWatch.LogRetentionDays)" \
      CreateAlarms="$(val .CloudWatch.CreateAlarms)" \
      AlarmEmailTopicArn="$(val .CloudWatch.AlarmEmailTopicArn)" \
      AlbMetricLoadBalancerFullName="$(val .CloudWatch.AlbMetricLoadBalancerFullName)" \
      Alb5xxThreshold="$(val .CloudWatch.Alb5xxThreshold)" \
      Alb5xxPeriodSeconds="$(val .CloudWatch.Alb5xxPeriodSeconds)" \
      Alb5xxEvalPeriods="$(val .CloudWatch.Alb5xxEvalPeriods)"
fi

# --- AMP / AMG
deploy_amp=false
deploy_amg=false
$([ "$(val .AMP_AMG.EnableAmp)" = "true" ]) && deploy_amp=true
$([ "$(val .AMP_AMG.EnableAmg)" = "true" ]) && deploy_amg=true
if $deploy_amp || $deploy_amg; then
  params=( --parameter-overrides
    EnableAmp="$(val .AMP_AMG.EnableAmp)"
    AmpWorkspaceAlias="$(val .AMP_AMG.AmpWorkspaceAlias)"
    EnableAmg="$(val .AMP_AMG.EnableAmg)"
    GrafanaWorkspaceName="$(val .AMP_AMG.GrafanaWorkspaceName)"
    AmgAccountAccessType="$(val .AMP_AMG.AmgAccountAccessType)"
    AmgAuthenticationProviders="$(jq -r '.AMP_AMG.AmgAuthenticationProviders|join(",")' "$CFG")"
    AmgRoleArn="$(val .AMP_AMG.AmgRoleArn)"
    DataSources="$(jq -r '.AMP_AMG.DataSources|join(",")' "$CFG")"
  )
  deploy_stack "$(STACK observability-amp-amg)" templates/observability-amp-amg.yaml "${params[@]}"
fi

# --- OTel / X-Ray
if is_true .OTel_XRay.Enable; then
  deploy_stack "$(STACK otel-xray)" templates/observability-otel-xray.yaml \
    --parameter-overrides \
      ClusterName="$(val .Global.ClusterName)" \
      OidcProviderArn="$(val .Global.OidcProviderArn)" \
      Namespace="$(val .OTel_XRay.Namespace)" \
      ServiceAccountName="$(val .OTel_XRay.ServiceAccountName)" \
      EnableXRay="$(val .OTel_XRay.EnableXRay)" \
      KmsKeyArnForXRay="$(val .OTel_XRay.KmsKeyArnForXRay)"
  echo ">> Apply the Kubernetes manifest for the collector:"
  echo "   kubectl apply -f ops/k8s/otel-collector.yaml"
fi

# --- Backup
if is_true .Backup.Enable; then
  deploy_stack "$(STACK backup-policies)" templates/backup-policies.yaml \
    --parameter-overrides \
      BackupVaultName="$(val .Backup.BackupVaultName)" \
      BackupPlanName="$(val .Backup.BackupPlanName)" \
      ScheduleExpression="$(val .Backup.ScheduleExpression)" \
      StartWindowMinutes="$(val .Backup.StartWindowMinutes)" \
      CompletionWindowMinutes="$(val .Backup.CompletionWindowMinutes)" \
      TransitionToColdAfterDays="$(val .Backup.TransitionToColdAfterDays)" \
      RetentionDays="$(val .Backup.RetentionDays)" \
      CopyToRegion="$(val .Backup.CopyToRegion)" \
      KmsKeyArn="$(val .Backup.KmsKeyArn)" \
      SelectionTagKey="$(val .Backup.SelectionTagKey)" \
      SelectionTagValue="$(val .Backup.SelectionTagValue)"
fi

echo "All selected add-on stacks processed."
