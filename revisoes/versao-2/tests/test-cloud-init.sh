#!/bin/bash
# Testes do cloud-init-orquestrador.sh e do finish-setup.sh gerado por ele.
# Rodam SEM Docker/apt/rede reais: comandos externos sao substituidos por stubs no PATH e todos os
# caminhos ficam sob um diretorio temporario (ORQ_ROOT_PREFIX).
# Uso: bash tests/test-cloud-init.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ="$(dirname "$HERE")"
SCRIPT="$PROJ/infra/cloud-init-orquestrador.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
check() { # check "descricao" comando...
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then PASS=$((PASS+1)); echo "  ok   $name"; else FAIL=$((FAIL+1)); echo "  FAIL $name"; fi
}
not() { ! "$@"; }
mode_is() { [ "$(stat -c %a "$1")" = "$2" ]; }
count_is() { [ "$(grep -c -- "$2" "$1" 2>/dev/null || true)" = "$3" ]; }

# ------------------------------------------------------------------ stubs
STUBS="$WORK/stubs"; mkdir -p "$STUBS"
mkstub() { cat > "$STUBS/$1"; chmod +x "$STUBS/$1"; }

for c in apt-get systemctl usermod netfilter-persistent; do
  mkstub "$c" <<'EOF'
#!/bin/bash
echo "$(basename "$0") $*" >> "$STUB_LOG"
EOF
done
mkstub dpkg <<'EOF'
#!/bin/bash
echo arm64
EOF
mkstub id <<'EOF'
#!/bin/bash
[ "${1:-}" = "-u" ] && { echo 0; exit 0; }
exec /usr/bin/id "$@"
EOF
mkstub sshd <<'EOF'
#!/bin/bash
echo "sshd $*" >> "$STUB_LOG"
exit "${STUB_SSHD_FAIL:-0}"
EOF
mkstub curl <<'EOF'
#!/bin/bash
args="$*"
echo "curl <redacted>" >> "$STUB_LOG"
while [ $# -gt 0 ]; do
  if [ "$1" = "-o" ]; then echo "stub-key" > "$2"; exit 0; fi
  shift
done
if [ -n "${STUB_IP_FAIL:-}" ]; then exit 22; fi
case "$args" in
  *169.254.169.254*) [ -n "${STUB_IMDS_FAIL:-}" ] && exit 22; echo "[{\"publicIp\":\"${STUB_IP}\"}]" ;;
  *ipify*|*icanhazip*|*ifconfig.me*) printf '%s\n' "${STUB_IP_FALLBACK:-$STUB_IP}" ;;
  *) exit 22 ;;
esac
EOF
mkstub iptables <<'EOF'
#!/bin/bash
RULES="$STUB_STATE/iptables.rules"; touch "$RULES"
port() { while [ $# -gt 0 ]; do [ "$1" = "--dport" ] && { echo "$2"; return; }; shift; done; }
case "$1" in
  -C) grep -q " dport $(port "$@")\$" "$RULES" ;;
  -L)
    echo "Chain INPUT (policy ACCEPT)"
    echo "num  target     prot opt source               destination"
    echo "1    ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED"
    echo "2    ACCEPT     icmp --  0.0.0.0/0            0.0.0.0/0"
    echo "3    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:22"
    echo "4    REJECT     all  --  0.0.0.0/0            0.0.0.0/0            reject-with icmp-host-prohibited"
    ;;
  -I) echo "iptables -I INPUT $3 dport $(port "$@")" >> "$STUB_LOG"; echo "$3 dport $(port "$@")" >> "$RULES" ;;
esac
EOF
mkstub docker <<'EOF'
#!/bin/bash
case "$1" in
  volume) [ "${STUB_VOLUME:-0}" = "1" ] ;;
  run)
    echo "docker run hash-password" >> "$STUB_LOG"
    if [ -n "${STUB_HASH_BAD:-}" ]; then echo "garbage"; exit 0; fi
    # ultimo argumento = senha em texto; hash falso bcrypt-shaped (60 chars), deterministico
    pw="${@: -1}"
    echo "\$2a\$14\$$(printf '%s' "$pw" | sha256sum | cut -c1-53)"
    ;;
  compose)
    shift
    case "$*" in
      version*) exit 0 ;;
      "up -d") echo "compose up" >> "$STUB_LOG" ;;
      *"exec -T caddy caddy validate"*) echo "caddy validate" >> "$STUB_LOG" ;;
      *"exec -T caddy caddy reload"*)
        echo "caddy reload" >> "$STUB_LOG"
        [ -e "$STUB_STATE/reload_fail" ] && exit 1
        cp "$STUB_APP/Caddyfile" "$STUB_STATE/caddyfile.at-last-reload"
        ;;
      *"exec -T n8n wget"*)
        [ -n "${STUB_WGET_FAIL:-}" ] && exit 1
        printf '%s' "${STUB_SETTINGS:-}"
        ;;
    esac
    ;;
  *) exit 0 ;;
