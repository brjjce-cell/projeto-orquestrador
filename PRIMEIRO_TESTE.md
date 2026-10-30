# Primeiro teste — tarefas pelo Telegram

Data: 30/10/2026.

**Escolha confirmada pelo usuário:** receber e organizar tarefas pelo Telegram.

**Estado:** proposta de funcionamento documentada; bot Gestor criado e ID do Telegram obtido segundo o usuário. O usuário informou que o n8n ainda não está em funcionamento. Integração, armazenamento e execução permanecem pendentes.

## Objetivo

Validar um ciclo simples: enviar uma tarefa, receber confirmação, consultar pendências e marcar a tarefa como concluída. A verificação da Oracle foi adiada a pedido do usuário por problemas de conexão.

## Pré-requisitos informados

- [x] Conta Oracle criada, conforme relato do usuário.
- [x] Bot do Telegram denominado Gestor criado, conforme relato do usuário.
- [x] ID do Telegram obtido pelo usuário; valor não registrado aqui.
- [x] Confirmar a situação do n8n: usuário informou que ainda não está em funcionamento.
- [ ] Preparar um ambiente n8n para executar o piloto.
- [ ] Configurar credenciais e a integração do bot nesse ambiente.
- [ ] Preparar o armazenamento das tarefas e executar o teste.

O nome de usuário do bot não foi informado. A criação do bot não confirma que os comandos propostos já funcionem.

## Comandos propostos

| Comando | Ação | Exemplo |
| --- | --- | --- |
| `/nova <descrição>` | Cadastrar uma tarefa pendente e devolver seu número | `/nova Revisar roteiro` |
| `/lista` | Mostrar as tarefas pendentes, da mais antiga para a mais recente | `/lista` |
| `/concluir <número>` | Marcar a tarefa indicada como concluída | `/concluir 1` |

Os nomes e as mensagens abaixo são uma proposta inicial. Não representam comandos já cadastrados ou testados no Telegram.

## Exemplo esperado

```text
Usuário: /nova Revisar roteiro
Orquestrador: Tarefa #1 criada: Revisar roteiro. Status: pendente.

Usuário: /lista
Orquestrador: Pendentes:
#1 — Revisar roteiro

Usuário: /concluir 1
Orquestrador: Tarefa #1 concluída.

Usuário: /lista
Orquestrador: Você não tem tarefas pendentes.
```

## Regras iniciais propostas

- Cada tarefa recebe um identificador único, uma descrição, um estado e as datas de criação e conclusão.
- Os estados deste piloto são pendente e concluída. Concluir preserva o histórico da tarefa.
- Uma descrição vazia ou um identificador inválido deve produzir uma orientação curta, sem alterar o registro.
- Concluir novamente uma tarefa já concluída deve informar seu estado atual.
- Receber novamente o mesmo evento do Telegram não deve criar uma segunda tarefa.
- O piloto atende apenas ao usuário autorizado. Identificadores de acesso e credenciais ficam fora do repositório.
- Os registros devem persistir após reiniciar o serviço; a forma de armazenamento será definida na preparação da infraestrutura.

## Fluxo planejado

Telegram → recebimento e validação no n8n → registro ou consulta das tarefas → resposta no Telegram.

A coordenação deste piloto usa regras simples de cadastro e consulta. Modelos de IA, agentes especializados, pesquisa de produtos e criação de vídeos ficam para etapas posteriores.

## Critérios de aceite — ainda não executados

1. Cadastrar duas tarefas e receber identificadores diferentes.
2. Listar as duas tarefas pendentes.
3. Concluir uma delas e verificar que a outra continua pendente.
4. Reiniciar o serviço e confirmar que os registros e seus estados foram preservados.
5. Repetir o mesmo evento de cadastro e confirmar que não surgiu uma tarefa duplicada.
6. Enviar um comando inválido e verificar que nenhuma tarefa foi alterada.
7. Confirmar que um usuário não autorizado não consegue consultar ou alterar as tarefas.

## O que pode avançar agora

- Escopo escolhido e proposta de comandos registrados neste documento.
- Revisão das regras e das respostas esperadas sem depender do painel Oracle.

## Quando a conexão estiver normalizada

Retomar a verificação da infraestrutura conforme necessário; preparar o ambiente e o armazenamento persistente; configurar a integração com o bot Gestor já criado, mantendo credenciais e identificadores pessoais fora do GitHub; implementar o fluxo e executar os critérios de aceite.

A implantação e o teste real permanecem pendentes.
