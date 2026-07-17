# Registros de Decisão de Arquitetura (ADR)

Um ADR (*Architecture Decision Record*) documenta uma decisão de arquitetura relevante: o
**contexto** em que ela foi tomada, a **decisão** em si e as **consequências**, positivas e
negativas. O objetivo é preservar o *porquê* das escolhas, não só o *o quê*, para que quem chegar
depois entenda o raciocínio sem precisar reconstruí-lo.

Cada registro é imutável: quando uma decisão é revista, cria-se um novo ADR que substitui o
anterior, em vez de reescrever o antigo.

## Índice

- [0001. Linguagens: Go no processamento, Node/TypeScript no restante](0001-split-de-linguagem.md)
- [0002. Um repositório por serviço](0002-repos-separados.md)
- [0003. Comunicação entre serviços por mensageria, não HTTP síncrono](0003-mensageria-vs-http.md)
- [0004. Clean Architecture por serviço](0004-clean-architecture.md)
- [0005. Coordenação do fluxo por coreografia (SAGA)](0005-saga-coreografia.md)
- [0006. Um banco por serviço, processamento sem estado](0006-database-per-service.md)