esac
EOF

# ------------------------------------------------------------------ ambiente
new_env() { # cria raiz isolada; $1 = "nokeys" para nao criar authorized_keys
  R="$WORK/root.$RANDOM$RANDOM"; mkdir -p "$R/var/log" "$R/var/lock" "$R/home/ubuntu/.ssh"
  [ "${1:-}" = "nokeys" ] || echo "ssh-ed25519 AAAAFAKEPUBLICKEYFORTEST test" > "$R/home/ubuntu/.ssh/authorized_keys"
  export STUB_LOG="$R/stub.log" STUB_STATE="$R/stubstate" STUB_APP="$R/opt/orquestrador"
  mkdir -p "$STUB_STATE"; : > "$STUB_LOG"
  export STUB_IP="203.0.113.10"
  unset STUB_VOLUME STUB_HASH_BAD STUB_IP_FAIL STUB_IMDS_FAIL STUB_IP_FALLBACK STUB_SSHD_FAIL STUB_WGET_FAIL STUB_SETTINGS
  APP="$R/opt/orquestrador"; ST="$APP/state"; LOGF="$R/var/log/orquestrador-init.log"
}
run_init() { ORQ_ROOT_PREFIX="$R" ORQ_RETRY_SLEEP=0 PATH="$STUBS:$PATH" bash "$SCRIPT" </dev/null >/dev/null 2>&1; }
run_finish() { PATH="$STUBS:$PATH" bash "$APP/finish-setup.sh" "$@" 2>&1; }
key_of() { sed -n 's/^N8N_ENCRYPTION_KEY=//p' "$APP/.env"; }

echo "== Sintaxe"
check "bash -n cloud-init" bash -n "$SCRIPT"
check "ha tabs? (nao deve ter: quebraria colagem no console)" not grep -qP '\t' "$SCRIPT"
check "jq disponivel (necessario p/ o teste do IMDS)" command -v jq

