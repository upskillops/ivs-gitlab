{{/*
Gateway API related templates to integrate with GitLab helm chart.
The GitLab helm chart overrides these with its own implementation.
*/}}

{{- define "gitlab.gatewayApi.route.enabled" -}}
{{- .Values.gatewayRoute.enabled | default false -}}
{{- end -}}

{{- define "gitlab.gatewayApi.route.gateway" -}}
{{- .Values.gatewayRoute.gatewayName | default "gateway" -}}
{{- end -}}

{{- define "gitlab.gatewayApi.gatewayRef" -}}
- group: gateway.networking.k8s.io
  kind: Gateway
  name: {{ include "gitlab.gatewayApi.route.gateway" . | quote }}
  {{- with .Values.gatewayRoute.gatewayNamespace }}
  namespace: {{ . | quote }}
  {{- end }}
  {{- with .Values.gatewayRoute.sectionName }}
  sectionName: {{ . | quote }}
  {{- end }}
{{- end -}}
