# setup-portproxy.ps1
# -------------------
# Reaplica o port forwarding Windows -> WSL2 para o ThingsBoard, detectando o
# IP atual do WSL2 automaticamente. Necessário a cada reboot (o IP do WSL muda).
#
# COMO RODAR (PowerShell como ADMINISTRADOR):
#   Set-ExecutionPolicy -Scope Process Bypass -Force
#   & "\\wsl.localhost\OracleLinux_9_5\home\josevbrito\projects\universidade\graduacao\distributed-systems\fall-detection-cloud\setup-portproxy.ps1"
#
# (Ajuste o nome da distro se mudar — veja com `wsl -l` no Windows.)
# Mais simples: copie este arquivo para uma pasta no Windows e rode de lá.

# Nome da distro WSL (ajuste se necessário)
$distro = "OracleLinux_9_5"

# Detecta o IP do WSL2 (eth0)
$wslIp = (wsl -d $distro -- ip -4 -o addr show eth0 |
    Select-String -Pattern 'inet (\d+\.\d+\.\d+\.\d+)').Matches[0].Groups[1].Value

if (-not $wslIp) {
    Write-Error "Nao consegui obter o IP do WSL2. O WSL esta rodando?"
    exit 1
}
Write-Host "IP do WSL2 detectado: $wslIp"

# Limpa regras antigas e recria com o IP atual
netsh interface portproxy reset
netsh interface portproxy add v4tov4 listenport=1883 listenaddress=0.0.0.0 connectport=1883 connectaddress=$wslIp
netsh interface portproxy add v4tov4 listenport=8090 listenaddress=0.0.0.0 connectport=8090 connectaddress=$wslIp

# Regras de firewall (idempotente: remove antes de adicionar)
netsh advfirewall firewall delete rule name="TB MQTT 1883" | Out-Null
netsh advfirewall firewall delete rule name="TB HTTP 8090" | Out-Null
netsh advfirewall firewall add rule name="TB MQTT 1883" dir=in action=allow protocol=TCP localport=1883
netsh advfirewall firewall add rule name="TB HTTP 8090" dir=in action=allow protocol=TCP localport=8090

Write-Host ""
Write-Host "Portproxy aplicado para o WSL2 ($wslIp):"
netsh interface portproxy show v4tov4
