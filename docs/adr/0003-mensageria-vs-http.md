# ADR 0003 — Comunicação entre serviços por mensageria, não HTTP síncrono

- **Status:** Aceito
- **Data:** 2026-07-16

## Contexto

O processamento de um vídeo é demorado (extração de frames com `ffmpeg`) e o volume de envios é
irregular: pode chegar um punhado de vídeos e, logo depois, dezenas de uma vez. Dois requisitos são
explícitos: processar mais de um vídeo ao mesmo tempo e **não perder requisições em picos**.

Era preciso decidir como o serviço que recebe o envio (`fiapx-api`) aciona o serviço que processa
(`fiapx-worker`), e como o resultado volta.

Duas abordagens estavam em jogo:

- **HTTP síncrono:** a api chama o worker diretamente e espera a resposta.
- **Mensageria:** a api publica um pedido em uma fila; o worker consome quando estiver disponível.

## Decisão

A comunicação **entre serviços de backend** é feita por **mensageria (RabbitMQ)**, de forma
assíncrona. O `fiapx-api` publica o pedido em `videos.processar` e responde ao usuário
imediatamente; o `fiapx-worker` consome no seu ritmo e publica o resultado em `videos.resultado`.

O **HTTP** fica restrito à borda síncrona, onde o cliente precisa de resposta imediata:
**frontend → api** (login, envio, consulta de status, download).

## Consequências

### Positivas
- **Absorve picos:** um pico de envios vira uma fila que cresce, não requisições derrubadas. A api
  aceita todos e o processamento acontece na vazão possível.
- **Escala horizontal simples:** vários workers consomem a mesma fila competindo pelas mensagens;
  aumentar a vazão é subir mais instâncias, sem a api saber quantas existem.
- **Tolerância a falha:** se um worker cai no meio, a mensagem não é confirmada e volta para a fila,
  sendo reprocessada por outro. Nada se perde.
- **Desacoplamento temporal:** api e worker não precisam estar disponíveis ao mesmo tempo.

### Negativas
- **Complexidade de infraestrutura:** exige um broker (RabbitMQ) para operar, monitorar e manter.
- **Fluxo assíncrono é mais difícil de seguir:** não há uma resposta direta; acompanhar um vídeo
  ponta a ponta exige olhar filas e status em vez de um único request/response.
- **Consistência eventual:** o status que o usuário vê pode estar momentaneamente atrás do estado
  real, até a mensagem de resultado ser processada.
- **Entrega ao menos uma vez:** a mesma mensagem pode ser entregue mais de uma vez, o que exige
  atenção para não processar o mesmo vídeo em duplicidade.

### Mitigações
- O usuário recebe `202` e acompanha o andamento pela listagem de status (consulta HTTP), o que
  torna a assincronia visível e aceitável do ponto de vista de experiência.
- O tratamento de reentrega e o reprocessamento automático de falhas estão registrados em
  [Limitações conhecidas](../limitacoes-conhecidas.md) como evolução.

## Alternativa considerada

**HTTP síncrono entre api e worker.** Mais simples de entender e depurar (uma chamada, uma
resposta), mas incompatível com os requisitos: em um pico, ou o worker tenta atender tudo ao mesmo
tempo e degrada, ou a api precisa segurar/recusar chamadas — perdendo requisições. Além disso,
acoplaria a disponibilidade dos dois serviços e dificultaria a escala independente do processamento.
