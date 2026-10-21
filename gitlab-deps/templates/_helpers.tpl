{{/* Reuse an existing secret value on upgrade, otherwise generate one. */}}
{{- define "deps.secretValue" -}}
{{- $s := lookup "v1" "Secret" .ns .name -}}
{{- if and $s (index $s.data .key) -}}
{{- index $s.data .key | b64dec -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}

{{- define "deps.storageClass" -}}
{{- if .Values.storageClass }}
storageClassName: {{ .Values.storageClass }}
{{- end }}
{{- end -}}
