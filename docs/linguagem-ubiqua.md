# Linguagem ubíqua (DDD)

Este documento define os termos do negócio usados **de forma idêntica** em conversas, na
documentação e no código. Sempre que um destes termos aparecer, ele significa exatamente o que
está descrito aqui — e é assim que ele é nomeado nas classes, funções e tabelas.

Por decisão do projeto, o código é escrito em **português**, então os nomes abaixo são também os
nomes reais no código (`usuario`, `video`, `status`, ...).

## Glossário

| Termo | Significado |
|---|---|
| **Usuário** | Pessoa autenticada por e-mail e senha. É dona dos vídeos que envia e só enxerga os próprios vídeos. |
| **Vídeo** | Arquivo enviado pelo usuário para processamento. Guarda o nome original, o status atual e, quando concluído, o caminho do pacote de frames. |
| **Envio** (upload) | Ato de o usuário submeter um vídeo. Não processa nada na hora: apenas registra o vídeo como `PENDENTE` e o coloca na fila. |
| **Frame** | Imagem extraída do vídeo. A extração pega **1 frame por segundo** de vídeo. |
| **Pacote de frames** (zip) | Arquivo `.zip` com todos os frames extraídos de um vídeo. É o que o usuário baixa ao final. |
| **Processamento** | Trabalho de extrair os frames de um vídeo e montar o pacote de frames. Acontece de forma assíncrona, fora da requisição do usuário. |
| **Status** | Situação atual de um vídeo no seu ciclo de vida (ver abaixo). |
| **Notificação** | Aviso enviado ao usuário por e-mail quando o processamento do seu vídeo falha. |
| **Resultado do processamento** | Informação que o processamento devolve sobre um vídeo: novo status e, conforme o caso, o caminho do pacote de frames ou a mensagem de erro. |

## Status do vídeo (ciclo de vida)

| Status | Significado |
|---|---|
| `PENDENTE` | O vídeo foi enviado e está na fila, aguardando processamento. |
| `PROCESSANDO` | O processamento começou (extração de frames em andamento). |
| `CONCLUIDO` | Os frames foram extraídos e o pacote de frames está disponível para download. |
| `ERRO` | O processamento falhou. O usuário é notificado por e-mail. |

Transições válidas:

```
PENDENTE ──> PROCESSANDO ──> CONCLUIDO
                        └──> ERRO
```

## Contexto delimitado (Bounded contexts)

Cada microsserviço é um contexto delimitado, com responsabilidade e vocabulário próprios. Eles
não compartilham banco de dados e conversam apenas por eventos (mensageria).

### 1. Identidade e Catálogo de Vídeos — serviço `fiapx-api`

Responsável por quem é o usuário e por tudo que ele enxerga sobre seus vídeos.

- Autentica o usuário (registro e login).
- Recebe o envio do vídeo e o registra como `PENDENTE`.
- Mantém o **catálogo**: a lista de vídeos de cada usuário e o status de cada um.
- Entrega o pacote de frames para download.
- É o **único contexto que possui banco de dados** (usuários e vídeos).

### 2. Processamento — serviço `fiapx-worker`

Responsável por transformar um vídeo em um pacote de frames.

- Recebe o pedido de processamento, extrai os frames e monta o pacote.
- **Não conhece usuário, banco de dados nem e-mail.** Seu vocabulário é apenas: vídeo de entrada,
  frames, pacote de frames, sucesso ou falha.
- Comunica o **resultado do processamento** por evento; quem interpreta e persiste isso é o
  contexto de Catálogo.

### 3. Notificação — serviço `fiapx-notificacao`

Responsável por avisar o usuário quando algo dá errado.

- Recebe o pedido de notificação (para quem, sobre qual vídeo, qual erro) e envia o e-mail.
- Não decide *quando* notificar: apenas executa o aviso solicitado.

## Como os contextos se relacionam

O fluxo é uma sequência de eventos, sem chamadas síncronas entre serviços:

```
Catálogo (api)    ──[vídeo para processar]──>   Processamento (worker)
Processamento     ──[resultado]──────────────>   Catálogo (api)
Catálogo (api)    ──[avisar usuário]─────────>   Notificação
```

Observação importante de vocabulário: o **Processamento** reporta um *resultado*; ele não "atualiza
o status". Quem traduz o resultado em mudança de status é o **Catálogo**, porque o status é um
conceito do catálogo — e é lá que ele é persistido.
