> **Cópia histórica recebida do Claude — não usar como orientação de implantação.**
> Este documento pode conter informações incorretas sobre custos, limites ou recursos ainda não criados.
> Consulte o [status oficial](../../../STATUS.md) e a [revisão da versão 2](../../../REVISAO_V2.md).

---

# Status do Projeto Orquestrador

Última atualização: 2026-10-30

## Decisões

1. **Região:** região home da tenancy (São Paulo, GRU). Recursos Always Free só valem na região home.
2. **Conta em "Avaliação Grátis" (trial):** usar exclusivamente formas/volumes marcados "Always Free elegível"; nenhum upgrade, nenhum serviço pago.
3. **Forma:** `VM.Standard.A1.Flex`, 2 OCPUs / 12 GB (dentro do limite Always Free de 4 OCPUs / 24 GB e 200 GB de armazenamento em bloco).
4. **SO:** Canonical Ubuntu 24.04 (imagem completa, não Minimal).
5. **Rede:** VCN criada pelo assistente "VCN com conectividade de Internet" (o assistente de instância não liberou o IPv4 público ao criar VCN embutida). Regras de entrada TCP 22, 80, 443 na Default Security List.
6. **HTTPS sem domínio:** Caddy + `<ip>.sslip.io` com Let's Encrypt.
7. **SSH:** par de chaves gerado pelo console; a chave privada foi baixada pelo próprio usuário (nunca passou pelo chat). Login por senha desativado (somente se houver `authorized_keys`); fail2ban ativo.
8. **Autenticação do n8n (revisado 2026-10-30):** o primeiro cadastro **não** fica aberto. Gate de bootstrap no Caddy (basic auth, senha gerada no servidor) até o owner ser criado pelo usuário e `finish-setup.sh` ser executado. Recomenda-se ativar 2FA.
9. **Chave de criptografia (revisado):** gerada uma única vez; reexecuções reaproveitam o `.env`; o script aborta se houver volume do n8n sem chave.
10. **Bot:** token inserido pelo usuário diretamente em Credentials do n8n. ID do dono configurado no nó de código (não versionado). Responde só em conversa privada.
11. **Concorrência:** `N8N_CONCURRENCY_PRODUCTION_LIMIT=1` para serializar execuções que mexem nas tarefas.
12. **Custo:** o estimador do console mostra ~R$ 10,45/mês para o volume de boot (46,6 GB); isso é preço de tabela e deve ser coberto pelos 200 GB de bloco do Always Free. Conferir em *Cost Analysis* após a criação.

## Revisão 2026-10-30 (script cloud-init v2 e fluxo do Telegram v2)

Corrigido no script:
- Cadastro aberto do n8n: gate de bootstrap + `finish-setup.sh` (recusa se o owner ainda não existe; restaura o gate se o Caddy rejeitar a mudança).
- Troca da chave em reexecução: chave preservada; aborta se faltar a chave com volume existente; `.env` gravado com troca atômica, modo 600.
- Robustez: trava contra execução simultânea; log em append (sem senha/chave); IP público via metadados da OCI com fallbacks e validação; firewall inserido antes do primeiro REJECT/DROP sem duplicar; `sshd -t` antes de recarregar; não desativa senha SSH sem `authorized_keys`; sem `docker compose pull` em reexecução; `caddy validate` antes de `reload`; Caddyfile editado no mesmo inode.

Corrigido no fluxo:
- Duplicidade: dedupe por `update_id`; todos os itens do lote são processados.
- `/concluir`: só inteiro positivo (`^#?\d{1,9}$`); `3abc`, `1.5`, `0`, `-1` recusados.
- Grupos: ignora grupos/canais/bots em silêncio (antes respondia no grupo se o dono escrevesse lá).
- Limite: 200 **pendentes** (antes 300 no total, contando concluídas); poda de concluídas antigas (mantém 100).
- `/listar` truncado em ~3800 caracteres; texto escapado em HTML (`parse_mode` fixo) para evitar erro 400.

Testes (rodar localmente): `node tests/test-workflow.js` → 25 de 25; `bash tests/test-cloud-init.sh` → 93 de 93. Mutações de teste (chave rotacionando, gate removido, `/concluir` frouxo) são detectadas.
Não testado contra serviços reais (instância não existe): Docker/Caddy/n8n reais, Let's Encrypt, SSH real, Telegram real.

## Andamento

- [x] Verificação de recursos existentes: nenhuma instância, VCN ou volume no compartimento raiz.
- [x] VCN `vcn-orquestrador` + sub-rede pública + gateways criados.
- [x] Regras de entrada 80/443 adicionadas (22 já existia).
- [x] Script cloud-init v2 escrito e testado (stubs).
- [x] Workflow n8n do Gestor v2 escrito e testado localmente.
- [ ] **Instância `orquestrador`: BLOQUEADA** — `Out of host capacity` para `VM.Standard.A1.Flex` no AD-1 (testado sem domínio de falha, FD-1, FD-2 e FD-3, com 2 OCPU/12 GB e também com 1 OCPU/6 GB).
- [ ] n8n no ar com HTTPS (depende da instância).
- [ ] Teste do bot no Telegram (depende do n8n).
- [ ] Registro no repositório `brjjce-cell/projeto-orquestrador`: sem acesso nesta sessão; os arquivos estão prontos para o usuário subir.

## Pendências

1. Obter capacidade A1.Flex: repetir a criação em outros horários (madrugada costuma ter mais chance) ou tentar tamanho menor (1 OCPU / 6 GB) e redimensionar depois. Não usar formas pagas.
2. Criar a instância com o script `infra/cloud-init-orquestrador.sh` (v2) como user data.
3. Ler a senha de bootstrap por SSH, abrir `https://<ip-com-hifens>.sslip.io/`, criar o owner do n8n e rodar `sudo /opt/orquestrador/finish-setup.sh`.
4. Criar credencial Telegram, importar o workflow, ajustar o ID do dono e ativar; testar `/nova`, `/listar`, `/concluir` em conversa privada.
5. Backup do `/opt/orquestrador/.env` (contém a `N8N_ENCRYPTION_KEY`) e do volume `orquestrador_n8n_data`.
6. Avaliar restringir a porta 22 a um IP fixo e reservar o IP público (o IP efêmero se mantém enquanto a instância existir).
7. Subir estes arquivos ao repositório privado (sem credenciais).
