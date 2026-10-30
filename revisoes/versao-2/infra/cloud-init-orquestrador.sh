#!/bin/bash
# Projeto Orquestrador - cloud-init v2 (Ubuntu 24.04 ARM, OCI Always Free)
#
# Instala Docker + n8n + Caddy (HTTPS automatico via Let's Encrypt) e endurece o SSH.
#
# Garantias desta versao:
#  * IDEMPOTENTE: pode rodar de novo sem trocar a N8N_ENCRYPTION_KEY. Se existir volume do n8n
#    sem a chave no .env, o script ABORTA (gerar outra chave deixaria as credenciais ilegiveis).
#  * SEM CADASTRO ABERTO: ate voce rodar `finish-setup.sh`, tudo (exceto /webhook/*) fica atras de
#    uma senha de bootstrap gerada NO SERVIDOR (basic auth no Caddy). Assim ninguem na internet
#    consegue ser o primeiro a criar o owner do n8n.
#  * Nenhum segredo vai para este arquivo, para o log ou para o chat. A senha de bootstrap fica em
#    /opt/orquestrador/state/bootstrap-password.txt (modo 600, somente root).
#
# Variavel de teste: ORQ_ROOT_PREFIX (prefixo de caminhos; vazio em producao).
set -euo pipefail
umask 022
export DEBIAN_FRONTEND=noninteractive
PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin"

ROOT="${ORQ_ROOT_PREFIX:-}"
APP_DIR="${ROOT}/opt/orquestrador"
STATE="${APP_DIR}/state"
LOG="${ROOT}/var/log/orquestrador-init.log"
LOCK="${ROOT}/var/lock/orquestrador-init.lock"
ENV_FILE="${APP_DIR}/.env"
CADDYFILE="${APP_DIR}/Caddyfile"
VOLUME_NAME="orquestrador_n8n_data"

mkdir -p "$(dirname "$LOG")" "$(dirname "$LOCK")"
exec >>"$LOG" 2>&1
trap 'echo "ERRO: falhou na linha $LINENO (codigo $?)" >&2' ERR

# Execucao unica por vez (cloud-init + execucao manual ao mesmo tempo corromperiam o estado).
exec 9>"$LOCK"
if ! flock -n 9; then
  echo "ERRO: outra execucao do script esta em andamento." >&2
  exit 1
fi

echo "== $(date -Is) inicio (v2)"

fail() { echo "ERRO: $*" >&2; exit 1; }

write_secret() { # $1 = destino; conteudo via stdin; modo 600; troca atomica
  local dest="$1" tmp
  tmp="$(umask 077; mktemp "${dest}.XXXXXX")"
  cat > "$tmp"
  chmod 600 "$tmp"
  mv -f "$tmp" "$dest"
}

valid_ipv4() {
  [[ "$1" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]] || return 1
  local o
  for o in "${BASH_REMATCH[@]:1}"; do
    [ "$o" -le 255 ] || return 1
  done
}

detect_public_ip() {
  local ip url
  ip="$(curl -fsS --max-time 5 -H 'Authorization: Bearer Oracle' \
        http://169.254.169.254/opc/v2/vnics/ 2>/dev/null | jq -r '.[0].publicIp // empty' 2>/dev/null || true)"
  if valid_ipv4 "$ip"; then echo "$ip"; return 0; fi
  for url in https://api.ipify.org https://icanhazip.com https://ifconfig.me/ip; do
    ip="$(curl -fsS --max-time 8 --retry 2 "$url" 2>/dev/null | tr -d '[:space:]' || true)"
    if valid_ipv4 "$ip"; then echo "$ip"; return 0; fi
  done
  return 1
}

render_caddyfile() { # $1 = gated|open ; $2 = hash bcrypt (so para gated)
  local mode="$1" hash="${2:-}"
  echo '{$N8N_HOST} {'
  echo '  encode gzip'
  if [ "$mode" = "gated" ]; then
    echo '  @gated {'
    echo '    not path /webhook/*'
    echo '  }'
    echo '  basic_auth @gated {'
    echo "    setup ${hash}"
    echo '  }'
  fi
  echo '  reverse_proxy n8n:5678'
  echo '}'
}

is_bcrypt() { [[ "${1:-}" =~ ^\$2[abxy]\$[0-9]{2}\$.{53}$ ]]; }

reload_caddy() {
  local i
  for i in 1 2 3 4 5; do
    if docker compose exec -T caddy caddy validate --config /etc/caddy/Caddyfile >/dev/null 2>&1 \
       && docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile --force >/dev/null 2>&1; then
      return 0
    fi
    sleep "${ORQ_RETRY_SLEEP:-2}"
  done
  return 1
}

