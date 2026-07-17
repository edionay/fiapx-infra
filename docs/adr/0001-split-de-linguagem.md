# ADR 0001 — Linguagens: Go no processamento, Node/TypeScript no restante

- **Status:** Aceito
- **Data:** 2026-07-16

## Contexto

O sistema já contava com uma implementação funcional do processamento de vídeo escrita em **Go**,
que usa `ffmpeg` para extrair os frames e monta o pacote `.zip`. Essa lógica é a parte mais
sensível do domínio — é onde estão o tratamento do arquivo, a invocação do `ffmpeg` e a geração do
resultado — e já estava validada.

Os demais serviços (autenticação, catálogo de vídeos, notificação) e a interface web ainda não
existiam e precisavam ser construídos do zero.

Era preciso decidir em qual linguagem escrever cada parte: padronizar tudo em uma só linguagem ou
combinar mais de uma conforme a aptidão de cada uma.

## Decisão

Adotar **duas linguagens**, cada uma onde tem mais valor:

- **Go** no serviço de **processamento** (`fiapx-worker`), reaproveitando a implementação existente
  de `ffmpeg` + `zip`. Go é forte para esse tipo de trabalho intensivo em CPU e I/O.
- **Node + TypeScript** em todo o **código novo** de aplicação (`fiapx-api`, `fiapx-notificacao`),
  onde o ecossistema oferece produtividade para APIs, geração de documentação (TSOA/OpenAPI),
  integração com fila, banco, SMTP e a equipe estava familiarizada com a criação de APIs com essa stack.
- **React + TypeScript** na **interface** (`fiapx-frontend`).

Os serviços são independentes e se comunicam por mensagens JSON, então a diferença de linguagem
entre eles não gera acoplamento.

## Consequências

### Positivas
- Reaproveita a lógica de processamento já validada, sem reescrevê-la e arriscar regressões.
- Cada parte usa a linguagem mais adequada ao seu trabalho.
- A comunicação por contrato de mensagem (JSON) mantém os serviços desacoplados, independentemente
  da linguagem interna de cada um.
- TypeScript no backend e no frontend compartilha a mesma linguagem entre quem faz API e interface.

### Negativas
- Duas stacks para manter: duas formas de build, teste, lint e imagem Docker.
- Não há reuso de tipos/código entre o worker (Go) e os serviços em TypeScript — o contrato das
  mensagens precisa ser mantido em sincronia manualmente nos dois lados.
- Quem for evoluir o sistema precisa transitar entre Go e TypeScript.

### Mitigações
- Os contratos de fila ficam documentados em um único lugar (a [arquitetura](../arquitetura.md)),
  reduzindo o risco de divergência entre os lados.
- Cada serviço tem CI próprio, então as duas stacks são exercitadas de forma isolada e automática.
