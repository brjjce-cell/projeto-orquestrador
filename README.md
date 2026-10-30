# Projeto Orquestrador

Registro oficial de continuidade do Projeto Orquestrador, mantido em repositório privado.

## Objetivo

Planejar um sistema que receba comandos e aprovações pelo Telegram e coordene automações e agentes especializados. A estrutura discutida prevê Docker e n8n em um servidor Oracle Cloud.

**Fase atual:** planejamento e preparação da infraestrutura. O funcionamento do servidor, do n8n e dos agentes ainda não foi confirmado.

## Por onde continuar

1. Leia [Continuidade](CONTINUIDADE.md) para recuperar o contexto e os limites deste registro.
2. Consulte [Status](STATUS.md) para separar o que foi confirmado do que está pendente.
3. Siga [Próximos passos](PROXIMOS_PASSOS.md), começando pela avaliação da infraestrutura gratuita.

Documentos de referência:

- [Arquitetura planejada](ARQUITETURA.md)
- [Decisões e questões abertas](DECISOES.md)

## Como manter o registro

Ao concluir uma etapa, atualize o status, registre decisões relevantes e revise o próximo passo no mesmo commit. Informe a data, o que mudou e a evidência disponível, sem anexar informações confidenciais.

Este repositório não recebe atualizações automáticas das conversas. Nenhuma sincronização ou rotina de backup foi configurada nesta etapa.

## Escopo e proteção dos dados

Este registro inicial contém somente documentação. Não contém aplicação, servidor provisionado, workflows executáveis ou credenciais.

Não incluir senhas, tokens de bots, chaves de API, chaves privadas, arquivos de ambiente, dados pessoais, backups de serviços ou exportações com informações confidenciais. O arquivo [.gitignore](.gitignore) ajuda a excluir arquivos locais comuns; o conteúdo deve ser revisado antes de cada envio.

**Última consolidação:** 30/10/2026. O documento original de continuidade não estava disponível no histórico recuperado; os detalhes ausentes estão indicados nos documentos.