# ---------------------------------------------------------------- [1/7] pacotes
echo "== [1/7] Pacotes base"
apt-get update
apt-get install -y --no-upgrade ca-certificates curl gnupg jq fail2ban unattended-upgrades iptables-persistent openssl util-linux

# ---------------------------------------------------------------- [2/7] Docker
echo "== [2/7] Docker (repo oficial)"
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  echo "Docker ja instalado; mantendo."
else
  install -m 0755 -d "${ROOT}/etc/apt/keyrings"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "${ROOT}/etc/apt/keyrings/docker.asc"
  chmod a+r "${ROOT}/etc/apt/keyrings/docker.asc"
  mkdir -p "${ROOT}/etc/apt/sources.list.d"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" \
    > "${ROOT}/etc/apt/sources.list.d/docker.list"
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
systemctl enable --now docker
usermod -aG docker ubuntu || true

# ---------------------------------------------------------------- [3/7] SSH + fail2ban
echo "== [3/7] SSH somente por chave + fail2ban"
SSHD_DROPIN="${ROOT}/etc/ssh/sshd_config.d/99-hardening.conf"
AUTH_KEYS="${ROOT}/home/ubuntu/.ssh/authorized_keys"
mkdir -p "$(dirname "$SSHD_DROPIN")"
if [ -s "$AUTH_KEYS" ]; then
  cat > "$SSHD_DROPIN" <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
MaxAuthTries 3
EOF
  if sshd -t; then
    systemctl reload ssh || systemctl reload sshd || true
  else
    rm -f "$SSHD_DROPIN"
    echo "AVISO: sshd -t reprovou a configuracao; endurecimento SSH NAO aplicado." >&2
  fi
else
  rm -f "$SSHD_DROPIN"
  echo "AVISO: usuario ubuntu sem authorized_keys; login por senha NAO foi desativado (evita ficar sem acesso)." >&2
fi
mkdir -p "${ROOT}/etc/fail2ban/jail.d"
cat > "${ROOT}/etc/fail2ban/jail.d/sshd.local" <<'EOF'
[sshd]
enabled = true
maxretry = 4
findtime = 10m
bantime = 1h
EOF
systemctl enable --now fail2ban

# ---------------------------------------------------------------- [4/7] firewall do SO
echo "== [4/7] Firewall do SO: liberar 80/443 antes do primeiro REJECT/DROP"
fw_open() { # $1 = porta
  local port="$1" pos
  if iptables -C INPUT -p tcp --dport "$port" -m conntrack --ctstate NEW -j ACCEPT 2>/dev/null; then
    return 0
  fi
  pos="$(iptables -L INPUT --line-numbers -n | awk '$2=="REJECT" || $2=="DROP" {print $1; exit}')"
  iptables -I INPUT "${pos:-1}" -p tcp --dport "$port" -m conntrack --ctstate NEW -j ACCEPT
}
fw_open 80
fw_open 443
if command -v netfilter-persistent >/dev/null 2>&1; then
  netfilter-persistent save
fi

# ---------------------------------------------------------------- [5/7] estado, chave, host
echo "== [5/7] Estado: chave de criptografia, host e senha de bootstrap"
mkdir -p "$APP_DIR"
(umask 077; mkdir -p "$STATE")
chmod 700 "$STATE"

OLD_KEY=""; OLD_HOST=""
if [ -f "$ENV_FILE" ]; then
  OLD_KEY="$(sed -n 's/^N8N_ENCRYPTION_KEY=//p' "$ENV_FILE" | head -n1)"
  OLD_HOST="$(sed -n 's/^N8N_HOST=//p' "$ENV_FILE" | head -n1)"
fi

if [ -n "$OLD_KEY" ]; then
  [[ "$OLD_KEY" =~ ^[A-Za-z0-9+/=_-]{16,}$ ]] || fail "N8N_ENCRYPTION_KEY em ${ENV_FILE} tem formato invalido; nada foi alterado."
  ENC_KEY="$OLD_KEY"
  echo "Chave de criptografia existente preservada."
else
  if docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
    fail "o volume ${VOLUME_NAME} ja existe, mas ${ENV_FILE} nao tem N8N_ENCRYPTION_KEY. Restaure o .env do backup; gerar outra chave tornaria as credenciais salvas ilegiveis. Nada foi alterado."
  fi
  ENC_KEY="$(openssl rand -hex 32)"
  echo "Chave de criptografia nova gerada (primeira execucao)."
fi

if PUBLIC_IP="$(detect_public_ip)"; then
  N8N_HOST="$(echo "$PUBLIC_IP" | tr '.' '-').sslip.io"
