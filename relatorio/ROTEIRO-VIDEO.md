# Roteiro do Vídeo — Fase 4 Tech Challenge FIAP
## ToggleMaster — Observabilidade e Self-Healing

**Duração total estimada: 20–25 minutos**  
**Resolução recomendada:** 1920×1080  
**Ferramentas abertas antes de começar:** terminal, Chrome (Datadog, GitHub, Discord, Jira)

---

## Antes de gravar — checklist de preparo

```bash
# 1. Verificar que o cluster está healthy
kubectl get nodes
kubectl get pods -A | grep -v Running  # deve retornar só Completed ou vazio

# 2. Verificar que o monitor está em OK (obrigatório!)
curl -s -H "DD-API-KEY: $DD_API_KEY" -H "DD-APPLICATION-KEY: $DD_APP_KEY" "https://api.datadoghq.com/api/v1/monitor/282578515" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['overall_state'])"

# 3. Abrir port-forward do Grafana em background
kubectl port-forward svc/grafana -n observability 3000:80 &

# 4. Deixar aberto em abas separadas:
#    - https://app.datadoghq.com/apm/services?env=production
#    - https://app.datadoghq.com/monitors/282578515
#    - https://github.com/AXMEDUSA/ToggleMaster-gitops/actions
#    - Grafana: http://localhost:3000
#    - Discord (canal de alertas)
#    - Jira Ops (dashboard de incidentes)
```

---

## PARTE 1 — Apresentação do Projeto (3 min)

### Fala sugerida:
*"Bom dia / Boa tarde. Somos o grupo [X] e vamos apresentar a Fase 4 do Tech Challenge. Desenvolvemos o ToggleMaster, uma plataforma de feature flags com 5 microsserviços em Go e Python, rodando em Kubernetes na Azure. Nesta fase, implementamos observabilidade completa e um sistema de auto-recuperação que detecta falhas e reinicia serviços automaticamente."*

### O que mostrar na tela:

**1.1 — Cluster Kubernetes funcionando**
```bash
kubectl get nodes
# Mostrar os 2 nodes Ready

kubectl get pods -A
# Mostrar todos os pods dos 5 serviços + stack de monitoramento
```

**1.2 — ArgoCD com os serviços sincronizados**
- Abrir ArgoCD no browser
- Mostrar os apps: auth-service, flag-service, targeting-service, evaluation-service, analytics-service
- Todos devem estar verdes (Synced + Healthy)

**1.3 — Os dois repositórios no GitHub**
- Abrir `https://github.com/AXMEDUSA/ToggleMaster-AppRepo` — mostrar os 5 serviços
- Abrir `https://github.com/AXMEDUSA/ToggleMaster-gitops` — mostrar a estrutura de environments/

---

## PARTE 2 — Métricas, Logs e OTel (5 min)

### Fala sugerida:
*"Toda a telemetria dos serviços passa pelo OTel Collector, que age como roteador: recebe dados das aplicações via protocolo OTLP e distribui simultaneamente para o Datadog e para o Grafana. Vou mostrar o Grafana agora."*

### O que mostrar na tela:

**2.1 — Grafana Dashboard**
- Abrir `http://localhost:3000`
- Mostrar o dashboard customizado:
  - Gauges de status dos serviços (UP/DOWN)
  - Gráficos de CPU e memória por pod
  - Taxa de requisições e latência por serviço
- *"Aqui vemos todas as métricas coletadas pelo Prometheus através do OTel Collector."*

**2.2 — Logs no Loki**
- Dentro do Grafana, ir em Explore → selecionar Loki
- Fazer a query: `{namespace=~"auth-service-prd|flag-service-prd"}`
- Mostrar os logs chegando em tempo real
- *"O Promtail coleta os logs de todos os pods e envia para o Loki. Aqui conseguimos buscar por serviço, pod, ou qualquer campo dos logs."*

**2.3 — OTel Collector no cluster**
```bash
kubectl get pods -n observability
# Mostrar: otel-collector, grafana, loki, prometheus, promtail — todos Running
```

---

## PARTE 3 — APM e Traces Distribuídos (5 min)

### Fala sugerida:
*"Além do Grafana, os serviços também enviam traces para o Datadog via dd-trace-go e ddtrace. O Datadog APM permite rastrear uma requisição do início ao fim, passando por múltiplos microsserviços."*

### O que mostrar na tela:

**3.1 — Service Map**
- Abrir `https://app.datadoghq.com/software?env=production&fromUser=true&view=map`
- Mostrar o mapa com os 5 serviços conectados
- *"Aqui vemos o Service Map — cada nó é um serviço, e as arestas mostram as chamadas entre eles."*

**3.2 — Lista de serviços APM**
- Abrir `https://app.datadoghq.com/apm/services?env=production`
- Mostrar os 5 serviços com métricas de latência, throughput e taxa de erro

**3.3 — Lista de traces**
- Abrir `https://app.datadoghq.com/apm/traces?query=service%3Aauth-service&env=production`
- Clicar em um trace para abrir o detalhe
- *"Cada trace representa uma requisição completa. Aqui vemos as spans — cada operação dentro da requisição — com tempo de duração, status e metadados."*

**3.4 — Fazer uma requisição ao vivo (opcional)**
```bash
# Gerar uma requisição real ao auth-service
kubectl run -it --rm test-req --image=curlimages/curl --restart=Never -n auth-service-prd -- curl -s http://auth-service:8001/health
```
- Mostrar o trace aparecendo no Datadog em tempo real

---

## PARTE 4 — Self-Healing: A Prova Real (10 min)

> **Este é o item mais importante do vídeo. Gravar com calma.**

