# Entregáveis — Fase 4 Tech Challenge FIAP

---

## STATUS GERAL

| # | Entregável | Status |
|---|-----------|--------|
| 1 | Código IaC/GitOps com stack de monitoramento | ✅ Feito |
| 2 | Código fonte com instrumentação APM/OTel | ✅ Feito |
| 3 | Scripts/automações de Self-Healing | ✅ Feito |
| 4 | Vídeo de demonstração | ⚠️ Gravar |
| 5 | Relatório PDF | ⚠️ Montar |

---

## 1. CÓDIGO FONTE NO REPOSITÓRIO

### ✅ IaC/GitOps com stack de monitoramento

**Repositório:** https://github.com/AXMEDUSA/ToggleMaster-gitops

Stack de monitoramento deployada via ArgoCD:

| Componente | Namespace | Status |
|-----------|-----------|--------|
| OTel Collector | observability | ✅ Running |
| Grafana | observability | ✅ Running (3/3) |
| Loki | observability | ✅ Running |
| Prometheus | observability | ✅ Running |
| Promtail | observability | ✅ Running |
| Datadog Agent | datadog | ✅ Running |
| Datadog Cluster Agent | datadog | ✅ Running |

Arquivos GitOps relevantes:
- `environments/prd/observability/otel-collector.yaml`
- `environments/prd/observability/grafana-app.yaml`
- `environments/prd/observability/loki-app.yaml`
- `environments/prd/observability/prometheus-app.yaml`
- `environments/prd/datadog/`

### ✅ Código fonte com instrumentação

**Repositório:** https://github.com/AXMEDUSA/ToggleMaster-AppRepo

| Serviço | Linguagem | Instrumentação |
|---------|-----------|---------------|
| auth-service | Go | dd-trace-go v2.8.0 + OTel SDK |
| evaluation-service | Go | dd-trace-go v2.8.0 + OTel SDK |
| flag-service | Python | ddtrace + OTel SDK |
| targeting-service | Python | ddtrace + OTel SDK |
| analytics-service | Python | ddtrace + OTel SDK |

Todos os serviços enviam traces via:
- **Datadog Agent** (porta 8126) → Datadog APM
- **OTel Collector** (porta 4317 gRPC) → Grafana/Loki

### ✅ Scripts e automações de Self-Healing

| Arquivo | Descrição |
|---------|-----------|
| `generate-5xx-errors.sh` | Gera erros HTTP 500 para disparar o monitor |
| `.github/workflows/self-healing-auth-service.yml` | Workflow que executa o rollout restart |

---

## 2. VÍDEO DE DEMONSTRAÇÃO (até 25 min)

### Roteiro sugerido para o vídeo

#### 🎬 Parte 1 — Visão Geral (3 min)
- Mostrar cluster AKS rodando: `kubectl get nodes` e `kubectl get pods -A`
- Abrir ArgoCD e mostrar os 5 serviços sincronizados (verde)
- Mostrar os 2 repositórios no GitHub (AppRepo + GitOps)

> **Atenção:** o enunciado menciona EKS (AWS) mas o projeto usa AKS (Azure). Mencionar isso no vídeo e justificar que a proposta é equivalente.

#### 🎬 Parte 2 — Métricas, Logs e OTel (5 min)
- Abrir Grafana: `kubectl port-forward svc/grafana -n observability 3000:80`
- Mostrar o dashboard customizado com métricas dos serviços
- Buscar logs no Loki (fonte: Promtail coletando logs dos pods)
- Explicar o fluxo do OTel Collector: aplicação → OTel Collector → Datadog/Grafana

> ⚠️ **PENDÊNCIA:** Tirar print do dashboard do Grafana e de uma query no Loki para o relatório.

#### 🎬 Parte 3 — APM e Tracing (5 min)
- Abrir Datadog APM: https://app.datadoghq.com/apm/services
- Mostrar o Service Map com os 5 serviços
- Fazer uma requisição de teste ao auth-service e mostrar o trace distribuído

> ⚠️ **PENDÊNCIA:** Tirar print do Service Map e de um trace distribuído detalhado.

#### 🎬 Parte 4 — Incidente e Self-Healing — A Prova Real (10 min)

Este é o item mais importante. Roteiro:

1. Mostrar monitor no Datadog em estado `OK`
   - https://app.datadoghq.com/monitors/282578515
2. Mostrar que o monitor está configurado (query, thresholds, webhook)
3. Rodar o script de geração de erros:
   ```bash
   bash generate-5xx-errors.sh 100
   ```
4. Mostrar o gráfico no Datadog APM subindo para 80% de erro
5. Mostrar o monitor mudando para `Alert` (Firing)
6. Mostrar o GitHub Actions sendo acionado automaticamente
   - https://github.com/AXMEDUSA/ToggleMaster-gitops/actions
7. Mostrar no terminal os pods reiniciando:
   ```bash
   kubectl get pods -n auth-service-prd -w
   ```