echo "== Primeira execucao"
new_env
check "executa com sucesso" run_init
check ".env modo 600" mode_is "$APP/.env" 600
check "chave gerada com 64 hex" grep -Eq '^N8N_ENCRYPTION_KEY=[0-9a-f]{64}$' "$APP/.env"
check "host sslip a partir do IP (IMDS)" grep -q '^N8N_HOST=203-0-113-10\.sslip\.io$' "$APP/.env"
check "Caddyfile com gate (basic_auth) e /webhook/* liberado" bash -c "grep -q 'basic_auth @gated' '$APP/Caddyfile' && grep -q 'not path /webhook/\*' '$APP/Caddyfile'"
check "Caddyfile contem hash bcrypt, nao a senha" grep -Eq 'setup \$2a\$14\$' "$APP/Caddyfile"
check "Caddyfile modo 600" mode_is "$APP/Caddyfile" 600
check "reverse_proxy continua presente" grep -q 'reverse_proxy n8n:5678' "$APP/Caddyfile"
check "senha de bootstrap modo 600" mode_is "$ST/bootstrap-password.txt" 600
check "gate.hash modo 600" mode_is "$ST/gate.hash" 600
check "state/ modo 700" mode_is "$ST" 700
PW="$(cat "$ST/bootstrap-password.txt")"
check "senha de bootstrap tem 24 hex" bash -c "[[ '$PW' =~ ^[0-9a-f]{24}$ ]]"
check "senha NAO esta no log" not grep -qF "$PW" "$LOGF"
check "senha NAO esta no .env/compose/Caddyfile/URL/PROXIMOS-PASSOS" bash -c "! grep -qF '$PW' '$APP/.env' '$APP/docker-compose.yml' '$APP/Caddyfile' '$APP/URL.txt' '$APP/PROXIMOS-PASSOS.txt' '$STUB_LOG'"
check "chave de criptografia NAO esta no log" not grep -qF "$(key_of)" "$LOGF"
check "Caddyfile.open sem gate" bash -c "! grep -q basic_auth '$ST/Caddyfile.open' && grep -q reverse_proxy '$ST/Caddyfile.open'"
check "compose: concurrency limit = 1" grep -q 'N8N_CONCURRENCY_PRODUCTION_LIMIT=1' "$APP/docker-compose.yml"
check "compose: nome do projeto fixo" grep -q '^name: orquestrador' "$APP/docker-compose.yml"
check "compose: n8n sem porta publicada" bash -c "! grep -q '5678:5678' '$APP/docker-compose.yml'"
check "finish-setup.sh criado, executavel, caminho resolvido" bash -c "[ -x '$APP/finish-setup.sh' ] && grep -q 'APP_DIR=\"$APP\"' '$APP/finish-setup.sh' && bash -n '$APP/finish-setup.sh'"
check "SSH: drop-in endurecido aplicado" grep -q '^PasswordAuthentication no' "$R/etc/ssh/sshd_config.d/99-hardening.conf"
check "SSH: sshd -t executado antes do reload" bash -c "grep -n 'sshd -t' '$STUB_LOG' | head -1 | cut -d: -f1 | xargs -I{} bash -c '[ {} -gt 0 ]' && grep -q 'systemctl reload ssh' '$STUB_LOG'"
check "firewall: 80 e 443 inseridos ANTES do REJECT (posicao 4)" bash -c "grep -q 'iptables -I INPUT 4 dport 80' '$STUB_LOG' && grep -q 'iptables -I INPUT 4 dport 443' '$STUB_LOG'"
check "netfilter-persistent save chamado" grep -q 'netfilter-persistent save' "$STUB_LOG"
check "docker compose up chamado; sem 'pull' explicito" bash -c "grep -q 'compose up' '$STUB_LOG' && ! grep -q 'pull' '$STUB_LOG'"
check "caddy validate + reload chamados" bash -c "grep -q 'caddy validate' '$STUB_LOG' && grep -q 'caddy reload' '$STUB_LOG'"
check "reload viu o Caddyfile COM gate" grep -q basic_auth "$STUB_STATE/caddyfile.at-last-reload"
check "PROXIMOS-PASSOS.txt sem segredos, menciona finish-setup" bash -c "grep -q finish-setup.sh '$APP/PROXIMOS-PASSOS.txt'"

echo "== Segunda execucao (idempotencia)"
K1="$(key_of)"; H1="$(cat "$ST/gate.hash")"; INO1="$(stat -c %i "$APP/Caddyfile")"
: > "$STUB_LOG"
check "re-executa com sucesso" run_init
check "chave de criptografia NAO mudou" bash -c "[ '$K1' = '$(key_of)' ]"
check "senha/hash de bootstrap preservados (nao regerados)" bash -c "[ '$PW' = \"\$(cat '$ST/bootstrap-password.txt')\" ] && [ '$H1' = \"\$(cat '$ST/gate.hash')\" ]"
check "Caddyfile continua com gate" grep -q basic_auth "$APP/Caddyfile"
check "Caddyfile reescrito no mesmo inode (bind mount seguro)" bash -c "[ '$INO1' = '$(stat -c %i "$APP/Caddyfile")' ]"
check "nao baixa imagens/atualiza pacotes a toa (sem pull; sem hash novo)" bash -c "! grep -q 'hash-password' '$STUB_LOG' && ! grep -q pull '$STUB_LOG'"
check "regras de firewall nao duplicadas" bash -c "[ \"\$(grep -c 'dport 80' '$STUB_STATE/iptables.rules')\" = 1 ] && [ \"\$(grep -c 'dport 443' '$STUB_STATE/iptables.rules')\" = 1 ]"
check "log acumulado (append), nao sobrescrito" bash -c "[ \"\$(grep -c 'inicio (v2)' '$LOGF')\" = 2 ]"

