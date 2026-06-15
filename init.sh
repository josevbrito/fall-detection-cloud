#!/usr/bin/env bash
# init.sh — setup inicial do SERVIDOR (rodar uma vez).
# Prepara o .env, garante o Docker no ar e baixa as imagens.
set -e
cd "$(dirname "$0")"

echo ">>> [1/3] Verificando .env..."
if [ ! -f .env ]; then
  cp .env.example .env
  echo "    .env criado a partir do exemplo — revise as senhas se quiser."
else
  echo "    .env já existe."
fi

echo ">>> [2/3] Verificando Docker..."
if ! docker info >/dev/null 2>&1; then
  echo "    Docker não está rodando. Iniciando (pode pedir a senha)..."
  sudo service docker start
  sleep 3
fi
docker info >/dev/null 2>&1 && echo "    Docker OK." || { echo "    ERRO: Docker não subiu."; exit 1; }

echo ">>> [3/3] Baixando imagens (demora só na primeira vez)..."
docker compose pull

echo
echo "Init do servidor concluído. Agora rode:  ./server.sh"
