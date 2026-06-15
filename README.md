# fall-detection-cloud — Servidor (middleware)

Middleware da simulação distribuída de detecção de quedas: **ThingsBoard CE +
PostgreSQL** (+ Grafana/Prometheus opcional), tudo em Docker.

Roda na **Máquina A (servidor)**. A geração de carga fica no repositório
[`fall-detection-client`](../fall-detection-client), executado em **outra
máquina (Máquina B)**, que publica telemetria via MQTT pela rede.

```
Máquina A (este repo)                       Máquina B (fall-detection-client)
  docker compose up -d                        python scripts/load_test.py --devices 1000
  ThingsBoard :8090 (HTTP) / :1883 (MQTT)     TB_HOST = IP da Máquina A
        ▲──────────────── LAN / MQTT :1883 ──────────────────┘
```

---

## Pré-requisitos
- Docker + Docker Compose
- ~2 GB de RAM livres para o ThingsBoard

## Subir o servidor

```bash
cp .env.example .env       # ajuste as senhas
docker compose up -d       # ThingsBoard + Postgres

# acompanhar (pronto em ~90s): "Started Application in X seconds"
docker compose logs -f thingsboard
```

Com monitoramento (Grafana + Prometheus):
```bash
docker compose --profile monitoring up -d
# Grafana:    http://IP_DO_SERVIDOR:3000   (admin / senha do .env)
# Prometheus: http://IP_DO_SERVIDOR:9091
```

Dashboard do ThingsBoard: `http://IP_DO_SERVIDOR:8090`
Login inicial: `sysadmin@thingsboard.org` / `sysadmin` (depois entre como Tenant
Administrator — o `provision_devices.py` do cliente cria o tenant).

---

## Deixar acessível para a Máquina B (rede)

### Descobrir o IP do servidor
- **Linux nativo:** `hostname -I` → use o IP da LAN (ex: `192.168.0.42`).
- **Windows+WSL2:** no Windows, `ipconfig` → IPv4 do Wi‑Fi/Ethernet.

### Liberar firewall
- **Linux nativo:**
  ```bash
  sudo ufw allow 1883/tcp
  sudo ufw allow 8090/tcp
  # (se usar monitoramento) sudo ufw allow 3000/tcp
  ```
- **Windows+WSL2:** o Docker roda dentro do WSL2 (rede própria). Para a Máquina B
  alcançar, encaminhe as portas no **PowerShell como Administrador**:
  ```powershell
  # IP_DO_WSL: no WSL rode `hostname -I`
  netsh interface portproxy add v4tov4 listenport=1883 listenaddress=0.0.0.0 connectport=1883 connectaddress=IP_DO_WSL
  netsh interface portproxy add v4tov4 listenport=8090 listenaddress=0.0.0.0 connectport=8090 connectaddress=IP_DO_WSL
  netsh advfirewall firewall add rule name="TB MQTT 1883" dir=in action=allow protocol=TCP localport=1883
  netsh advfirewall firewall add rule name="TB HTTP 8090" dir=in action=allow protocol=TCP localport=8090
  ```
  > O IP do WSL2 muda ao reiniciar. Se parar de funcionar, rode de novo
  > (`netsh interface portproxy reset` limpa as regras antigas).
  >
  > **Dica:** se tiver uma máquina Linux nativo, use-a como servidor — evita
  > toda essa configuração de WSL2.

### Testar (da Máquina B)
```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://IP_DO_SERVIDOR:8090/api/auth/login -X POST -H 'Content-Type: application/json' -d '{}'
# 401 = alcançou o servidor (ok). timeout/refused = firewall/portproxy.
```

---

## (Opcional) Modo público com domínio + TLS

Para hospedar numa VM pública (DigitalOcean/Azure/etc.) com domínio próprio e
HTTPS automático, use o `docker-compose.public.yml` (Caddy + Let's Encrypt):

```bash
# requer A record do domínio -> IP da VM e portas 80/443 abertas
TB_DOMAIN=iot.seudominio.com docker compose -f docker-compose.public.yml up -d
```

---

## Operação

```bash
docker compose ps
docker compose logs -f thingsboard
docker compose down        # para (mantém dados nos volumes)
docker compose down -v     # para e APAGA os dados
```
