# Revisão da versão 2 — rascunho

Data: 30/10/2026.

Os arquivos de código e testes recebidos foram preservados em `revisoes/versao-2/` como rascunho. Não são uma versão aprovada para implantação. As documentações externas com informações conflitantes não substituíram os documentos oficiais deste repositório.

## O que foi verificado

- O arquivo do fluxo corresponde ao código-fonte. Os 25 testes locais do fluxo passaram com dados fictícios, sem serviços reais.
- O script cloud-init e seu teste passaram em `bash -n`. O script de instalação não foi executado.
- Os 93 testes simulados do cloud-init relatados pela outra sessão não foram reproduzidos aqui: as ferramentas `jq` e `flock` não estavam disponíveis neste Windows.
- Não houve teste real com n8n, Docker, Caddy, SSH, Oracle ou Telegram. A instância continua sem criação confirmada.

## Pendências antes de usar

1. **Histórico de tarefas:** ao concluir uma tarefa, o fluxo apaga as concluídas mais antigas quando ultrapassa 100. Isso contraria a proposta de preservar o histórico e requer alteração ou decisão explícita do usuário.
2. **Eventos repetidos:** a proteção guarda apenas os 200 identificadores mais recentes. Em teste fictício, reenviar um evento após outros 200 criou uma duplicata.
3. **Persistência:** o fluxo ainda usa dados estáticos experimentais do n8n. A documentação informa limitações em testes manuais e possíveis falhas sob execuções frequentes. Avaliar armazenamento e backup adequados: https://docs.n8n.io/code/cookbook/builtin/get-workflow-static-data/.
4. **Primeiro acesso:** a versão 2 adiciona senha temporária no Caddy e preserva a chave de criptografia em condições simuladas. Porém, o mecanismo não foi validado com Caddy/n8n reais; o script permite `--skip-check --yes`, que pode remover a proteção sem verificação automática do proprietário. Validar o processo antes de expor o serviço.
5. **SSH:** o script valida a sintaxe, mas ainda usa `99-hardening.conf` e ignora falha de recarga. Isso não confirma os valores efetivos; verificar precedência e `sshd -T` na imagem real.
6. **Versões:** as imagens `latest` e `caddy:2` permanecem móveis. Fixar versões testadas e verificar compatibilidade.
7. **Custos:** a documentação recebida ainda cita 4 OCPUs / 24 GB e diz que todos os gateways são gratuitos. A Oracle informa 2 OCPUs / 12 GB totais para permanecer Always Free após a avaliação; os custos e créditos dos recursos criados seguem pendentes de conferência no painel.

## Limites

Os testes não comprovam segurança, persistência ou integração real. Não usar a versão 2 no formulário Oracle até corrigir e revisar as pendências, validar a segurança do primeiro acesso e confirmar qual script está colado no formulário.
