# Próximos passos

Data de referência: 30/10/2026. Esta lista é um plano; não autoriza contratações, exposição de serviços ou alterações fora do novo repositório.

## 1. Verificar a opção gratuita de infraestrutura

- [ ] Acessar Computação > Instâncias no painel Oracle.
- [ ] Conferir região, capacidade disponível, elegibilidade gratuita e limites aplicáveis.
- [ ] Registrar uma configuração candidata e os custos exibidos, sem dados de conta ou credenciais.

**Resultado esperado:** uma opção concreta e revisada para o servidor, antes de sua criação.

## 2. Recuperar e reconciliar o documento de continuidade

- [ ] Recuperar o documento original mencionado na conversa.
- [ ] Revisar e remover informações confidenciais antes de incorporá-lo.
- [ ] Comparar decisões e andamento com os documentos atuais.
- [ ] Atualizar as lacunas e registrar eventuais divergências.

**Resultado esperado:** continuidade validada contra a fonte original.

## 3. Definir o primeiro teste

- [ ] Escolher um fluxo pequeno com entrada e resultado verificáveis.
- [ ] Definir quais tarefas cabem ao n8n, ao orquestrador e a cada agente.
- [ ] Definir os serviços necessários e eventuais custos de API.
- [ ] Definir critérios de aprovação humana e de conclusão do teste.

**Resultado esperado:** escopo mínimo claro, com custo e comportamento esperados.

## 4. Preparar a implantação

Após validar a configuração e obter autorização para as ações de infraestrutura:

- [ ] Criar e configurar o servidor.
- [ ] Preparar Docker, armazenamento persistente e n8n.
- [ ] Definir acesso administrativo, rede e proteção das credenciais.
- [ ] Configurar o Telegram para o fluxo escolhido.
- [ ] Documentar versões e procedimentos sem incluir valores secretos.

**Resultado esperado:** ambiente acessível apenas conforme as permissões definidas e pronto para um teste controlado.

## 5. Validar a operação e a continuidade

- [ ] Executar o primeiro fluxo e verificar o resultado.
- [ ] Verificar tratamento de erros e aprovações.
- [ ] Definir backups e testar a recuperação.
- [ ] Atualizar STATUS.md e DECISOES.md com evidências não confidenciais.

**Resultado esperado:** primeira automação validada e instruções suficientes para retomá-la em outra conversa.
