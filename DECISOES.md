# Decisões e questões abertas

Registro inicial: 30/10/2026.

## D-001 — GitHub privado como registro oficial

**Estado:** autorizado pelo usuário.

**Decisão:** criar `projeto-orquestrador` em sua conta GitHub com visibilidade privada, centralizando continuidade, arquitetura, decisões, status e próximos passos.

**Motivo:** reduzir a dependência do histórico de conversas para retomar o projeto.

**Consequência:** as etapas futuras devem atualizar os documentos conforme D-004. Não foi configurado um serviço de sincronização ou uma tarefa agendada.

## D-002 — Não incluir informações confidenciais

**Estado:** requisito expresso do usuário.

**Decisão:** não versionar segredos, tokens ou dados confidenciais. O envio inicial contém apenas documentação revisada e regras de exclusão de arquivos locais.

**Consequência:** configurações operacionais futuras precisarão separar valores secretos da documentação e do código.

## D-003 — Limitar a atuação ao novo repositório

**Estado:** requisito expresso do usuário.

**Decisão:** a criação e a manutenção do registro se restringem a `projeto-orquestrador`, sem alterar outros repositórios.

## D-004 — Manter o registro durante o trabalho ativo

**Data:** 30/10/2026.

**Estado:** adotado em resposta à solicitação do usuário de atualização ao longo das conversas.

**Decisão:** ao concluir uma etapa relevante do projeto neste contexto, o assistente deve resumir decisões confirmadas, avanços, testes e pendências, atualizar os documentos afetados e publicar a atualização por Git/SSH dentro da autorização aplicável. Não é necessário um pedido separado a cada etapa.

**Motivo:** o acesso SSH à conta correta foi validado, permitindo manter o registro diretamente sem depender do envio manual de arquivos pelo usuário.

**Limites:** não transcrever conversas integralmente, não incluir segredos ou dados confidenciais e não registrar inferências como fatos concluídos. Perguntas sem mudanças no projeto não exigem um commit. Não há tarefa agendada ou monitoramento de outros chats configurado; a manutenção ocorre durante o trabalho ativo com o contexto disponível.

**Evidência técnica:** autenticação SSH na conta `brjjce-cell`, leitura de `main` e simulação de envio concluídas em 30/10/2026. Essa validação se refere ao GitHub; não houve teste de acesso SSH a um servidor Oracle.

## D-005 — Adiar a verificação da Oracle

**Data:** 30/10/2026.

**Estado:** solicitado pelo usuário.

**Decisão:** adiar temporariamente a verificação da infraestrutura Oracle devido aos problemas de conexão relatados e avançar no planejamento do primeiro teste. Retomar a verificação quando a conexão estiver normalizada.

**Consequência:** a disponibilidade gratuita e a configuração do servidor continuam pendentes. Não houve provisionamento nesta etapa.

## D-006 — Começar por tarefas no Telegram

**Data:** 30/10/2026.

**Estado:** escopo escolhido pelo usuário.

**Decisão:** o primeiro teste será receber e organizar tarefas pelo Telegram.

**Proposta de funcionamento:** cadastrar, listar pendências e marcar tarefas como concluídas, conforme PRIMEIRO_TESTE.md. Os comandos e as regras estão documentados como proposta inicial. Armazenamento, implementação e teste real permanecem pendentes.

## Direções de arquitetura registradas no histórico

Estas direções orientam o planejamento, mas não representam implantação concluída ou escolha técnica final validada:

| Direção | Base disponível | Validação pendente |
| --- | --- | --- |
| Avaliar Oracle Cloud para o servidor | Usuário mencionou Oracle e informou criação da conta | Disponibilidade, elegibilidade gratuita e configuração |
| Usar Docker e n8n | Arquitetura descrita na conversa | Instalação, versões e persistência |
| Usar Telegram como interface | Arquitetura descrita na conversa | Bot, autenticação e integração |
| Coordenar agentes especializados | Objetivo descrito na conversa | Escopo, ferramentas e critérios de execução |

## Questões abertas

1. Qual configuração gratuita está disponível e é suficiente para o primeiro teste?
2. Qual armazenamento persistente e forma de integração serão usados no piloto de tarefas pelo Telegram?
3. Quais modelos e serviços serão usados e qual o limite de gastos autorizado?
4. Quais ações exigirão aprovação humana?
5. Como serão implementados o armazenamento de credenciais, o backup e a recuperação?
6. Quais detalhes do documento original de continuidade precisam ser incorporados?

## Como registrar novas decisões

Para cada decisão, registrar data, problema, escolha, justificativa, consequências e evidência de autorização quando aplicável. Identificar propostas como propostas e preservar a distinção entre planejamento e execução.
