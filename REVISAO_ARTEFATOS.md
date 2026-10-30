# Revisão dos artefatos do piloto

Data: 30/10/2026.

## Atualização sobre versão 2

Em 30/10/2026, o usuário trouxe relato de uma versão 2 que corrigiria os pontos abaixo. O outro assistente informou 25 testes do fluxo e 93 do script com comandos simulados. Esses resultados e os arquivos v2 ainda não foram verificados nesta sessão; a revisão a seguir se aplica à versão anterior.

## Arquivos recebidos

Foram lidos os arquivos README.md, STATUS.md e gestor-tarefas-telegram.json fornecidos pelo usuário. Posteriormente, o script cloud-init foi recebido e revisado sem execução; seus resultados estão em REVISAO_CLOUD_INIT.md. Nenhuma credencial ou chave privada foi incorporada ao repositório.

## Avaliação da documentação recebida

- O STATUS recebido menciona 4 OCPUs / 24 GB como limite Always Free para A1. A [documentação oficial da Oracle](https://docs.oracle.com/pt-br/iaas/Content/FreeTier/freetier.htm) informa 2 OCPUs / 12 GB totais para permanecer no Always Free após a avaliação.
- A documentação descreve proteções, HTTPS e usuário proprietário como parte da configuração planejada. Como a instância não foi criada segundo o relato e a captura de tela, esses recursos não foram comprovados em funcionamento.
- A afirmação de que todos os componentes de rede são gratuitos e de que a estimativa positiva será integralmente coberta não foi comprovada nesta revisão. Verificar diretamente recursos, consumo de créditos e custos na Oracle.

## Avaliação do fluxo n8n

O fluxo contém um gatilho Telegram, um nó de processamento de comandos e um nó de resposta. Os comandos `/lista` e `/listar` são aceitos; assim, a diferença de nomes identificada no relato anterior está esclarecida.

O nó de código foi examinado e executado isoladamente com dados fictícios, sem Telegram, credenciais, n8n ou acesso à rede. A criação simples funcionou e uma mensagem de outro usuário com ID configurado foi ignorada. Os seguintes pontos precisam de correção ou decisão antes do uso:

1. **Eventos repetidos:** duas entregas do mesmo comando de criação geraram duas tarefas. O fluxo não registra um identificador do evento para evitar duplicações.
2. **Identificador inválido:** `/concluir 1abc` foi interpretado como tarefa 1 e a marcou como concluída. A entrada precisa ser validada integralmente.
3. **Conversa em grupo:** um comando enviado pelo usuário autorizado em um grupo gerou resposta para o grupo. Restringir o chat ou confirmar explicitamente se esse comportamento é desejado antes de expor tarefas.
4. **Limite de 300 tarefas:** mesmo com as 300 já concluídas, a criação foi bloqueada. A mensagem sugere limpar, mas o fluxo recebido não oferece um comando de limpeza.
5. **Configuração inicial:** enquanto o ID do usuário não for configurado, o fluxo responde ao remetente informando o ID dele. Definir uma configuração segura antes de ativar o bot.
6. **Persistência:** o fluxo usa dados estáticos do workflow. A [documentação n8n](https://docs.n8n.io/code/cookbook/builtin/get-workflow-static-data/) informa que essa funcionalidade é experimental, não persiste em testes manuais e pode ser pouco confiável em execuções frequentes. Avaliar armazenamento adequado, prevenção de duplicidades e backup.

## Limites da revisão

Os ensaios isolados não confirmam importação, integração com Telegram, concorrência, persistência real ou recuperação após reinício no n8n. O fluxo não foi ativado nem implantado. O script cloud-init foi revisado posteriormente; as correções e a validação da segurança do primeiro acesso ao n8n ainda são necessárias antes de criar a instância com esse script.