### Fala sugerida:
*"Agora vamos demonstrar o Self-Healing. O monitor do Datadog observa continuamente a taxa de erros do auth-service. Quando ultrapassa 5% de HTTP 500, ele dispara um webhook que aciona o GitHub Actions automaticamente para reiniciar os pods — sem nenhuma intervenção humana."*

### O que mostrar na tela:

**4.1 — Monitor em estado OK**
- Abrir `https://app.datadoghq.com/monitors/282578515`
- Mostrar que está verde (OK)
- Mostrar a configuração: query, threshold (5%), janela (last 1m), webhook configurado
- *"O monitor está OK. Isso é importante: o fluxo de Self-Healing só dispara na transição OK → Alert."*

**4.2 — Rodar o script de simulação**
```bash
bash generate-5xx-errors.sh 100
```
- Manter o terminal visível enquanto o script roda
- O script vai mostrar: `[ciclo 1/100] → 500 → 500 → 500 → 500 → 200`

**4.3 — Mostrar a taxa de erro subindo no Datadog**
- Manter `https://app.datadoghq.com/monitors/282578515` aberto e dar refresh
- *"Vemos a taxa de erros HTTP 500 subindo. O gráfico vai mostrar ~80% de erros — 4 em cada 5 requisições retornam 500."*

**4.4 — Monitor muda para Alert**
- Aguardar ~1 minuto
- O monitor muda de verde para vermelho (Alert)
- *"O monitor acabou de mudar para Alert. Isso dispara automaticamente o webhook para o GitHub."*

**4.5 — GitHub Actions sendo acionado**
- Abrir `https://github.com/AXMEDUSA/ToggleMaster-gitops/actions`
- Mostrar o workflow `self-healing-auth-service` sendo disparado (aparece em segundos)
- Clicar no workflow para ver os steps executando
- *"Em menos de 5 segundos o GitHub Actions já foi acionado. Ele está executando o kubectl rollout restart."*

**4.6 — Pods reiniciando no Kubernetes**
```bash
kubectl get pods -n auth-service-prd -w
```
- Mostrar os pods terminando e novos subindo
- *"Os pods antigos estão sendo substituídos. Em alguns segundos teremos os pods novos no estado Running."*

**4.7 — Discord recebe a notificação**
- Mostrar o Discord com o embed de confirmação
- *"Automaticamente o GitHub Actions enviou uma notificação para o Discord confirmando que o Self-Healing foi concluído com sucesso."*

**4.8 — Jira Ops com incidente criado**
- Abrir o Jira Ops / JSM
- Mostrar o incidente criado automaticamente com os detalhes do alerta
- *"Simultaneamente, um incidente foi aberto no Jira Ops com o contexto completo do alerta — serviço afetado, horário, e o que foi feito."*

**4.9 — Monitor volta para OK**
- Voltar ao `https://app.datadoghq.com/monitors/282578515`
- Após ~1 minuto dos pods novos rodando, o monitor volta para verde
- *"O monitor retornou ao estado OK. O ciclo completo — detecção, resposta e recuperação — aconteceu em menos de 3 minutos, totalmente automático."*

---

## PARTE 5 — Encerramento (2 min)

### Fala sugerida:
*"Para resumir o que implementamos:"*

- ✅ **5 microsserviços instrumentados** com Datadog APM e OTel
- ✅ **Stack de observabilidade** com Grafana, Loki, Prometheus e Datadog
- ✅ **Pipeline CI/CD** com lint, SAST, Trivy, build e GitOps via ArgoCD
- ✅ **Self-Healing validado em produção** — detecção a recuperação em < 3 minutos
- ✅ **Notificações automáticas** via Discord e Jira Ops

*"Obrigado. Os repositórios e toda a documentação estão nos links na descrição do vídeo."*

---

## Comandos rápidos de referência (durante a gravação)

```bash
# Status geral do cluster
kubectl get pods -A

# Status do monitor Datadog
curl -s -H "DD-API-KEY: $DD_API_KEY" -H "DD-APPLICATION-KEY: $DD_APP_KEY" "https://api.datadoghq.com/api/v1/monitor/282578515" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['overall_state'])"

# Rodar o script de Self-Healing
bash generate-5xx-errors.sh 100

# Monitorar os pods reiniciando
kubectl get pods -n auth-service-prd -w

# Port-forward Grafana
kubectl port-forward svc/grafana -n observability 3000:80

# Port-forward ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

---

## Links do vídeo (abrir antes de gravar)

| Seção | URL |
|---|---|
| APM Services | https://app.datadoghq.com/apm/services?env=production |
| Service Map | https://app.datadoghq.com/software?env=production&fromUser=true&view=map |
| APM Traces (auth-service) | https://app.datadoghq.com/apm/traces?query=service%3Aauth-service&env=production |
| Monitor Self-Healing | https://app.datadoghq.com/monitors/282578515 |
| GitHub Actions | https://github.com/AXMEDUSA/ToggleMaster-gitops/actions |
| AppRepo | https://github.com/AXMEDUSA/ToggleMaster-AppRepo |
| GitOps Repo | https://github.com/AXMEDUSA/ToggleMaster-gitops |
| Grafana | http://localhost:3000 |

---

## Dicas de gravação

- **Fonte do terminal:** aumentar para 16–18pt para ficar legível no vídeo
- **Resolução:** gravar em 1080p, mínimo
- **Organize as abas antes de começar** usando a tabela de links acima
- **Parte 4 é crítica:** não cortar a gravação enquanto o monitor muda de OK → Alert → OK
- **Se o monitor estiver em Alert quando for gravar:** aguardar voltar para OK antes de iniciar a Parte 4 (pode levar 1–5 minutos)
- **Mostre os repositórios com orgulho:** são 2 repos bem estruturados com CI/CD completo
