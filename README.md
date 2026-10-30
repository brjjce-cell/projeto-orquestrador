# Projeto Orquestrador

Registro oficial de continuidade do Projeto Orquestrador, mantido em repositório privado.

## Objetivo

Planejar um sistema que receba comandos e aprovações pelo Telegram e coordene automações e agentes especializados. A estrutura discutida prevê Docker e n8n em um servidor Oracle Cloud.

**Fase atual:** verificação da infraestrutura para executar o primeiro teste: receber e organizar tarefas pelo Telegram. O usuário informou que o acesso à Oracle voltou; a conferência das opções de servidor passa a ser a próxima etapa. O n8n ainda não está em funcionamento, segundo o usuário. O funcionamento do servidor e dos agentes ainda não foi confirmado.

O usuário já informou que a conta Oracle está criada, o bot **Gestor** foi criado e seu ID do Telegram foi obtido. O n8n ainda precisa ser preparado, e a integração do bot está pendente. Credenciais e identificadores pessoais permanecem fora do repositório.

## Por onde continuar

1. Leia [Continuidade](CONTINUIDADE.md) para recuperar o contexto e os limites deste registro.
2. Consulte [Status](STATUS.md) para separar o que foi confirmado do que está pendente.
3. Consulte o [primeiro teste pelo Telegram](PRIMEIRO_TESTE.md) e siga [Próximos passos](PROXIMOS_PASSOS.md). A próxima ação é conferir as opções de infraestrutura no painel Oracle.

Documentos de referência:

- [Arquitetura planejada](ARQUITETURA.md)
- [Decisões e questões abertas](DECISOES.md)

## Como manter o registro

Durante o trabalho ativo nesta conversa e neste projeto, o assistente deve registrar as decisões confirmadas, os avanços, os testes e as pendências relevantes sem exigir um pedido separado a cada etapa. Ao concluir uma etapa, atualizar o status, registrar as decisões e revisar o próximo passo no mesmo commit.

O registro contém resumos de continuidade. Perguntas sem mudança no projeto não exigem um novo commit. Informar a data, o que mudou e a evidência disponível, sem anexar informações confidenciais.

O acesso Git por SSH à conta `brjjce-cell` foi validado em 30/10/2026, incluindo leitura do repositório e simulação de envio. Esse é o caminho disponível para publicar as próximas atualizações.

Não há monitoramento de outros chats, cópia integral das conversas ou tarefa agendada configurada. O registro acontece durante o trabalho ativo do assistente; informações de outras conversas precisam ser recuperadas ou fornecidas antes de serem incorporadas. Nenhuma rotina de backup foi configurada nesta etapa.

## Escopo e proteção dos dados

Este registro inicial contém somente documentação. Não contém aplicação, servidor provisionado, workflows executáveis ou credenciais.

Não incluir senhas, tokens de bots, chaves de API, chaves privadas, arquivos de ambiente, dados pessoais, backups de serviços ou exportações com informações confidenciais. O arquivo [.gitignore](.gitignore) ajuda a excluir arquivos locais comuns; o conteúdo deve ser revisado antes de cada envio.

**Última consolidação:** 30/10/2026. O documento original de continuidade não estava disponível no histórico recuperado; os detalhes ausentes estão indicados nos documentos.
