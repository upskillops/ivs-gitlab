{{/*
Expand the name of the chart.
*/}}
{{- define "ai-gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ai-gateway.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ai-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ai-gateway.labels" -}}
helm.sh/chart: {{ include "ai-gateway.chart" . }}
{{ include "ai-gateway.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ai-gateway.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ai-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ai-gateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ai-gateway.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
GitLab URL
*/}}
{{- define "ai-gateway.gitlab.url" -}}
{{- .Values.gitlab.url }}
{{- end }}

{{/*
GitLab API URL
*/}}
{{- define "ai-gateway.gitlab.apiUrl" -}}
{{- .Values.gitlab.apiUrl }}
{{- end }}

{{/*
Secret AIGW aigwSigningKey key helper
*/}}
{{- define "ai-gateway.aigwSigningKey.secret" -}}
{{- (.Values.aigwSigningKey).secret | default ""}}
{{- end }}

{{- define "ai-gateway.aigwSigningKey.key" -}}
{{- (.Values.aigwSigningKey).key | default "" }}
{{- end }}

{{/*
Secret AIGW aigwValidationKey key helper
*/}}
{{- define "ai-gateway.aigwValidationKey.secret" -}}
{{- (.Values.aigwValidationKey).secret | default ""}}
{{- end }}

{{- define "ai-gateway.aigwValidationKey.key" -}}
{{- (.Values.aigwValidationKey).key | default "" }}
{{- end }}

{{/*
Secret AIGW duoWorkflowSigningKey key helper
*/}}
{{- define "ai-gateway.duoWorkflowSigningKey.secret" -}}
{{- (.Values.duoWorkflowSigningKey).secret | default ""}}
{{- end }}

{{- define "ai-gateway.duoWorkflowSigningKey.key" -}}
{{- (.Values.duoWorkflowSigningKey).key | default "" }}
{{- end }}

{{/*
Secret AIGW duoWorkflowValidationKey key helper
*/}}
{{- define "ai-gateway.duoWorkflowValidationKey.secret" -}}
{{- (.Values.duoWorkflowValidationKey).secret | default ""}}
{{- end }}

{{- define "ai-gateway.duoWorkflowValidationKey.key" -}}
{{- (.Values.duoWorkflowValidationKey).key | default "" }}
{{- end }}

{{- define "ai-gateway.ingress.enabled" -}}
{{- and .Values.ingress.enabled (eq .Values.ingress.gitlabIngressEnabled false) }}
{{- end }}

{{- define "ai-gateway.ingress.grpc.enabled" -}}
{{- and .Values.ingress.enabled .Values.duoWorkflow.enabled (eq .Values.ingress.gitlabIngressEnabled false) }}
{{- end }}

{{/*
Image pull secrets - merges global.image.pullSecrets from the parent GitLab chart
with the chart-local imagePullSecrets, mirroring the parent chart's
"gitlab.image.pullSecrets" helper. Both lists must be `- name: <secret>` entries.
A copy of this helper lives in charts/grpc-tls-proxy/templates/_helpers.tpl.
*/}}
{{- define "ai-gateway.imagePullSecrets" -}}
{{- $secrets := concat (default (list) ((.Values.global).image).pullSecrets) (default (list) .Values.imagePullSecrets) -}}
{{- range $secrets }}
- name: {{ .name }}
{{- end }}
{{- end }}
