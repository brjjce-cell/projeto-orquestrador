# Próximos passos

Data de referência: 30/10/2026. Esta lista é um plano; não autoriza contratações, exposição de serviços ou alterações fora deste repositório.

## 1. Definir o piloto de tarefas pelo Telegram — planejamento registrado

- [x] Escolher o primeiro fluxo: receber e organizar tarefas pelo Telegram.
- [x] Documentar uma proposta de cadastro, listagem e conclusão de tarefas em [Primeiro teste](PRIMEIRO_TESTE.md).
- [x] Definir exemplos de resposta e critérios de aceite.
- [x] Confirmar a situação do n8n: usuário informou que ainda não está em funcionamento.
- [ ] Revisar a proposta com base em eventuais ajustes do usuário.
- [ ] Definir o armazenamento persistente e a forma de integração na preparação da infraestrutura.

**Resultado esperado:** um escopo mínimo claro. O planejamento avançou; implementação e teste real permanecem pendentes.

## 2. Recuperar e reconciliar o documento de continuidade — próxima ação

- [ ] Recuperar o documento original mencionado na conversa.
- [ ] Revisar e remover informações confidenciais antes de incorporá-lo.
- [ ] Comparar decisões e andamento com os documentos atuais.
- [ ] Atualizar as lacunas e registrar eventuais divergências.

**Resultado esperado:** continuidade validada contra a fonte original.

## 3. Verificar a opção gratuita de infraestrutura — adiado

Etapa adiada a pedido do usuário por problemas de conexão. Retomar quando a conexão estiver normalizada.

- [ ] Acessar Computação > Instâncias no painel Oracle.
- [ ] Conferir região, capacidade disponível, elegibilidade gratuita e limites aplicáveis.
- [ ] Registrar uma configuração candidata e os custos exibidos, sem dados de conta ou credenciais.

**Resultado esperado:** uma opção concreta e revisada para o servidor, antes de sua criação.

## 4. Preparar a implantação

O n8n ainda não está em funcionamento, conforme relato do usuário. Após retomar e validar a configuração da infraestrutura e obter autorização para as ações necessárias:

- [ ] Criar e configurar o servidor.
- [ ] Preparar Docker, armazenamento persistente e n8n.
- [ ] Definir acesso administrativo, rede e proteção das credenciais.
- [x] Criar o bot do Telegram: Gestor, conforme relato do usuário.
- [x] Obter o ID do Telegram, conforme relato do usuário; valor fora do repositório.
- [ ] Configurar a integração do bot Gestor com o piloto escolhido.
- [ ] Implementar o cadastro, a listagem e a conclusão de tarefas.
- [ ] Documentar versões e procedimentos sem incluir valores secretos.

**Resultado esperado:** ambiente pronto para executar o piloto com o usuário autorizado.

## 5. Validar a operação e a continuidade

- [ ] Executar os critérios de aceite de PRIMEIRO_TESTE.md.
- [ ] Verificar tratamento de erros, duplicidade de eventos e persistência após reinício.
- [ ] Definir backups e testar a recuperação.
- [ ] Atualizar STATUS.md e DECISOES.md com evidências não confidenciais.

**Resultado esperado:** primeiro fluxo de tarefas validado e instruções suficientes para retomá-lo em outra conversa.