echo "== Re-execucao com falha de deteccao de IP / IP via fallback"
export STUB_IP_FAIL=1
check "re-executa sem IP detectavel (sucesso)" run_init
check "host anterior preservado" grep -q '^N8N_HOST=203-0-113-10\.sslip\.io$' "$APP/.env"
check "chave preservada tambem aqui" bash -c "[ '$K1' = '$(key_of)' ]"
unset STUB_IP_FAIL
new_env
export STUB_IMDS_FAIL=1 STUB_IP_FALLBACK="198.51.100.7"
check "IMDS indisponivel: usa servico externo" run_init
check "host a partir do fallback" grep -q '^N8N_HOST=198-51-100-7\.sslip\.io$' "$APP/.env"
new_env
export STUB_IP_FAIL=1
check "primeira execucao sem IP: aborta (rc!=0)" not run_init
check "nada publicado sem IP (sem compose up)" not grep -q 'compose up' "$STUB_LOG"
new_env
export STUB_IP="999.1.1.1" STUB_IP_FALLBACK="not-an-ip"
check "IP invalido nunca vira host (aborta)" not run_init

echo "== Chave: volume existente sem .env"
new_env
export STUB_VOLUME=1
check "aborta (rc!=0)" not run_init
check ".env NAO foi criado (nenhuma chave nova)" not test -e "$APP/.env"
check "nada publicado (sem compose up)" not grep -q 'compose up' "$STUB_LOG"
check "mensagem explica o motivo" grep -q 'N8N_ENCRYPTION_KEY' "$LOGF"
unset STUB_VOLUME
new_env
mkdir -p "$APP"; printf 'N8N_HOST=203-0-113-10.sslip.io\nN8N_ENCRYPTION_KEY=chave-existente-do-backup-123456\n' > "$APP/.env"
export STUB_VOLUME=1
check "volume + .env restaurado: segue e preserva a chave" run_init
check "chave restaurada intacta" grep -q '^N8N_ENCRYPTION_KEY=chave-existente-do-backup-123456$' "$APP/.env"
unset STUB_VOLUME
new_env
mkdir -p "$APP"; printf 'N8N_HOST=203-0-113-10.sslip.io\nN8N_ENCRYPTION_KEY=curta\n' > "$APP/.env"
check "chave com formato invalido: aborta sem sobrescrever" not run_init
check ".env permanece como estava" grep -q 'N8N_ENCRYPTION_KEY=curta' "$APP/.env"

echo "== Gate falha FECHADO"
new_env
export STUB_HASH_BAD=1
check "hash invalido: aborta" not run_init
check "Caddyfile sem gate NAO foi publicado" bash -c "! test -e '$APP/Caddyfile'"
check "compose up NAO executado" not grep -q 'compose up' "$STUB_LOG"
unset STUB_HASH_BAD
new_env
touch "$STUB_STATE/reload_fail"
check "Caddy recusa a config: script falha (rc!=0)" not run_init

echo "== SSH"
new_env nokeys
check "sem authorized_keys: script conclui" run_init
check "login por senha NAO e desativado (evita lockout)" bash -c "! test -e '$R/etc/ssh/sshd_config.d/99-hardening.conf'"
check "aviso registrado" grep -q 'sem authorized_keys' "$LOGF"
new_env
export STUB_SSHD_FAIL=1
check "sshd -t reprova: conclui sem recarregar" run_init
check "drop-in invalido removido" bash -c "! test -e '$R/etc/ssh/sshd_config.d/99-hardening.conf'"
check "ssh nao foi recarregado" not grep -q 'systemctl reload ssh' "$STUB_LOG"
unset STUB_SSHD_FAIL

echo "== Trava de execucao simultanea"
new_env
exec 8>"$R/var/lock/orquestrador-init.lock"; flock -n 8
check "segunda instancia recusa (rc!=0)" not run_init
check "mensagem de trava no log" grep -q 'outra execucao' "$LOGF"
check "nada foi alterado" not test -e "$APP/.env"
flock -u 8; exec 8>&-

