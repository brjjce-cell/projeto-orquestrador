# Continuidade da configuração Oracle

Atualização: 30/10/2026. Este registro resume capturas de tela e relatos do usuário; não substitui a conferência no painel.

## O que foi observado

- Conta Free Tier em avaliação; região exibida: Brazil East (São Paulo). A região principal da conta e a elegibilidade precisam ser conferidas.
- A lista de instâncias não mostrava itens no compartimento e na região selecionados; isso não confirma a inexistência de recursos em outros escopos.
- No formulário da instância, foi selecionado Ubuntu 24.04 Minimal aarch64.
- Foi selecionada a forma VM.Standard.A1.Flex, apresentada como elegível ao Always Free, com 2 OCPUs, 12 GB de memória e desempenho expansível desligado.
- Ao tentar criar uma VCN e uma sub-rede pública pelo formulário, a opção de atribuir IPv4 público permaneceu desabilitada e exibiu aviso para selecionar uma sub-rede pública, mesmo após nova seleção.
- O usuário abriu em outra aba o formulário separado para criar uma VCN. A criação dessa rede e da instância não foi confirmada.
- O controle do navegador do assistente falhou ao iniciar. O usuário perguntou sobre delegar a continuação a outro assistente com acesso ao navegador.

## Próximas verificações

1. Conferir o estado atual do formulário e se alguma VCN ou sub-rede já foi criada; evitar criar recursos duplicados.
2. Configurar uma VCN e sub-rede pública adequadas, com gateway de internet, rota e regras necessárias ao acesso. Verificar os recursos selecionados e seus custos antes de criá-los.
3. Selecionar a VCN e sub-rede criadas no formulário da instância e verificar a atribuição de IPv4 público.
4. Preparar o acesso SSH: usar ou gerar uma chave pública apropriada e manter a chave privada sob guarda do usuário, fora do repositório e das conversas.
5. Revisar imagem, forma, memória, armazenamento, recursos de rede e custo estimado no resumo; confirmar que estão dentro dos limites Always Free antes de criar a instância. Não fazer upgrade de conta nem contratar recursos pagos.
6. Após a criação, validar o acesso e só então preparar Docker, n8n e o piloto do bot Gestor.

**Limites conhecidos:** a documentação oficial da Oracle consultada nesta conversa informa um total de 2 OCPUs e 12 GB Always Free para A1 em contas Always Free; o uso é compartilhado com outras instâncias A1 e sujeito a limites, região e disponibilidade. A estimativa de custo e a disponibilidade da conta precisam de confirmação no painel.

**Credenciais:** não registrar chaves privadas, tokens, identificadores pessoais ou dados de acesso neste repositório.
