ATUALIZACAO_01-11-2026.md
# Atualização 01/11/2026

## Confirmações do usuário

- VPS criada e acessível na Oracle Cloud.
- Sistema operacional: **Oracle Linux 9**.
- Acesso SSH testado e validado.
- Chave privada SSH permanece no pendrive físico (ajustar `chmod 400` no computador de casa).
- Tokens e segredos continuam fora do repositório e de chats.

## Situação atual

| Item                        | Status                          |
|----------------------------|---------------------------------|
| VPS                        | Criada e acessível              |
| Oracle Linux 9             | Confirmado                      |
| SSH                        | Validado                        |
| Docker + Docker Compose    | Pendente                        |
| n8n Community Edition      | Pendente                        |
| code-server + Continue     | Planejado                       |
| Portas 5678 e 8080         | Pendentes de liberação          |
| Integração bot Gestor      | Pendente                        |
| Fluxo de tarefas (rascunho)| Precisa de revisão              |

## Estratégia atualizada

Arquitetura self-hosted de custo zero:

- Infraestrutura: VPS Oracle Always Free (já criada)
- Automações: n8n Community (Docker)
- IDE Web: code-server + Continue
- Modelos de IA: OpenRouter free / NVIDIA NIM / Ollama
- Acesso: 3 abas no navegador (n8n :5678, code-server :8080, Oracle Cloud Shell)

## Próxima ação prioritária

1. Conectar na VPS pelo SSH (computador de casa).
2. Instalar Docker + Docker Compose no Oracle Linux 9.
3. Subir o n8n com volume persistente.
4. Liberar a porta 5678 (Security List + firewall).
5. Só depois revisar o fluxo do bot e implantar o code-server.

## Observações

Os arquivos anteriores (`STATUS.md`, `CONTINUIDADE.md`, etc.) permanecem como registro histórico.  
Esta atualização reflete o estado confirmado em 01/11/2026.
