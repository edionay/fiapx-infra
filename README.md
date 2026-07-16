# fiapx-infra

Repositório de infraestrutura e documentação do Sistema de Processamento de Vídeos FIAP X.

Reúne o que amarra os microsserviços do projeto:

- **Orquestração:** `docker-compose.yml` que sobe toda a stack (Postgres, Redis, RabbitMQ,
  Mailhog, Prometheus, Grafana) e os serviços de aplicação.
- **Monitoramento:** configuração do Prometheus e provisionamento do Grafana.
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

## Documentação

- [Linguagem ubíqua (DDD)](docs/linguagem-ubiqua.md)
- [Arquitetura](docs/arquitetura.md)
- [LGPD](docs/lgpd.md)
- [Limitações conhecidas](docs/limitacoes-conhecidas.md)
- Cenários BDD: `docs/bdd/`
- Registros de decisão (ADR): `docs/adr/`
