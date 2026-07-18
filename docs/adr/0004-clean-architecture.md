# ADR 0004: Clean Architecture por serviço

- **Status:** Aceito
- **Data:** 2026-07-16

## Contexto

A versão anterior do sistema misturava, no mesmo arquivo, o recebimento HTTP, a chamada ao
`ffmpeg`, o acesso ao disco e até o HTML da interface. Tudo acoplado, difícil de testar sem subir a
aplicação inteira e difícil de evoluir sem risco.

Cada serviço da nova arquitetura precisa de uma organização interna que separe a **regra de
negócio** dos **detalhes de infraestrutura** (framework web, banco, fila, e-mail), para permitir
testes isolados e troca de tecnologia sem reescrever o núcleo.

## Decisão

Adotar a **Clean Architecture** em cada serviço, organizando o código em camadas
concêntricas com as dependências sempre apontando para dentro:

- **`dominio`** (Entities): entidades e regras puras (o que é um `Usuario`, um `Video`, os status
  válidos). Não conhece framework, banco nem fila.
- **`aplicacao`** (Use Cases): os casos de uso (ex.: `autenticarUsuario`, `enviarVideo`,
  `processarVideo`), que orquestram o domínio. Dependem apenas de **portas** (interfaces de
  entrada/saída definidas pelos próprios casos de uso), como `RepositorioDeVideo` e
  `PublicadorDeFila`, nunca de implementações concretas.
- **`adaptadores`** (Interface Adapters): as implementações concretas dessas portas (controllers
  web, repositório em Postgres, publicador/consumidor RabbitMQ, envio SMTP). É onde os frameworks
  (Frameworks & Drivers) vivem.

O acoplamento é evitado pela **Regra da Dependência**: o domínio e os casos de uso não sabem que
existe Express, Postgres ou RabbitMQ; são os adaptadores que dependem das portas, e não o contrário.

Interfaces são criadas **onde há uma fronteira real** (repositório, fila, mailer, armazenamento),
que é onde a Regra da Dependência precisa ser aplicada, e não por completude. É a aplicação do
princípio de manter o design tão simples quanto a arquitetura permite.

## Dados que cruzam fronteiras (DTOs)

A Clean Architecture exige que o que **atravessa uma fronteira** seja uma estrutura simples,
desacoplada dos modelos internos, e não impõe DTOs entre todas as camadas. Neste sistema, os DTOs
existem exatamente nas fronteiras que importam:

- **Borda HTTP:** os modelos de request/response gerados pelo TSOA. São o contrato da API,
  separado das entidades de domínio, então mudar a entidade `Video` não muda o contrato exposto.
- **Borda das filas:** os contratos de mensagem (`videos.processar`, `videos.resultado`,
  `notificacoes`). O JSON que trafega é o formato de fronteira, independente do modelo interno.

Não há DTO redundante **entre camadas internas** (nem *mappers* de ida e volta para levar dado do
caso de uso ao domínio): o domínio já é a estrutura adequada ali, e duplicá-lo seria cerimônia sem
ganho. Os DTOs estão onde há fronteira; as entidades ficam no núcleo.

## Consequências

### Positivas
- **Testabilidade:** os casos de uso são testados com *fakes* das portas, sem subir banco nem fila.
- **Baixo acoplamento:** trocar Express, Postgres ou RabbitMQ afeta um adaptador, não a regra.
- **Legibilidade:** a estrutura de pastas comunica a intenção; olhar `aplicacao/` mostra o que o
  serviço faz, sem ruído de infraestrutura.
- **Consistência:** todos os serviços seguem o mesmo desenho, então navegar entre eles é previsível.

### Negativas
- **Mais arquivos e indireção** do que uma abordagem direta: uma porta e um adaptador onde haveria
  uma única função.
- **Curva de aprendizado:** exige entender o fluxo de dependências (o que pode depender de quê) para
  não "furar" as camadas.
- **Risco de cerimônia excessiva** se as interfaces e os DTOs forem multiplicados além das
  fronteiras reais, daí a regra explícita de só abstrair onde a Regra da Dependência exige.

### Mitigações
- A regra "interface e DTO onde há fronteira real" é o limite que impede a arquitetura de virar
  burocracia.
- Serviços pequenos (notificação) usam uma versão enxuta das camadas, sem forçar estrutura além do
  necessário.

## Alternativa considerada

**Camadas simples (controller → serviço → repositório), sem inversão de dependência.** Menos
arquivos e mais imediata, mas acopla a regra de negócio ao framework e ao banco, dificultando o
teste isolado, justamente o problema da versão anterior que se quer evitar. A Clean Architecture
entrega o desacoplamento com a disciplina da Regra da Dependência.
