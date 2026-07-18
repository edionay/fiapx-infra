# Limitações conhecidas

Este documento reúne, em um só lugar, o que o sistema **ainda não cobre** — e como cada ponto seria
endereçado. Ele existe porque uma arquitetura só é defensável quando os seus limites são
explícitos: o que está aqui foi deixado de fora conscientemente, não por descuido.

Cada item traz a **limitação**, o **impacto** de conviver com ela e o **encaminhamento** previsto.
Itens marcados como *planejado* já têm solução desenhada e endereçada no roadmap imediato; os
demais são evoluções de médio prazo.

## Privacidade e proteção de dados

Complementa a [nota de privacidade](lgpd.md).

| Limitação | Impacto | Encaminhamento |
|---|---|---|
| Arquivos e banco sem **criptografia em repouso** | Quem obtiver acesso ao volume, ao host ou a um backup lê os vídeos e frames diretamente | Volume/disco criptografado ou object storage com criptografia do lado do servidor, com gestão de chaves |
| **Expurgo por retenção não automatizado** | A política de 7 dias não é cumprida sozinha; pacotes se acumulam indefinidamente | Rotina periódica de expurgo dos pacotes vencidos — *planejado* |
| **Exclusão pelo titular** indisponível | O usuário não consegue apagar os próprios vídeos por autosserviço; o direito de eliminação depende de ação manual | Endpoint `DELETE /videos/:id`, validando propriedade — *planejado* |
| **Exclusão de conta** indisponível | O titular não consegue encerrar o cadastro e eliminar todos os seus dados de uma vez | Endpoint de exclusão de conta com remoção em cascata de vídeos e pacotes |
| Vídeos em `ERRO` **permanecem** no volume | Dado pessoal retido depois de cumprida (ou frustrada) a finalidade | Incluir os vídeos em `ERRO` no expurgo automatizado — *planejado* |
| Sem **registro de consentimento** e sem **trilha de auditoria** | Não há prova de base legal nem rastro de quem acessou o quê | Registro de aceite no cadastro e log de auditoria de acesso a dado pessoal |

## Segurança

| Limitação | Impacto | Encaminhamento |
|---|---|---|
| Tráfego em **HTTP**, sem TLS | Credenciais, token e conteúdo trafegam em texto claro | TLS terminado no proxy/ingress, com redirecionamento obrigatório |
| **JWT sem revogação nem refresh** | Um token vazado continua válido até expirar; não há como invalidá-lo | Refresh token com tokens de acesso curtos e lista de revogação |
| Sem **rate limiting** no login | Tentativa de força bruta contra senhas não encontra barreira | Rate limit por IP/conta e bloqueio progressivo |
| Segredos em **variáveis de ambiente** | Adequado para o ambiente atual, mas sem rotação nem cofre | Gerenciador de segredos (Vault, Secrets Manager) com rotação |

## Resiliência

| Limitação | Impacto | Encaminhamento |
|---|---|---|
| Sem **reprocessamento automático de falhas** | Quando o processamento falha, o erro é registrado e o usuário avisado, mas o sistema não tenta de novo sozinho | Repetir a tentativa automaticamente e separar os casos que falham várias vezes para análise |
| **Processamento não idempotente** | A entrega é *at-least-once*: se a mesma mensagem chegar duas vezes, o vídeo é processado duas vezes | Descartar o pedido quando o vídeo já saiu de `PENDENTE`, ou usar chave de idempotência |
| **Postgres sem réplica nem backup** | Ponto único de falha; perda do volume significa perda dos dados | Réplica de leitura, backup periódico e teste de restauração |

## Escalabilidade e operação

| Limitação | Impacto | Encaminhamento |
|---|---|---|
| **Escala manual** dos workers (`--scale`) | O sistema não reage sozinho a picos; alguém precisa dimensionar | Kubernetes com HPA, escalando por CPU ou pelo tamanho da fila |
| **Volume compartilhado** entre api e worker | Prende os serviços ao mesmo host e dificulta a distribuição | Object storage (S3/MinIO), removendo o filesystem compartilhado |
| Sem **tracing distribuído** | Métricas mostram o quê, mas não permitem seguir um vídeo específico entre os serviços | OpenTelemetry com exportação para Jaeger |
| **Mailhog** como servidor de e-mail | Captura as mensagens para inspeção; não entrega e-mail de verdade | Provedor SMTP real (SES, SendGrid) com domínio verificado |

## O que está fora de discussão

Alguns pontos podem parecer ausências, mas são decisões deliberadas e não limitações:

- **Não há HTTP síncrono entre serviços.** É intencional: a comunicação assíncrona por fila é o que
  absorve picos e permite escalar o processamento. Ver [arquitetura](arquitetura.md).
- **O worker não tem banco de dados.** Também intencional: ele não precisa de estado e, sem acesso
  a dados pessoais, a superfície de exposição diminui.
- **Não há orquestrador central da saga.** A coreografia por eventos é suficiente para um fluxo
  linear como este; um orquestrador só se justificaria com muitos passos e compensações reais.
