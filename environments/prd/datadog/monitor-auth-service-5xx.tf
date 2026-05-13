terraform {
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = "https://api.datadoghq.com/"
}

variable "datadog_api_key" {
  type      = string
  sensitive = true
}

variable "datadog_app_key" {
  type      = string
  sensitive = true
}

variable "github_pat_token" {
  type      = string
  sensitive = true
}

resource "datadog_monitor" "auth_service_5xx_rate" {
  name    = "Auth Service — Taxa de Erros 5xx > 5%"
  type    = "metric alert"
  message = <<-EOT
    ## Alerta: Auth Service com alta taxa de erros 5xx

    A taxa de erros HTTP 5xx do **auth-service** ultrapassou **5%** nos últimos 5 minutos.

    **Ação automática:** O GitHub Actions irá executar `kubectl rollout restart` no deployment.

    **Monitor:** https://app.datadoghq.com/monitors/279096570

    @webhook-Alertas_fiap_tech_challenge @jsm_ops-projeto-fiap-tech-challange-fiap-fiap-tech-challenge
  EOT

  query = "sum(last_5m):( sum:trace.http.request.errors{service:auth-service,http.status_class:5xx}.as_count() / sum:trace.http.request.hits{service:auth-service}.as_count() ) * 100 > 5"

  thresholds = {
    critical          = 5
    critical_recovery = 2
    warning           = 3
    warning_recovery  = 1
  }

  notify_no_data    = false
  renotify_interval = 60
  timeout_h         = 1

  tags = [
    "service:auth-service",
    "env:production",
    "team:fiap-tech-challenge",
    "project:togglemaster"
  ]
}

resource "datadog_webhook" "self_healing_github" {
  name           = "Alertas_fiap_tech_challenge"
  url            = "https://api.github.com/repos/AXMEDUSA/ToggleMaster-gitops/dispatches"
  encode_as      = "json"

  payload = jsonencode({
    event_type = "datadog-alert-auth-service"
    client_payload = {
      alert_title  = "$EVENT_TITLE"
      alert_status = "$ALERT_STATUS"
      monitor_url  = "https://app.datadoghq.com/monitors/279096570"
      service      = "auth-service"
    }
  })

  custom_headers = jsonencode({
    Authorization        = "Bearer ${var.github_pat_token}"
    Accept               = "application/vnd.github+json"
    X-GitHub-Api-Version = "2022-11-28"
  })
}
