> **Cópia histórica recebida do Claude — não usar como orientação de implantação.**
> Este documento pode conter informações incorretas sobre custos, limites ou recursos ainda não criados.
> Consulte o [status oficial](../../../STATUS.md) e a [revisão da versão 2](../../../REVISAO_V2.md).

---

# Projeto Orquestrador

Servidor de automação (n8n) na Oracle Cloud Infrastructure, **somente recursos Always Free**, com um bot de Telegram ("Gestor") para criar, listar e concluir tarefas.

> Este repositório não contém credenciais, tokens, chaves privadas nem dados pessoais. Segredos ficam apenas no n8n (Credentials) e no servidor (`/opt/orquestrador/.env` e `/opt/orquestrador/state/`, modo 600).

## Arquitetura

- OCI, região home (São Paulo / `sa-saopaulo-1`), compartimento raiz.
- VCN `vcn-orquestrador` (10.0.0.0/16) com sub-rede pública, Internet Gateway, sub-rede privada, NAT e Service Gateway (todos sem custo).
- Instância `orquestrador`: `VM.Standard.A1.Flex`, 2 OCPUs, 12 GB, Ubuntu 24.04 (ARM), volume de boot padrão (~47 GB), IP público efêmero.
- Docker + Docker Compose; contêineres `n8n` (sem porta exposta) e `caddy` (80/443, HTTPS automático via Let's Encrypt).
- Hostname HTTPS: `<ip-com-hifens>.sslip.io` (sem domínio próprio). Trocar por domínio próprio é opcional.

## Segurança

- **Primeiro cadastro do n8n não fica aberto.** Até você rodar `finish-setup.sh`, o Caddy exige uma senha de bootstrap (usuário `setup`) para tudo, exceto `/webhook/*` (necessário para o Telegram). A senha é gerada no servidor, nunca aparece no log nem no chat: `sudo cat /opt/orquestrador/state/bootstrap-password.txt`.
- **A chave de criptografia não muda em reexecuções.** `N8N_ENCRYPTION_KEY` é gerada uma única vez e reaproveitada do `.env`. Se o volume do n8n existir mas o `.env` não tiver a chave, o script **aborta** em vez de gerar outra. **Faça backup do `.env`** (sem a chave, as credenciais salvas no n8n ficam irrecuperáveis).
- SSH somente por chave (`PasswordAuthentication no`, sem login de root), com `sshd -t` antes de recarregar; se o usuário `ubuntu` não tiver `authorized_keys`, o login por senha **não** é desativado (evita ficar sem acesso) e o script avisa. `fail2ban` no `sshd`.
- Firewall do SO: 80/443 inseridos antes da primeira regra REJECT/DROP da imagem Ubuntu da OCI, sem duplicar em reexecuções.
- Security List da OCI: TCP 22, 80 e 443 de entrada. Para reduzir a superfície, restrinja a porta 22 ao IP fixo do administrador, se houver.
- O script falha "fechado": se não conseguir gerar o hash da senha de bootstrap ou o Caddy rejeitar a configuração, nada é publicado.
- Bot Telegram: o workflow só responde ao ID numérico do dono e **somente em conversa privada**; grupos, canais e bots são ignorados em silêncio (nenhuma tarefa é exposta a grupos).

## Conteúdo

| Caminho | Descrição |
|---|---|
| `infra/cloud-init-orquestrador.sh` | Script de inicialização (user data), idempotente: Docker, n8n, Caddy, SSH endurecido, fail2ban, firewall do SO, gate de bootstrap e `finish-setup.sh`. |
| `n8n/workflows/gestor-tarefas-telegram.json` | Workflow: `/nova`, `/listar`, `/concluir`. Importar no n8n. **Gerado** a partir de `src/`. |
| `n8n/workflows/src/processar-comando.js` | Código-fonte editável do nó "Processar comando". |
| `n8n/workflows/build-workflow.js` | Regenera o JSON do workflow: `node n8n/workflows/build-workflow.js`. |
| `tests/test-workflow.js` | Testes do fluxo (usa o JSON entregue). |
| `tests/test-cloud-init.sh` | Testes do script e do `finish-setup.sh` com comandos simulados (stubs). |
| `docs/STATUS.md` | Decisões, andamento e pendências. |

## Primeiro acesso (depois que a instância existir)

1. Crie a instância com `infra/cloud-init-orquestrador.sh` como user data. Aguarde ~5 min.
2. Por SSH: `sudo cat /opt/orquestrador/state/bootstrap-password.txt` e `cat /opt/orquestrador/URL.txt`.
3. Abra a URL; o navegador pede usuário `setup` e essa senha. Crie a conta de proprietário do n8n (senha forte; ative 2FA).
4. Rode `sudo /opt/orquestrador/finish-setup.sh`. Ele só conclui se o n8n confirmar que o owner existe; então remove a senha de bootstrap e o Caddy passa a depender só do login do n8n.
5. Faça backup de `/opt/orquestrador/.env`.

Reexecutar o script de cloud-init é seguro: preserva a chave, a senha/hash de bootstrap (enquanto o setup não terminou) e não traz o gate de volta depois de concluído. Não atualiza imagens já baixadas (para atualizar o n8n: `cd /opt/orquestrador && sudo docker compose pull && sudo docker compose up -d`).

## Comandos do bot

- `/nova <texto>`: cria tarefa (até 500 caracteres; até 200 pendentes)
- `/listar`: pendentes; `/listar todas`: todas (corta em ~3800 caracteres e informa `(+N não exibidas)`)
- `/concluir <n>` ou `/concluir #n`: conclui a tarefa de número n; só aceita número inteiro positivo (`3abc`, `1.5`, `0`, `-1` são recusados)
- `/ajuda`

## Como colocar o workflow no ar

1. n8n → Credentials → *Create* → **Telegram API** → colar o token do bot (direto na tela do n8n) → salvar com o nome `Telegram Gestor`.
2. Workflows → *Import from file* → `gestor-tarefas-telegram.json`.
3. Nos nós **Telegram Trigger** e **Responder no Telegram**, selecionar a credencial `Telegram Gestor`.
4. No nó **Processar comando**, trocar `COLE_SEU_ID_AQUI` pelo seu ID numérico do Telegram. Se não souber, com o workflow ativo envie qualquer mensagem ao bot **em conversa privada**: ele responde com o ID (e não executa comandos até você configurar).
5. Ativar o workflow (*Active*). O Telegram exige HTTPS válido para o webhook, já atendido pelo Caddy.
6. Testar: `/nova teste`, `/listar`, `/concluir 1`.

Comportamentos de robustez do fluxo: updates repetidos do Telegram (mesmo `update_id`) são descartados, então uma retentativa não duplica tarefa; o texto é normalizado e escapado (HTML) para não causar erro 400 do Telegram; concluídas antigas são podadas (ficam as 100 mais recentes) e só as **pendentes** contam para o limite.

## Limitações conhecidas

- As tarefas ficam em *workflow static data*, que só persiste em execuções de produção (workflow ativo). O compose limita as execuções de produção a uma por vez (`N8N_CONCURRENCY_PRODUCTION_LIMIT=1`) para evitar corrida nesses dados. Para volume maior, relatórios ou vários usuários, migre para Data Table do n8n ou banco externo.
- Se o Telegram reenviar um update cuja primeira execução criou a tarefa mas falhou ao responder, a tarefa não é duplicada, mas a resposta daquela tentativa pode não chegar.
- Se o IP público mudar (instância recriada), o hostname `sslip.io` muda; reexecute o script e reative o workflow.

## Testes

```bash
node tests/test-workflow.js        # fluxo do Telegram (usa o JSON entregue)
bash tests/test-cloud-init.sh      # script cloud-init + finish-setup.sh (stubs, sem Docker/rede)
```

Os testes do script usam comandos simulados; o Caddyfile em si é validado no servidor pelo próprio script (`caddy validate` antes de cada `reload`).
