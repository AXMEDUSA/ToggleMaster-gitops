#!/bin/bash
# Instalar ArgoCD via Helm no cluster AKS
# Executar: bash environments/prd/argocd/install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --version 7.8.28 \
  -f "$SCRIPT_DIR/values.yaml" \
  --wait --timeout 5m

echo "ArgoCD instalado com sucesso."
echo "Senha admin: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
