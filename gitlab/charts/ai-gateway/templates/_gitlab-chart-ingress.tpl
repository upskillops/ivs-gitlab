
{{- define "gitlab.ingress.enabled" -}}
{{- .Values.ingress.gitlabIngressEnabled }}
{{- end }}

{{- define "ai-gateway.ingress.annotations" -}}
{{- toYaml .Values.ingress.annotations }}
{{- end }}

{{/*
Returns the secret name for the Secret containing the TLS certificate and key.
Uses `ingress.tls.secretName` first and falls back to `global.ingress.tls.secretName`
if there is a shared tls secret for all ingresses.
*/}}
{{- define "gitlab.ai-gateway.ingress.tlsSecret" -}}
{{- $defaultName := (dict "secretName" "") -}}
{{- if .Values.global.ingress.configureCertmanager -}}
{{- $_ := set $defaultName "secretName" (printf "%s-ai-gateway-tls" .Release.Name) -}}
{{- else -}}
{{- $_ := set $defaultName "secretName" (include "gitlab.wildcard-self-signed-cert-name" .) -}}
{{- end -}}
{{- pluck "secretName" .Values.ingress.tls .Values.global.ingress.tls $defaultName | first -}}
{{- end -}}

{{- define "gitlab.gatewayApi.route.enabled" -}}
false
{{- end }}

{{- define "gitlab.ai-gateway.hostname" -}}
{{- end }}

{{- define "gitlab.ai-gateway.grpcHostname" -}}
{{- end }}

{{- define "gitlab.standardLabels" -}}
{{- end }}

{{- define "gitlab.gatewayApi.gatewayRef" -}}
{{- end }}