echo "== finish-setup.sh"
new_env; run_init
PW2="$(cat "$ST/bootstrap-password.txt")"
export STUB_SETTINGS='{"data":{"userManagement":{"showSetupOnFirstLoad":true}}}'
check "owner ainda nao existe: RECUSA (rc!=0)" not run_finish --yes
check "gate mantido" grep -q basic_auth "$APP/Caddyfile"
check "senha/hash mantidos, setup-complete ausente" bash -c "[ -f '$ST/bootstrap-password.txt' ] && [ -f '$ST/gate.hash' ] && [ ! -e '$ST/setup-complete' ]"
export STUB_WGET_FAIL=1
check "nao consegue verificar: RECUSA" not run_finish --yes
check "gate ainda mantido" grep -q basic_auth "$APP/Caddyfile"
unset STUB_WGET_FAIL
export STUB_SETTINGS='{"data":{"userManagement":{"showSetupOnFirstLoad":false}}}'
check "resposta inesperada do n8n: RECUSA" bash -c "export STUB_SETTINGS='<html>oops</html>'; ! PATH='$STUBS:$PATH' bash '$APP/finish-setup.sh' --yes"
check "owner existe mas resposta 'nao' na confirmacao: cancela" bash -c "! echo nao | PATH='$STUBS:$PATH' bash '$APP/finish-setup.sh'"
check "gate ainda mantido apos cancelar" grep -q basic_auth "$APP/Caddyfile"
touch "$STUB_STATE/reload_fail"
check "Caddy rejeita config sem gate: falha (rc!=0)" not run_finish --yes
check "gate RESTAURADO apos falha" grep -q basic_auth "$APP/Caddyfile"
check "nao marcou como concluido e manteve a senha" bash -c "[ ! -e '$ST/setup-complete' ] && [ -f '$ST/gate.hash' ]"
rm -f "$STUB_STATE/reload_fail"
INO2="$(stat -c %i "$APP/Caddyfile")"
check "owner existe + confirma SIM (stdin): conclui" bash -c "echo SIM | PATH='$STUBS:$PATH' bash '$APP/finish-setup.sh'"
check "Caddyfile sem gate, mesmo inode" bash -c "! grep -q basic_auth '$APP/Caddyfile' && grep -q reverse_proxy '$APP/Caddyfile' && [ '$INO2' = '$(stat -c %i "$APP/Caddyfile")' ]"
check "senha e hash de bootstrap APAGADOS" bash -c "[ ! -e '$ST/bootstrap-password.txt' ] && [ ! -e '$ST/gate.hash' ] && [ -e '$ST/setup-complete' ]"
check "reload viu o Caddyfile sem gate" bash -c "! grep -q basic_auth '$STUB_STATE/caddyfile.at-last-reload'"
check "rodar de novo e inofensivo (rc 0)" run_finish --yes
check "re-executar o cloud-init NAO traz o gate de volta" bash -c "K='$(key_of)'; run() { ORQ_ROOT_PREFIX='$R' ORQ_RETRY_SLEEP=0 PATH='$STUBS:$PATH' bash '$SCRIPT' </dev/null >/dev/null 2>&1; }; run && ! grep -q basic_auth '$APP/Caddyfile' && [ ! -e '$ST/bootstrap-password.txt' ] && [ \"\$K\" = \"\$(sed -n 's/^N8N_ENCRYPTION_KEY=//p' '$APP/.env')\" ]"
check "PROXIMOS-PASSOS removido apos concluir" bash -c "[ ! -e '$APP/PROXIMOS-PASSOS.txt' ]"
check "senha antiga nao reaparece em nenhum arquivo" bash -c "! grep -rqF '$PW2' '$APP' '$LOGF'"
check "opcao desconhecida: rc!=0" not run_finish --foo
new_env; run_init
check "--skip-check permite concluir quando a checagem nao roda" bash -c "export STUB_WGET_FAIL=1; PATH='$STUBS:$PATH' bash '$APP/finish-setup.sh' --yes --skip-check"

echo "== Varredura de segredos nos arquivos entregues"
check "sem chave privada" not grep -rEq -- '-----BEGIN [A-Z ]*PRIVATE KEY-----' "$PROJ"
check "sem token de bot do Telegram" not grep -rEq '[0-9]{8,10}:[A-Za-z0-9_-]{35}' "$PROJ"
check "sem OCIDs" not grep -rEq 'ocid1\.[a-z]+\.oc1' "$PROJ"
check "sem N8N_ENCRYPTION_KEY literal no script" not grep -Eq 'N8N_ENCRYPTION_KEY=[0-9a-f]{32,}' "$SCRIPT"

echo
echo "$PASS passaram, $FAIL falharam"
[ "$FAIL" -eq 0 ]
