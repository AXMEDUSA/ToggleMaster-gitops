#!/bin/bash

# Gera erros HTTP 500 reais no auth-service via endpoint /simulate-error.
# Habilita e desabilita ENABLE_ERROR_SIMULATION automaticamente.

POD_NAME="error-generator"
NAMESPACE="auth-service-prd"
DEPLOYMENT="auth-service"
DURATION=${1:-300}  # duração em segundos (padrão: 5 minutos)
CONCURRENCY=5

AUTH_URL="http://auth-service.auth-service-prd.svc.cluster.local:80"

echo ""
echo "======================================"
echo "  Auth Service — Error Generator 5xx"
echo "======================================"
echo ""

# ── Cleanup ao sair (Ctrl+C ou erro) ─────────────────────────────────────────
cleanup() {
  echo ""
  echo "[!] Desabilitando simulação de erro..."
  kubectl set env deployment/"$DEPLOYMENT" -n "$NAMESPACE" \
    ENABLE_ERROR_SIMULATION- 2>/dev/null
  kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE" --timeout=60s 2>/dev/null
  echo "    Limpando pod de carga..."
  kubectl delete pod "$POD_NAME" -n "$NAMESPACE" --grace-period=0 --ignore-not-found 2>/dev/null
  echo "  Pronto. Serviço restaurado ao normal."
}
trap cleanup EXIT

# ── [1] Habilitar simulação ───────────────────────────────────────────────────
echo "[1/3] Habilitando ENABLE_ERROR_SIMULATION no deployment..."
kubectl set env deployment/"$DEPLOYMENT" -n "$NAMESPACE" \
  ENABLE_ERROR_SIMULATION=true 2>/dev/null
kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE" --timeout=90s 2>/dev/null
echo "      Pronto!"

# ── [2] Pod de carga ──────────────────────────────────────────────────────────
echo ""
echo "[2/3] Preparando pod de carga..."
kubectl delete pod "$POD_NAME" -n "$NAMESPACE" --ignore-not-found --grace-period=0 2>/dev/null
kubectl run "$POD_NAME" \
  --image=python:3.11-alpine \
  --restart=Never \
  --namespace="$NAMESPACE" \
  --command -- sh -c "sleep 600" 2>/dev/null
kubectl wait pod "$POD_NAME" -n "$NAMESPACE" --for=condition=Ready --timeout=60s 2>/dev/null
echo "      Pod pronto!"

# ── [3] Gerar erros 5xx em loop contínuo ─────────────────────────────────────
echo ""
echo "[3/3] Gerando erros contínuos por ${DURATION}s (80% HTTP 500 / 20% HTTP 200)..."
echo "      - /simulate-error → 500"
echo "      - /health         → 200"
echo ""

PYTHON_SCRIPT=$(cat <<PYEOF
import urllib.request, urllib.error, time, sys
from concurrent.futures import ThreadPoolExecutor

AUTH_URL    = "${AUTH_URL}"
DURATION    = ${DURATION}
CONCURRENCY = ${CONCURRENCY}

ok = 0; erros = 0
start = time.time()
ciclo = 0

def do_req(url):
    try:
        req = urllib.request.Request(url, method="GET")
        resp = urllib.request.urlopen(req, timeout=5)
        return resp.status
    except urllib.error.HTTPError as e:
        return e.code
    except:
        return 0

print(f"  Rodando por {DURATION}s — Ctrl+C para parar antes.", flush=True)

with ThreadPoolExecutor(max_workers=CONCURRENCY) as ex:
    while time.time() - start < DURATION:
        ciclo += 1
        urls = [
            AUTH_URL + "/simulate-error",
            AUTH_URL + "/simulate-error",
            AUTH_URL + "/simulate-error",
            AUTH_URL + "/simulate-error",
            AUTH_URL + "/health",
        ]
        results = list(ex.map(do_req, urls))
        for code in results:
            if code == 200: ok += 1
            else: erros += 1
        elapsed = int(time.time() - start)
        total = ok + erros
        taxa = (erros / total * 100) if total else 0
        print(f"  [{elapsed:3d}s] ciclo {ciclo:4d} — {erros} erros / {total} total — {taxa:.0f}% erro", flush=True)
        time.sleep(0.5)

total = ok + erros
taxa = (erros / total * 100) if total else 0
print(f"\n  Resumo: {ok} OK  |  {erros} erros  |  {total} total  |  {taxa:.1f}% de erros")
PYEOF
)

kubectl exec "$POD_NAME" -n "$NAMESPACE" -- python3 -c "$PYTHON_SCRIPT"

echo ""
echo "======================================"
echo "  Monitor: https://app.datadoghq.com/monitors/282578515"
echo "======================================"
echo ""
# cleanup roda via trap EXIT
