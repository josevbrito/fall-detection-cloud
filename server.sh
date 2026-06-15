#!/usr/bin/env bash
# server.sh — sobe o SERVIDOR (ThingsBoard + Postgres) e aguarda ficar pronto.
# Uso:
#   ./server.sh            # só ThingsBoard + Postgres
#   ./server.sh monitoring # + Grafana + Prometheus
set -e
cd "$(dirname "$0")"

[ -f .env ] || cp .env.example .env

# Garante o Docker no ar
if ! docker info >/dev/null 2>&1; then
  echo "Docker parado, iniciando..."
  sudo service docker start
  sleep 3
fi

PROFILE_ARGS=""
[ "$1" = "monitoring" ] && PROFILE_ARGS="--profile monitoring" && echo "Subindo COM monitoramento (Grafana/Prometheus)."

echo ">>> Subindo containers..."
docker compose $PROFILE_ARGS up -d

echo -n ">>> Aguardando ThingsBoard ficar pronto (até ~2min) "
for i in $(seq 1 30); do
  st=$(docker inspect -f '{{.State.Health.Status}}' thingsboard 2>/dev/null || echo "")
  [ "$st" = "healthy" ] && { echo " OK"; break; }
  echo -n "."
  sleep 5
done

WSL_IP=$(ip -4 addr show eth0 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)

echo
echo "==================================================================="
echo " SERVIDOR NO AR"
echo "   Dashboard (local):  http://localhost:8090"
[ "$1" = "monitoring" ] && echo "   Grafana (local):    http://localhost:3000"
echo "   IP do WSL2 atual:   ${WSL_IP:-?}"
echo
echo " Para outras máquinas alcançarem o servidor, rode no WINDOWS"
echo " (PowerShell como Administrador) o portproxy — o IP do WSL muda a"
echo " cada reboot, então o script abaixo detecta o IP sozinho:"
echo "     setup-portproxy.ps1"
echo "==================================================================="
