# Webhook Self-Healing — Configuração no Datadog

## Onde configurar
Datadog → Integrations → Webhooks → New Webhook

---

## Nome
```
Alertas_fiap_tech_challenge
```

## URL
```
https://api.github.com/repos/AXMEDUSA/ToggleMaster-gitops/dispatches
```

## Headers (JSON)
```json
{
  "Authorization": "Bearer GITHUB_PAT_TOKEN",
  "Accept": "application/vnd.github+json",
  "X-GitHub-Api-Version": "2022-11-28"
}
```

> Gerar o token em: GitHub → Settings → Developer settings → Personal access tokens → Fine-grained
> Permissão necessária: Actions: Read and Write (repositório ToggleMaster-gitops)

## Payload (JSON)
```json
{
  "event_type": "datadog-alert-auth-service",
  "client_payload": {
    "alert_title": "$EVENT_TITLE",
    "alert_status": "$ALERT_STATUS",
    "monitor_url": "https://app.datadoghq.com/monitors/279096570",
    "service": "auth-service"
  }
}
```

---

## Monitor 279096570 — Configuração da notificação

No monitor do Datadog, em **"Notify your team"**, adicionar:
```
@webhook-Alertas_fiap_tech_challenge @jsm_ops-projeto-fiap-tech-challange-fiap-fiap-tech-challenge
```

---

## GitHub Secret necessário no repositório

| Secret               | Valor                                                             |
|----------------------|-------------------------------------------------------------------|
| `KUBECONFIG_B64`     | `cat ~/.kube/config \| base64 -w0`                               |
| `DISCORD_WEBHOOK_URL`| `https://discord.com/api/webhooks/1503554151290896404/misZKHG...`|