elif [ -n "$OLD_HOST" ]; then
  N8N_HOST="$OLD_HOST"
  echo "AVISO: nao foi possivel detectar o IP publico; mantendo host anterior ${OLD_HOST}." >&2
else
  fail "nao foi possivel detectar o IP publico e nao ha host anterior."
fi
[[ "$N8N_HOST" =~ ^[0-9]{1,3}(-[0-9]{1,3}){3}\.sslip\.io$ ]] || fail "host invalido: ${N8N_HOST}"
if [ -n "$OLD_HOST" ] && [ "$OLD_HOST" != "$N8N_HOST" ]; then
  echo "AVISO: host mudou de ${OLD_HOST} para ${N8N_HOST}; reative o workflow do Telegram para registrar o novo webhook." >&2
fi

printf 'N8N_HOST=%s\nN8N_ENCRYPTION_KEY=%s\n' "$N8N_HOST" "$ENC_KEY" | write_secret "$ENV_FILE"

# Porta de entrada: gate de bootstrap enquanto o setup nao foi concluido.
GATE_HASH=""
if [ -e "${STATE}/setup-complete" ]; then
  echo "Setup ja concluido: sem gate."
  CADDY_MODE="open"
else
  CADDY_MODE="gated"
  if [ -f "${STATE}/gate.hash" ]; then GATE_HASH="$(head -n1 "${STATE}/gate.hash")"; fi
  if ! is_bcrypt "$GATE_HASH"; then
    BOOT_PW="$(openssl rand -hex 12)"
    GATE_HASH="$(docker run --rm caddy:2 caddy hash-password --plaintext "$BOOT_PW" | tr -d '\r\n')"
    # Falha FECHADA: sem hash valido nao publicamos nada.
    is_bcrypt "$GATE_HASH" || fail "nao foi possivel gerar o hash da senha de bootstrap; nada foi publicado."
    printf '%s\n' "$BOOT_PW" | write_secret "${STATE}/bootstrap-password.txt"
    printf '%s\n' "$GATE_HASH" | write_secret "${STATE}/gate.hash"
    unset BOOT_PW
    echo "Senha de bootstrap gerada em ${STATE}/bootstrap-password.txt (nao registrada no log)."
  else
    echo "Gate de bootstrap existente reaproveitado."
  fi
fi

# ---------------------------------------------------------------- [6/7] compose + Caddyfile
echo "== [6/7] n8n + Caddy"
# Escritos 'no lugar' (mesmo inode): o Caddyfile e montado como arquivo unico no conteiner.
render_caddyfile open > "${STATE}/Caddyfile.open"
chmod 600 "${STATE}/Caddyfile.open"
render_caddyfile "$CADDY_MODE" "$GATE_HASH" > "$CADDYFILE"
chmod 600 "$CADDYFILE"

cat > "${APP_DIR}/docker-compose.yml" <<'EOF'
name: orquestrador

services:
  caddy:
    image: caddy:2
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      - N8N_HOST=${N8N_HOST}
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - n8n

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    restart: unless-stopped
    environment:
      - N8N_HOST=${N8N_HOST}
      - N8N_PROTOCOL=https
      - N8N_PORT=5678
      - WEBHOOK_URL=https://${N8N_HOST}/
      - N8N_PROXY_HOPS=1
      - N8N_SECURE_COOKIE=true
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - TZ=America/Sao_Paulo
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_VERSION_NOTIFICATIONS_ENABLED=false
      - N8N_PERSONALIZATION_ENABLED=false
      - N8N_BLOCK_ENV_ACCESS_IN_NODE=true
      # Execucoes de producao uma por vez: evita corrida nos dados do workflow (tarefas do Telegram).
      - N8N_CONCURRENCY_PRODUCTION_LIMIT=1
    volumes:
      - n8n_data:/home/node/.n8n

volumes:
  caddy_data:
  caddy_config:
  n8n_data:
EOF

cd "$APP_DIR"
docker compose up -d   # baixa imagens que faltam; NAO atualiza imagens ja existentes
reload_caddy || fail "Caddy nao aceitou a configuracao (validate/reload)."

# ---------------------------------------------------------------- finish-setup.sh
cat > "${APP_DIR}/finish-setup.sh" <<'FINISH_EOF'
#!/bin/bash
# Remove a senha de bootstrap do Caddy DEPOIS que o owner do n8n foi criado.
# Uso: sudo /opt/orquestrador/finish-setup.sh [--yes] [--skip-check]
#   --yes         nao pergunta confirmacao
#   --skip-check  so use se a checagem automatica nao puder rodar E voce ja confirmou, na tela
#                 do n8n, que a conta de proprietario existe.
set -euo pipefail
PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin"
APP_DIR="@APP_DIR@"
STATE="${APP_DIR}/state"
CADDYFILE="${APP_DIR}/Caddyfile"
YES=0; SKIP=0
for a in "$@"; do
  case "$a" in
    --yes) YES=1 ;;
    --skip-check) SKIP=1 ;;
    *) echo "Opcao desconhecida: $a" >&2; exit 2 ;;
  esac
