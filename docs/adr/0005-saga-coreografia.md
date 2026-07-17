# ADR 0005: Coordenação do fluxo por coreografia (SAGA)

- **Status:** Aceito
- **Data:** 2026-07-16

## Contexto

O processamento de um vídeo envolve mais de um serviço. A `fiapx-api` recebe o envio e registra o
vídeo, o `fiapx-worker` extrai os frames e monta o pacote, e a `fiapx-notificacao` avisa o usuário
quando algo falha. Não há um banco de dados compartilhado nem uma transação única que abranja os
três, então cada passo confirma a sua parte de forma independente.

Era preciso decidir **como coordenar** essa sequência de passos entre serviços: com um componente
central comandando cada etapa, ou deixando cada serviço reagir aos eventos por conta própria.

O padrão SAGA trata justamente disso, coordenar uma operação que atravessa vários serviços sem uma
transação distribuída, e tem duas formas:

- **Orquestração:** um serviço central comanda a sequência e diz a cada participante o que fazer.
- **Coreografia:** não há maestro. Cada serviço publica eventos e reage aos eventos dos outros.

## Decisão

Adotar a **coreografia**. Cada serviço reage a um evento e publica o próximo, sem um orquestrador
central:

1. A `api` registra o vídeo como `PENDENTE` e publica o pedido de processamento.
2. O `worker` consome o pedido, processa e publica o **resultado** (sucesso ou falha).
3. A `api` consome o resultado, atualiza o status e, se foi falha, publica o pedido de notificação.
4. A `notificacao` consome esse pedido e envia o e-mail.

O passo compensatório da saga é o **caminho de erro**: quando o processamento falha, o estado é
levado a `ERRO` e o usuário é avisado, fechando o fluxo de forma controlada em vez de deixá-lo pela
metade.

## Consequências

### Positivas
- **Baixo acoplamento:** cada serviço conhece apenas os eventos que consome e produz, não os demais
  serviços. Dá para adicionar um novo interessado em um evento sem alterar quem o publica.
- **Sem ponto único de coordenação:** não há um orquestrador que precise conhecer todos os passos e
  que vire gargalo ou ponto único de falha.
- **Encaixe natural com a mensageria:** a coreografia usa as mesmas filas que já sustentam a
  comunicação assíncrona (ver [ADR 0003](0003-mensageria-vs-http.md)).

### Negativas
- **Visão distribuída do fluxo:** não existe um lugar único que descreva a saga inteira. Entender a
  sequência exige olhar quem publica e quem consome cada evento.
- **Rastreamento mais difícil:** seguir um vídeo específico do início ao fim passa por várias filas
  e serviços, o que dificulta o diagnóstico quando algo dá errado.
- **Compensação limitada:** a coreografia deste projeto trata o erro avisando o usuário, mas não
  desfaz efeitos de passos anteriores, porque o fluxo não cria estados que precisem ser revertidos.

### Mitigações
- O fluxo completo (sucesso e erro) está desenhado na [arquitetura](../arquitetura.md), suprindo a
  falta de um ponto único de descrição no código.
- O acompanhamento distribuído (tracing) está registrado em
  [Limitações conhecidas](../limitacoes-conhecidas.md) como evolução.

## Alternativa considerada

**Orquestração:** um serviço central conduziria a sequência, chamando cada participante e tratando
as compensações. Facilita enxergar e controlar o fluxo em um só lugar, mas adiciona um componente
central para manter, reintroduz acoplamento (o orquestrador precisa conhecer todos os passos) e
seria desproporcional para um fluxo curto e praticamente linear como este. A orquestração se
justifica quando há muitos passos, ramificações e compensações reais, o que não é o caso aqui.
