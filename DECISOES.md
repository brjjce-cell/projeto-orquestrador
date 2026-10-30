# Decisões e questões abertas

Registro inicial: 30/10/2026.

## D-001 — GitHub privado como registro oficial

**Estado:** autorizado pelo usuário.

**Decisão:** criar `projeto-orquestrador` em sua conta GitHub com visibilidade privada, centralizando continuidade, arquitetura, decisões, status e próximos passos.

**Motivo:** reduzir a dependência do histórico de conversas para retomar o projeto.

**Consequência:** as etapas futuras devem atualizar os documentos. Não foi configurada sincronização automática com conversas.

## D-002 — Não incluir informações confidenciais

**Estado:** requisito expresso do usuário.

**Decisão:** não versionar segredos, tokens ou dados confidenciais. O envio inicial contém apenas documentação revisada e regras de exclusão de arquivos locais.

**Consequência:** configurações operacionais futuras precisarão separar valores secretos da documentação e do código.

## D-003 — Limitar a atuação ao novo repositório

**Estado:** requisito expresso do usuário.

**Decisão:** o trabalho desta etapa se restringe à criação e ao registro inicial de `projeto-orquestrador`, sem alterar outros repositórios.

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
2. Qual será o primeiro fluxo de automação demonstrável?
3. Quais modelos e serviços serão usados e qual o limite de gastos autorizado?
4. Quais ações exigirão aprovação humana?
5. Como serão implementados o armazenamento de credenciais, o backup e a recuperação?
6. Quais detalhes do documento original de continuidade precisam ser incorporados?

## Como registrar novas decisões

Para cada decisão, registrar data, problema, escolha, justificativa, consequências e evidência de autorização quando aplicável. Identificar propostas como propostas e preservar a distinção entre planejamento e execução.
