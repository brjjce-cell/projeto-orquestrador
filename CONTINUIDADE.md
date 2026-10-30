# Continuidade do Projeto Orquestrador

Consolidação inicial: 30/10/2026.

## Contexto recuperado

O histórico da conversa “Breno - Continuar Projeto Orquestrador”, de 29 e 30/10/2026, descreve a intenção de usar Telegram para comandos, acompanhamento e aprovações; Docker e n8n para executar e coordenar automações; e um agente orquestrador para planejar e supervisionar agentes especializados.

Foram citados agentes de pesquisa, criação e análise. Também foram mencionadas possíveis aplicações em achadinhos, afiliados, YouTube, TikTok e Redbubble. Esses exemplos representam possibilidades discutidas, sem implantação confirmada.

## Último ponto confirmado

- O usuário informou que criou a conta Oracle Cloud.
- O histórico registra acesso ao painel da região de São Paulo.
- O passo de infraestrutura discutido era acessar Computação > Instâncias e avaliar uma configuração gratuita antes de criar o servidor.
- A instalação local do Docker não foi concluída segundo o histórico, motivando a avaliação antecipada de um servidor em nuvem.
- O usuário autorizou criar um repositório GitHub privado chamado `projeto-orquestrador` como registro oficial.
- O repositório privado foi criado na conta `brjjce-cell`, e o usuário publicou os sete arquivos iniciais em 30/10/2026.
- O acesso por SSH autenticou na conta `brjjce-cell`; a leitura da branch `main` e uma simulação de envio foram concluídas com sucesso.
- O usuário solicitou que o registro acompanhe as conversas. Durante o trabalho ativo neste contexto, as mudanças relevantes devem ser resumidas e publicadas sem um novo pedido a cada etapa.

## Pré-requisitos informados pelo usuário

Em 30/10/2026, o usuário confirmou que já possui conta Oracle, bot denominado Gestor criado e seu ID do Telegram. O nome de usuário do bot não foi informado; a criação e o funcionamento não foram verificados diretamente no Telegram nesta etapa. Nenhum token ou valor de identificador pessoal foi incorporado ao repositório.

O usuário confirmou que o n8n ainda não está em funcionamento. A preparação do ambiente e a integração do Gestor ao fluxo permanecem pendentes. Aproveitar o bot já criado quando a infraestrutura puder ser preparada.

O usuário informou depois que o acesso à Oracle voltou. Retomar a verificação da infraestrutura e manter a recuperação do documento original de continuidade como pendência paralela.

## Mudança de prioridade em 30/10/2026

O usuário relatou problemas de conexão e pediu para pular temporariamente a etapa da Oracle. Em seguida, escolheu receber e organizar tarefas pelo Telegram como primeiro teste.

Durante a indisponibilidade, foi definido o escopo desse fluxo. A proposta documentada em PRIMEIRO_TESTE.md prevê cadastrar, listar e concluir tarefas. Os comandos e as regras são uma proposta de funcionamento; não houve implementação ou teste real.

Em seguida, ainda em 30/10/2026, o usuário informou que o acesso à Oracle voltou. A prioridade atual passa a ser conferir as opções de instância e sua elegibilidade gratuita antes de qualquer provisionamento. A disponibilidade de recursos e a existência de uma instância ainda não foram verificadas nesta etapa.

## Ponto atual da configuração Oracle

Em 30/10/2026, as capturas de tela mostraram o formulário da instância com Ubuntu 24.04 Minimal aarch64 e forma VM.Standard.A1.Flex, 2 OCPUs e 12 GB. A forma foi exibida como elegível ao Always Free; o custo final e a disponibilidade efetiva ainda precisam ser conferidos.

O formulário não liberou a opção de IPv4 público, mesmo após a seleção de uma nova sub-rede pública. O usuário abriu em outra aba o formulário separado para criar uma rede virtual. Não há confirmação de criação da VCN ou da instância. O controle de navegador desta sessão falhou ao iniciar, e o usuário pediu para delegar a continuação. Detalhes e próximos passos em ORACLE_CONTINUIDADE.md.

## Relato recebido após a delegação

Em 30/10/2026, o usuário forneceu o relato da outra sessão: uma VCN e componentes de rede teriam sido criados, mas as tentativas A1.Flex com 2 OCPUs / 12 GB e 1 OCPU / 6 GB falharam por falta de capacidade. A sessão relatou ter preparado um script de inicialização e um fluxo n8n, que ainda não foram disponibilizados aqui para inspeção. Recursos, regras e custos precisam ser verificados diretamente na conta.

O relato intermediário mencionou 4 OCPUs / 24 GB como Always Free, mas a documentação oficial atual da Oracle informa limite total de 2 OCPUs / 12 GB para preservar instâncias A1 após a avaliação gratuita. Os detalhes, fontes e pendências constam em RELATO_CLAUDE.md.

## Preservação dos arquivos da sessão delegada

Em 30/10/2026, o ZIP da versão 2 foi recebido. O código, o fluxo e os testes foram preservados como rascunho em `revisoes/versao-2/`; os dois documentos que vieram no ZIP foram arquivados em `originais/` com avisos sobre informações que ainda precisam de correção. Nenhuma chave privada ou token foi incluído.

Esses documentos da sessão delegada não são o documento original de continuidade citado anteriormente, que continua pendente. A configuração da instância no formulário Oracle não havia sido finalizada; o usuário informou que encerraria suas atividades e foi orientado a cancelar o formulário. A criação ou o cancelamento efetivo não foi verificado nesta sessão.

## Limite das fontes

O histórico menciona um documento completo de continuidade compartilhado anteriormente, mas esse documento não estava acessível na recuperação realizada para este registro. Não houve transcrição nem validação integral desse documento.

Por isso, esta consolidação é parcial. Não pressupor que existam configurações, versões, código, workflows, contas de serviços adicionais ou decisões que não estejam documentados aqui. Ao recuperar o documento original, revisar seu conteúdo, remover informações confidenciais e reconciliar divergências antes de incorporá-lo.

As informações sobre implantação refletem o relato disponível; não foram verificadas diretamente no servidor ou na Oracle nesta etapa.

## Orientação para a próxima conversa

1. Consultar este repositório e a versão mais recente de STATUS.md.
2. Confirmar se houve alguma ação fora do registro.
3. Avançar na primeira tarefa pendente de PROXIMOS_PASSOS.md.
4. Atualizar e publicar os documentos ao concluir uma etapa relevante, dentro da autorização aplicável ao projeto.

O usuário prefere explicações curtas, claras e diretas, com um passo por vez.

## Persistência do registro

O GitHub centraliza a documentação. O histórico de conversas permanece uma fonte complementar. Durante o trabalho ativo, o assistente deve manter resumos de decisões, progresso, testes e pendências por Git/SSH. Não há transcrição integral, monitoramento de outros chats ou tarefa agendada configurada.

A orientação de manutenção foi registrada também em AGENTS.md para tarefas abertas neste repositório. Em uma nova conversa, consultar este registro antes de continuar e recuperar qualquer contexto adicional necessário.
