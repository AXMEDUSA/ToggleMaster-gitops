#!/bin/bash

# Gera erros HTTP 500 reais no auth-service via endpoint /simulate-error.
# Habilita e desabilita ENABLE_ERROR_SIMULATION automaticamente.

POD_NAME="error-generator"
NAMESPACE="auth-service-prd"
DEPLOYMENT="auth-service"
TOTAL=${1:-100}
CONCURRENCY=20

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

# ── [3] Gerar erros 5xx ───────────────────────────────────────────────────────
echo ""
echo "[3/3] Gerando $TOTAL ciclos (80% HTTP 500 / 20% HTTP 200)..."
echo "      - /simulate-error → 500 x4 por ciclo"
echo "      - /health         → 200 x1 por ciclo"
echo ""

PYTHON_SCRIPT=$(cat <<PYEOF
import urllib.request, urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed

AUTH_URL    = "${AUTH_URL}"
TOTAL       = ${TOTAL}
CONCURRENCY = ${CONCURRENCY}

requests_to_make = []
for i in range(1, TOTAL + 1):
    requests_to_make += [
        ("error-500-1", AUTH_URL + "/simulate-error", {}, "GET", None),
        ("error-500-2", AUTH_URL + "/simulate-error", {}, "GET", None),
        ("error-500-3", AUTH_URL + "/simulate-error", {}, "GET", None),
        ("error-500-4", AUTH_URL + "/simulate-error", {}, "GET", None),
        ("health-ok",   AUTH_URL + "/health",          {}, "GET", None),
    ]

ok = 0; erros = 0

def do_req(label, url, headers, method, body):
    try:
        req = urllib.request.Request(url, data=body, headers=headers, method=method)
        resp = urllib.request.urlopen(req, timeout=5)
        return f"  {label:<14} HTTP {resp.status}  OK"
    except urllib.error.HTTPError as e:
        return f"  {label:<14} HTTP {e.code}  ERRO"
    except Exception as e:
        return f"  {label:<14} FALHA — {e}"

with ThreadPoolExecutor(max_workers=CONCURRENCY) as ex:
    futures = [ex.submit(do_req, *args) for args in requests_to_make]
    for f in as_completed(futures):
        result = f.result()
        print(result, flush=True)
        if "OK" in result: ok += 1
        else: erros += 1

total = ok + erros
taxa = (erros / total * 100) if total else 0
print(f"\n  Resumo: {ok} OK  |  {erros} erros  |  {total} total  |  {taxa:.1f}% de erros")
print(f"  Aguardar ~5min para o monitor Datadog disparar e o self-healing agir.")
PYEOF
)

kubectl exec "$POD_NAME" -n "$NAMESPACE" -- python3 -c "$PYTHON_SCRIPT"

echo ""
echo "======================================"
echo "  Verifique em 2-5 min:"
echo "  https://app.datadoghq.com/monitors/282578515"
echo "======================================"
echo ""
echo "[!] Aguardando 5 minutos para o monitor Datadog avaliar a janela de erros..."
sleep 300
# cleanup roda via trap EXIT
