# ToggleMaster GitOps

Este repositório gerencia a infraestrutura declarativa e os deployments dos microserviços da plataforma **ToggleMaster**, utilizando GitOps com Kubernetes.

---

## 📦 Microserviços

A arquitetura é composta por 5 microserviços principais, cada um com seu próprio namespace e deployment:

| Serviço              | Namespace               | Porta | Função Principal                                  |
|----------------------|-------------------------|-------|---------------------------------------------------|
| `auth-service`       | `auth-service-prd`      | 8001  | Autenticação, login, tokens e controle de acesso |
| `flag-service`       | `flag-service-prd`      | 8002  | Gerenciamento de feature flags                    |
| `targeting-service`  | `targeting-service-prd` | 8003  | Segmentação de usuários e regras de targeting     |
| `evaluation-service` | `evaluation-service-prd`| 8004  | Avaliação de flags e entrega de decisões          |
| `analytics-service`  | `analytics-service-prd` | 8005  | Coleta e análise de métricas de uso               |

---

## 🚀 Estrutura do Repositório

```
auth-service-prd/ 
├── deployment.yaml 
└── acr-pull-secret.yaml

flag-service-prd/ 
├── deployment.yaml 
└── acr-pull-secret.yaml

targeting-service-prd/ 
├── deployment.yaml 
└── acr-pull-secret.yaml

evaluation-service-prd/ 
├── deployment.yaml 
└── acr-pull-secret.yaml

analytics-service-prd/ 
├── deployment.yaml 
└── acr-pull-secret.yaml
```
---

## 🔐 Acesso ao Azure Container Registry (ACR)

Todos os serviços utilizam o secret `acr-pull-secret` para autenticar no ACR privado `toggleacr.azurecr.io`.  
O secret é criado em cada namespace e referenciado nos deployments via `imagePullSecrets`.

---

## ⚙️ GitOps

Este repositório é sincronizado com o cluster Kubernetes via [ArgoCD](https://argo-cd.readthedocs.io/) ou [Flux](https://fluxcd.io/), garantindo que qualquer alteração nos manifests seja automaticamente aplicada no ambiente de produção.

---

## 📥 Deploy Manual (opcional)

Caso precise aplicar manualmente:

```bash
kubectl apply -f auth-service-prd/
kubectl apply -f flag-service-prd/
kubectl apply -f targeting-service-prd/
kubectl apply -f evaluation-service-prd/
kubectl apply -f analytics-service-prd/
