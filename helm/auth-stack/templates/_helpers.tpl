{{/*
Expand the name of the chart.
*/}}
{{- define "auth-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "auth-stack.fullname" -}}
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
{{- define "auth-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "auth-stack.labels" -}}
helm.sh/chart: {{ include "auth-stack.chart" . }}
{{ include "auth-stack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "auth-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "auth-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "auth-stack.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "auth-stack.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "auth-stack.frontend.labels" -}}
{{ include "auth-stack.labels" . }}
app: frontend
component: frontend
{{- end }}

{{/*
Backend labels
*/}}
{{- define "auth-stack.backend.labels" -}}
{{ include "auth-stack.labels" . }}
app: backend
component: backend
{{- end }}

{{/*
MariaDB labels
*/}}
{{- define "auth-stack.mariadb.labels" -}}
{{ include "auth-stack.labels" . }}
app: mariadb
component: database
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "auth-stack.frontend.selectorLabels" -}}
{{ include "auth-stack.selectorLabels" . }}
app: frontend
{{- end }}

{{/*
Backend selector labels
*/}}
{{- define "auth-stack.backend.selectorLabels" -}}
{{ include "auth-stack.selectorLabels" . }}
app: backend
{{- end }}

{{/*
MariaDB selector labels
*/}}
{{- define "auth-stack.mariadb.selectorLabels" -}}
{{ include "auth-stack.selectorLabels" . }}
app: mariadb
{{- end }}
