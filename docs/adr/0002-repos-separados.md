# ADR 0002 — Um repositório por serviço

- **Status:** Aceito
- **Data:** 2026-07-16

## Contexto

O sistema é composto por serviços independentes (`fiapx-api`, `fiapx-worker`, `fiapx-notificacao`),
uma interface (`fiapx-frontend`) e a infraestrutura/documentação (`fiapx-infra`). Era preciso
decidir como versioná-los: em um único repositório (monorepo) ou em repositórios separados.

Cada serviço tem stack própria (ver [ADR 0001](0001-split-de-linguagem.md)), ciclo de build e de
teste próprios, e não compartilha código com os demais — a comunicação é por contrato de mensagem.

## Decisão

Adotar **um repositório por serviço**: `fiapx-api`, `fiapx-worker`, `fiapx-notificacao`,
`fiapx-frontend` e `fiapx-infra`, cada um com seu próprio histórico, CI e imagem Docker.

Para rodar o sistema completo, os repositórios são clonados lado a lado e a stack sobe a partir do
`fiapx-infra`, cujo `docker-compose.yml` referencia os serviços vizinhos como contexto de build.

## Consequências

### Positivas
- Cada serviço tem ciclo de vida independente: versiona, testa e publica sem arrastar os outros.
- Fronteiras nítidas — o repositório reforça a separação entre os serviços; não há atalho para
  acoplá-los por um `import` indevido.
- CI menor e mais rápido por repositório, exercitando só a stack daquele serviço.
- O quality gate (SonarCloud) é avaliado por serviço, com métricas isoladas.

### Negativas
- Uma mudança que atravessa serviços (ex.: alterar um contrato de mensagem) exige commits e PRs em
  mais de um repositório, sem uma visão atômica da alteração.
- Mais cerimônia operacional: cinco repositórios para clonar, configurar e manter.
- O `docker-compose.yml` depende de os repositórios estarem clonados juntos e com os nomes
  esperados — a montagem local é mais frágil do que em um monorepo.
- Não há um ponto único para versionar o sistema como um todo.

### Mitigações
- O `fiapx-infra` centraliza a orquestração e a documentação, funcionando como ponto de entrada.
- Os contratos de mensagem são documentados na [arquitetura](../arquitetura.md), tornando explícito
  o que precisa mudar em conjunto quando um contrato evolui.