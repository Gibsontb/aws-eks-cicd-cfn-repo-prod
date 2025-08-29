# ============================================================
# Author: TGibson
# File: ops/helm/templates/_helpers.tpl
# Repo: AWS EKS CI/CD (Commercial + GovCloud) via CloudFormation
# Version: 1.0
# Date: 2025-08-27
# ============================================================

{{- define "myservice.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "myservice.fullname" -}}
{{- printf "%s-%s" (include "myservice.name" .) .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "myservice.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "myservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "myservice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "myservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "myservice.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "myservice.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