done
[ "$(id -u)" = "0" ] || { echo "Rode como root (sudo)." >&2; exit 1; }
cd "$APP_DIR"

if [ -e "${STATE}/setup-complete" ]; then
  echo "Setup ja estava concluido; nada a fazer."
  exit 0
fi
[ -f "${STATE}/Caddyfile.open" ] || { echo "ERRO: ${STATE}/Caddyfile.open ausente; rode o cloud-init de novo." >&2; exit 1; }

if [ "$SKIP" -eq 0 ]; then
  settings="$(docker compose exec -T n8n wget -qO- http://127.0.0.1:5678/rest/settings 2>/dev/null || true)"
  if printf '%s' "$settings" | grep -Eq '"showSetupOnFirstLoad"[[:space:]]*:[[:space:]]*true'; then
    echo "RECUSADO: o n8n ainda nao tem conta de proprietario (tela de cadastro aberta)." >&2
    echo "Acesse a URL, entre com a senha de bootstrap, crie o owner e rode este comando de novo." >&2
    exit 1
  fi
  if ! printf '%s' "$settings" | grep -Eq '"showSetupOnFirstLoad"[[:space:]]*:[[:space:]]*false'; then
    echo "RECUSADO: nao foi possivel verificar se o owner ja existe (n8n nao respondeu como esperado)." >&2
    echo "Confirme na tela do n8n e, se o owner existir, use --skip-check." >&2
    exit 1
  fi
fi

if [ "$YES" -eq 0 ]; then
  printf 'O owner do n8n ja foi criado? Digite SIM para remover a senha de bootstrap: '
  read -r answer || answer=""
  [ "$answer" = "SIM" ] || { echo "Cancelado."; exit 1; }
fi

reload_caddy() {
  docker compose exec -T caddy caddy validate --config /etc/caddy/Caddyfile >/dev/null 2>&1 \
    && docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile --force >/dev/null 2>&1
}

umask 077
cp "$CADDYFILE" "${STATE}/Caddyfile.gated.bak"
cat "${STATE}/Caddyfile.open" > "$CADDYFILE"   # no lugar (mesmo inode do bind mount)
if ! reload_caddy; then
  cat "${STATE}/Caddyfile.gated.bak" > "$CADDYFILE"
  reload_caddy || true
  rm -f "${STATE}/Caddyfile.gated.bak"
  echo "ERRO: Caddy nao aceitou a configuracao sem gate; gate restaurado, nada concluido." >&2
  exit 1
fi
: > "${STATE}/setup-complete"
rm -f "${STATE}/gate.hash" "${STATE}/bootstrap-password.txt" "${STATE}/Caddyfile.gated.bak"
echo "Pronto: senha de bootstrap removida. O acesso agora e somente pelo login do n8n (+HTTPS)."
FINISH_EOF
sed -i "s|@APP_DIR@|${APP_DIR}|g" "${APP_DIR}/finish-setup.sh"
chmod 700 "${APP_DIR}/finish-setup.sh"

# ---------------------------------------------------------------- [7/7] pronto
echo "== [7/7] Pronto"
echo "https://${N8N_HOST}/" > "${APP_DIR}/URL.txt"
chmod 644 "${APP_DIR}/URL.txt"
if [ "$CADDY_MODE" = "gated" ]; then
  cat > "${APP_DIR}/PROXIMOS-PASSOS.txt" <<EOF
1. Leia a senha de bootstrap (somente no servidor, via SSH):  sudo cat ${STATE}/bootstrap-password.txt
2. Abra https://${N8N_HOST}/ ; o navegador pede usuario "setup" e essa senha.
3. Crie a conta de proprietario do n8n (senha forte; ative 2FA).
4. Rode:  sudo ${APP_DIR}/finish-setup.sh   (remove a senha de bootstrap)
EOF
  chmod 644 "${APP_DIR}/PROXIMOS-PASSOS.txt"
  echo "READY (gate ativo) $(date -Is) https://${N8N_HOST}/ - veja ${APP_DIR}/PROXIMOS-PASSOS.txt"
else
  rm -f "${APP_DIR}/PROXIMOS-PASSOS.txt"
  echo "READY $(date -Is) https://${N8N_HOST}/"
fi
