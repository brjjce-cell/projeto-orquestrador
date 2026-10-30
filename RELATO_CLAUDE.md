# Relato de continuidade após delegação

Data: 30/10/2026.

Este documento resume o relato fornecido pelo usuário sobre a sessão de outro assistente. Os recursos da Oracle e o código mencionado não foram inspecionados diretamente nesta atualização.

## Infraestrutura relatada

- A região principal foi informada como São Paulo, e a conta está em avaliação gratuita.
- O outro assistente relatou criação da VCN `vcn-orquestrador`, com sub-redes pública e privada, gateway de internet, NAT gateway e service gateway. Relatou também regras de entrada para SSH e portas 80 e 443. Esses itens e as origens permitidas ainda precisam ser verificados diretamente.
- As tentativas de criar uma instância A1.Flex com 2 OCPUs / 12 GB e depois 1 OCPU / 6 GB teriam falhado por falta de capacidade. Segundo o relato, nenhuma instância foi criada. A afirmação de que não houve cobrança ainda depende de conferência na conta.
- O console teria apresentado uma estimativa positiva para o volume de boot. O enquadramento Always Free e qualquer consumo de créditos ou cobranças devem ser verificados no painel antes de concluir que o custo é zero.
- Foi relatado que uma chave privada SSH teria sido baixada pelo usuário. Sua existência, guarda e correspondência com a futura instância ainda precisam ser confirmadas pelo próprio usuário; nunca incluir a chave neste repositório.

## Artefatos relatados

- Script de inicialização para Docker, n8n, Caddy/HTTPS e medidas de acesso SSH.
- Fluxo n8n para cadastrar, listar e concluir tarefas pelo Telegram; o relato menciona teste local da lógica, sem teste real no Telegram.
- Documentação de continuidade produzida na outra sessão.

Posteriormente, o usuário forneceu README.md, STATUS.md, o fluxo JSON e o script cloud-init. O fluxo foi examinado com dados fictícios; o script foi revisado sem execução. Há problemas pendentes descritos em REVISAO_ARTEFATOS.md e REVISAO_CLOUD_INIT.md. Antes de importar, executar, provisionar ou substituir documentos existentes, corrigir os pontos encontrados e validar eventuais dados sensíveis.

## Pontos para conferir

1. Confirmar no painel a existência da VCN, gateways, sub-redes, regras e seus custos; revisar especialmente se a rede expõe SSH desnecessariamente.
2. A declaração de que todos os gateways são gratuitos e de que não houve cobrança não foi verificada nesta sessão. Conferir recursos, uso de créditos e Análise de Custos.
3. Revisar o script de inicialização e a proteção do primeiro acesso do n8n antes de publicar o serviço na internet; não presumir que HTTPS, autenticação e proteção de credenciais estejam configurados corretamente.
4. O fluxo recebido aceita tanto `/listar` quanto `/lista`; corrigir e testar os demais pontos registrados em REVISAO_ARTEFATOS.md antes de ativá-lo.
5. Confirmar os arquivos e resultados reais dos testes; preservar os documentos existentes durante a integração dos artefatos.
6. Quando houver disponibilidade, tentar novamente a instância A1.Flex dentro do escopo gratuito. Não fazer upgrade nem contratar serviços pagos.

## Correção do limite A1

O relato intermediário mencionou 4 OCPUs / 24 GB como Always Free. A documentação oficial atual da Oracle informa que, para continuar como usuário Always Free após o período de avaliação, o total entre instâncias A1 da conta deve ser de até **2 OCPUs e 12 GB de memória**. A documentação também descreve 1.500 horas de OCPU e 9.000 GB-horas mensais. Ver [Oracle Free Tier](https://docs.oracle.com/pt-br/iaas/Content/FreeTier/freetier.htm) e [Recursos Always Free](https://docs.oracle.com/pt-br/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm).

Não há comprovação nesta sessão de que qualquer configuração A1 acima desse limite tenha sido criada.
