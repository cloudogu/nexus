{{- define "nexus.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "nexus.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "nexus.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/* All-in-one labels */}}
{{- define "nexus.labels" -}}
app: ces
{{ include "nexus.selectorLabels" . }}
helm.sh/chart: {{- printf " %s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.extraLabels }}
{{ toYaml .Values.extraLabels }}
{{- end }}
{{- end }}

{{/* Selector labels */}}
{{- define "nexus.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nexus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "nexus.backupLabels" -}}
k8s.cloudogu.com/backup-scope: nexus
{{- end }}

{{- define "nexus.postgresqlServiceName" -}}
{{- printf "%s-postgresql" (include "nexus.fullname" .) -}}
{{- end -}}

{{- define "nexus.lookupSecretValue" -}}
{{- $root := .root -}}
{{- $secretName := .secretName -}}
{{- $key := .key -}}
{{- $secret := lookup "v1" "Secret" $root.Release.Namespace $secretName -}}
{{- if and $secret $secret.data -}}
{{- with (index $secret.data $key) -}}
{{- . | b64dec -}}
{{- end -}}
{{- end -}}
{{- end -}}
