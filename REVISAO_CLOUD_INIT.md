# Revisão do script de inicialização

Data: 30/10/2026.

Arquivo recebido: `cloud-init-orquestrador.sh`.
SHA-256 da versão revisada: `cc1644797795cef9e3af034822795bd7d76cf952b7d8f9437f169b8fedbfacf4`.

## Escopo da revisão

O conteúdo foi examinado sem executá-lo. A verificação `bash -n` não encontrou erro de sintaxe; isso não comprova instalação, segurança ou funcionamento na Oracle. Uma busca por padrões comuns não identificou credenciais no arquivo, mas não substitui revisão de segredos. O script recebido não foi incluído neste repositório nem aplicado a servidor.

## Pontos que exigem correção ou validação antes de criar a instância

1. **Primeiro acesso ao n8n:** o Compose publica as portas 80 e 443 do Caddy em todas as interfaces e encaminha as requisições ao n8n. O próprio relato da outra sessão informa que a configuração inicial de proprietário ficará disponível no primeiro acesso. Se as regras da rede permitirem acesso público antes da criação da conta, outra pessoa pode alcançar essa tela primeiro. Restringir o acesso durante a configuração inicial e validar o acesso antes de abrir o serviço. HTTPS protege o transporte, mas não cria uma conta de proprietário por si só. Ver [configuração de usuários do n8n](https://docs.n8n.io/deploy/host-n8n/configure-n8n/user-management.md) e [publicação de portas do Docker](https://docs.docker.com/engine/network/port-publishing/).
2. **Chave de criptografia em reexecução:** o script gera uma nova chave e sobrescreve `/opt/orquestrador/.env` a cada execução. Se já existirem credenciais no volume persistente do n8n, trocar a chave pode impedir sua descriptografia. Preservar a chave existente, impedir sobrescrita acidental e definir backup protegido. Ver [chave de criptografia do n8n](https://docs.n8n.io/hosting/configuration/configuration-examples/encryption-key/).
3. **Regras de rede e firewall:** o script abre 80 e 443 no host e publica essas portas pelo Docker. Regras inseridas na cadeia INPUT não bastam, isoladamente, para concluir que as portas publicadas de contêineres estão protegidas; verificar regras efetivas da Oracle e do Docker. Ver [filtragem de pacotes do Docker](https://docs.docker.com/engine/network/packet-filtering-firewalls/).
4. **SSH:** o arquivo `99-hardening.conf` pode não prevalecer sobre valores definidos anteriormente; o OpenSSH normalmente usa o primeiro valor obtido. Além disso, a recarga do serviço termina com `|| true`, ocultando eventual falha. Validar sintaxe e configuração efetiva com `sshd` antes de recarregar e manter um caminho de recuperação. Ver [manual do OpenSSH](https://man.openbsd.org/sshd_config).
5. **Versões dos contêineres:** o script usa `latest` para n8n e uma tag móvel para Caddy. Fixar versões testadas e definir como atualizar reduz mudanças inesperadas; confirmar compatibilidade com o fluxo JSON antes de implantar.
6. **Privilégios e dependências:** o usuário `ubuntu` é incluído no grupo Docker, que dá privilégios equivalentes a root; avaliar se isso é necessário. O script também depende de um serviço externo para descobrir o IP e interrompe a execução caso a consulta falhe. Ver [pós-instalação do Docker](https://docs.docker.com/engine/install/linux-postinstall/).
7. **Erro no firewall:** a inserção fixa na posição 5 do INPUT pode falhar se essa posição não existir; com `set -e`, isso pode interromper a configuração parcialmente. Testar as regras em um ambiente equivalente e manter o acesso SSH recuperável.

## Próxima etapa

Preparar uma versão corrigida, preservando a configuração existente em reexecuções; definir um primeiro acesso restrito; revisar as regras efetivas da rede; e testar a instalação em ambiente adequado. Revisar também os problemas do fluxo em REVISAO_ARTEFATOS.md. Enquanto não houver uma versão revisada e capacidade Oracle, a criação da instância com o script atual deve permanecer pendente.
