# ADR 0006: Um banco por serviço, processamento sem estado

- **Status:** Aceito
- **Data:** 2026-07-16

## Contexto

Em uma arquitetura de microsserviços, um antipadrão comum é vários serviços compartilharem o mesmo
banco de dados. Quando isso acontece, o banco vira um ponto de acoplamento: a mudança no schema
feita por um serviço quebra os outros, e ninguém é de fato dono dos dados.

No sistema, três serviços participam do fluxo. A `fiapx-api` cuida de usuários e do catálogo de
vídeos (com o status de cada um), o `fiapx-worker` faz o processamento, e a `fiapx-notificacao`
envia e-mails. Era preciso decidir quem guarda o quê, e evitar que o worker escrevesse direto na
mesma base da api, como uma versão inicial chegou a considerar.

## Decisão

Aplicar **database-per-service**: cada serviço é dono exclusivo dos seus dados e nenhum acessa o
banco de outro. Na prática, apenas a **api** precisa de banco:

- **api:** dona do Postgres, com as tabelas de `usuarios` e `videos`. É o único serviço que lê e
  escreve dados pessoais e o estado dos vídeos.
- **worker:** **sem estado (stateless)**. Recebe o pedido, processa e publica o resultado por
  evento. Não acessa banco. É a api que consome esse resultado e atualiza o próprio banco.
- **notificacao:** sem estado. Apenas envia o e-mail pedido, sem persistir nada.

Como o worker não escreve mais o status diretamente, foi criada a fila `videos.resultado`, pela
qual ele reporta o andamento (`PROCESSANDO`, `CONCLUIDO` ou `ERRO`) para a api aplicar no banco.

## Consequências

### Positivas
- **Sem acoplamento por banco:** o schema pertence a um único serviço e pode evoluir sem quebrar os
  outros.
- **Dono claro dos dados:** o status é um conceito do catálogo, então faz sentido que só a api o
  escreva. O worker reporta um fato (o resultado), a api decide como isso vira estado.
- **Menor exposição de dado pessoal:** o worker processa o vídeo sem saber de quem ele é, sem acesso
  a e-mail ou banco, o que reduz a superfície de exposição (ver [LGPD](../lgpd.md)).
- **Escala e reinício simples:** serviços sem estado sobem, caem e escalam sem coordenação de dados.

### Negativas
- **Mais um evento no fluxo:** a atualização de status deixa de ser uma escrita direta e passa a
  depender da fila `videos.resultado`, adicionando um salto assíncrono.
- **Consistência eventual:** entre o worker terminar e a api processar o resultado, há uma pequena
  janela em que o status exibido está atrás do estado real.
- **Concentração na api:** sendo o único serviço com banco, a api acumula a responsabilidade de
  persistência do sistema.

### Mitigações
- O salto extra reaproveita a mensageria que já existe, sem nova infraestrutura.
- A janela de inconsistência é curta e aceitável para o caso de uso (o usuário acompanha o status
  por atualização periódica, não em tempo real).

## Alternativa considerada

**Dar um banco próprio ao worker**, com metadados de processamento. Cumpriria igualmente a regra de
não compartilhar banco, e demonstraria dois bancos de forma concreta, mas adicionaria um Postgres e
mais código para persistir dados que o sistema não precisa guardar. O worker não tem estado próprio
que justifique persistência, então mantê-lo sem estado é mais simples e igualmente correto quanto ao
database-per-service.