8. Mostrar o Discord recebendo o embed de ✅ Self-Healing Concluído
9. Mostrar o Jira Ops com o incidente aberto automaticamente

---

## 3. RELATÓRIO PDF

### Informações necessárias para o relatório

> ⚠️ **PENDÊNCIA:** Preencher os dados do time abaixo.

| Campo | Valor |
|-------|-------|
| Jailson Vitor Domingos da Silva | RM367527 |
| Pedro Gimenez Miranda Silva | RM368740 |
| Diego José de Melo | RM368013 |
| Felipe da Matta | RM367534 |
| Link AppRepo | https://github.com/AXMEDUSA/ToggleMaster-AppRepo |
| Link GitOps | https://github.com/AXMEDUSA/ToggleMaster-gitops |
| Link Vídeo | *(preencher após gravar)* |

### Evidências visuais obrigatórias

| Evidência | Status | Arquivo |
|-----------|--------|---------|
| Print do Dashboard do Grafana (visão geral) | ✅ Temos | `docs/prints/08-grafana-dashboard-visao-geral.png` |
| Print do Dashboard do Grafana (logs + métricas) | ✅ Temos | `docs/prints/09-grafana-dashboard-logs-loki-metricas.png` |
| Print de um Trace distribuído no APM (lista) | ✅ Temos | `docs/prints/10-datadog-apm-traces-lista.png` |
| Print de um Trace distribuído no APM (detalhe) | ✅ Temos | `docs/prints/11-datadog-apm-trace-detalhe-auth-service.png` |
| Print do Service Map — completo | ✅ Temos | `docs/prints/14-datadog-service-map-completo.png` |
| Print da notificação no Discord | ✅ Temos | `docs/prints/03-discord-self-healing.png` |
| Print do incidente no Jira Ops | ✅ Temos | `docs/prints/01-jira-incidente.png` |
| Print do Self-Healing no GitHub Actions | ✅ Temos | `docs/prints/06-github-actions-selfhealing.png` |
| Print do erro 500 no Datadog APM | ✅ Temos | `docs/prints/04-datadog-error-rate.png` |
| Print dos pods reiniciando (Kubernetes) | ✅ Temos | `docs/prints/07-kubernetes-pods.png` |

### Justificativa Técnica (para o relatório)

#### Arquitetura OTel implementada

```
Aplicações (Go/Python)
        │
        ├── dd-trace-go / ddtrace  ──→  Datadog Agent (porta 8126)  ──→  Datadog Cloud
        │
        └── OTel SDK (OTLP gRPC)  ──→  OTel Collector (porta 4317)
                                            │
                                            ├──→  Grafana / Loki (logs)
                                            └──→  Prometheus (métricas)
```

O OTel Collector atua como roteador central: recebe dados das aplicações via protocolo OTLP e os distribui para múltiplos backends simultaneamente — Datadog para APM/tracing e Grafana/Loki para métricas e logs.

#### Por que Datadog e não New Relic?

- Integração nativa com Kubernetes via Datadog Operator
- Webhook direto para GitHub Actions (não precisa de intermediário)
- Monitor com query APM (`trace.http.request.hits`) nativa por status code
- Trial gratuito com APM completo

#### Por que Jira Ops (Atlassian) e não PagerDuty/OpsGenie?

- Integração nativa com o Datadog via `@jsm_ops-*`
- O time já utilizava Jira para gestão do projeto
- Incidentes abertos automaticamente com contexto completo do alerta

---

## CHECKLIST FINAL ANTES DA ENTREGA

### Código ✅
- [x] GitOps com OTel Collector, Grafana, Loki, Prometheus, Datadog
- [x] Todos os 5 serviços instrumentados com APM
- [x] Workflow de Self-Healing no GitHub Actions
- [x] Script `generate-5xx-errors.sh` funcional
- [x] Documentação completa (`DOCUMENTACAO.md` no GitOps)

### Evidências ⚠️
- [x] Print do alerta no Jira Ops
- [x] Print do Discord com Self-Healing
- [x] Print do GitHub Actions executando
- [x] Print do Datadog APM com 80% de erro
- [x] Print dos pods no Kubernetes após restart
- [x] **Print do dashboard Grafana** — `08-grafana-dashboard-visao-geral.png` e `09-grafana-dashboard-logs-loki-metricas.png`
- [x] **Print de trace distribuído no Datadog APM** — `10-datadog-apm-traces-lista.png` e `11-datadog-apm-trace-detalhe-auth-service.png`
- [x] **Print do Service Map Datadog** — `14-datadog-service-map-completo.png`

### Pendências antes de gravar o vídeo
1. ~~Tirar print do Grafana com dashboard aberto~~ ✅
2. ~~Tirar print de um trace distribuído no Datadog APM~~ ✅
3. Confirmar nomes, RMs e usernames do time
4. Definir link do vídeo
