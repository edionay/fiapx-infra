# fiapx-infra

Repositório de infraestrutura e documentação do Sistema de Processamento de Vídeos FIAP X.

Reúne o que amarra os microsserviços do projeto:

- **Orquestração:** `docker-compose.yml` que sobe a stack. Hoje já traz o **backbone de
  mensageria** (RabbitMQ), o **Postgres**, a **api**, o **worker** e a **notificacao** (com um
  **Mailpit** de caixa de correio para desenvolvimento), com um **volume compartilhado** montado
  em `/data`. Os demais serviços (frontend) e a observabilidade entram conforme cada um é
  construído.
- **Contratos de fila** (`docs/contratos-fila.md`): a fonte da verdade das mensagens trocadas
  entre os serviços.
- **Documentação** (`docs/`): linguagem ubíqua (DDD), arquitetura, cenários BDD, registros de
  decisão (ADR) e nota de LGPD.

## Serviços do sistema

| Repositório | Papel | Stack |
|---|---|---|
| `fiapx-api` | Autenticação, upload, status e download | Node + TypeScript (TSOA/Swagger) |
| `fiapx-worker` | Processamento do vídeo (ffmpeg + zip) | Go |
| `fiapx-notificacao` | Envio de e-mail em caso de erro | Node + TypeScript |
| `fiapx-frontend` | Interface web | React + Tailwind |
| `fiapx-infra` | Infraestrutura e documentação | Docker Compose |

## Como rodar

Os 5 repositórios são clonados como **irmãos** dentro de uma pasta de trabalho comum. A stack é
subida **de dentro do `fiapx-infra`**, cujo `docker-compose.yml` referencia os repos vizinhos por
caminho relativo (`build: ../fiapx-api`, etc.).

```
Dev/                        <- pasta de trabalho comum (não é um repositório)
├── fiapx-api/              (Dockerfile + db/init.sql)
├── fiapx-worker/           (Dockerfile)
├── fiapx-notificacao/      (Dockerfile)
├── fiapx-frontend/         (Dockerfile)
└── fiapx-infra/            ← rode a partir daqui
    └── docker-compose.yml
```

```bash
cd fiapx-infra
docker compose up --build
```

Sobe agora: **RabbitMQ** (AMQP em `5672`, painel de management em
[localhost:15672](http://localhost:15672), usuário/senha `fiapx`/`fiapx`), **Postgres** (`5432`),
a **api** (`3000`, Swagger em `/docs`), o **worker** e a **notificacao**, com as migrações
aplicadas antes da api iniciar. O worker e a notificacao consomem suas filas e expõem métricas em
`9091` dentro da rede do Compose, sem porta publicada no host. Os e-mails de falha caem no
**Mailpit**, com a caixa de entrada em [localhost:8025](http://localhost:8025).

## Desenvolvimento

Este repositório bloqueia **commits diretos na branch `main`** por meio de um hook versionado em
`.githooks/pre-commit`. Como o Git não ativa hooks versionados automaticamente, após clonar rode
uma vez:

```bash
sh scripts/ativar-hooks.sh
```

ou, de forma equivalente:

```bash
git config core.hooksPath .githooks
```

A partir daí, o trabalho é feito em uma branch (`git switch -c minha-branch`) e integrado à `main`
por pull request. Para uma exceção pontual existe o `git commit --no-verify`.

## Documentação

- [Linguagem ubíqua (DDD)](docs/linguagem-ubiqua.md)
- [Arquitetura](docs/arquitetura.md)
- [Contratos de fila](docs/contratos-fila.md)
- [LGPD](docs/lgpd.md)
- [Limitações conhecidas](docs/limitacoes-conhecidas.md)
- Cenários BDD: `docs/bdd/`
- Registros de decisão (ADR): `docs/adr/`
