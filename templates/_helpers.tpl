{{- define "clue-arena-app.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "clue-arena-app.fullname" -}}
{{- $name := include "clue-arena-app.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "clue-arena-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "clue-arena-app.labels" -}}
helm.sh/chart: {{ include "clue-arena-app.chart" . }}
{{ include "clue-arena-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "clue-arena-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clue-arena-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "clue-arena-app.serviceAccountName" -}}
{{- include "clue-arena-app.fullname" . -}}
{{- end -}}

{{- define "clue-arena-app.configMapName" -}}
{{- printf "%s-config" (include "clue-arena-app.fullname" .) -}}
{{- end -}}

{{- define "clue-arena-app.secretName" -}}
{{- printf "%s-secret" (include "clue-arena-app.fullname" .) -}}
{{- end -}}

{{- define "clue-arena-app.databaseUrl" -}}
{{- printf "/app/data/%s" .Values.app.database.filename -}}
{{- end -}}

{{- define "clue-arena-app.publicUrl" -}}
{{- if .Values.app.publicUrl -}}
{{- .Values.app.publicUrl -}}
{{- else if and .Values.exposure.enabled .Values.exposure.host -}}
{{- if .Values.exposure.tls.enabled -}}
{{- printf "https://%s" .Values.exposure.host -}}
{{- else -}}
{{- printf "http://%s" .Values.exposure.host -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "clue-arena-app.hasSecretData" -}}
{{- if or .Values.app.auth.authSecret .Values.app.auth.firebaseAdmin.projectId .Values.app.auth.firebaseAdmin.clientEmail .Values.app.auth.firebaseAdmin.privateKey .Values.app.mcp.authToken .Values.app.agents.geminiApiKey .Values.app.agents.mattin.apiKey -}}
true
{{- end -}}
{{- end -}}
