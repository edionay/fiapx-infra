# LGPD — Nota de privacidade

Como o sistema autentica pessoas e processa arquivos enviados por elas, ele **trata dados
pessoais** e precisa considerar a LGPD (Lei 13.709/2018). Este documento registra quais dados são tratados, por quê, e como a arquitetura protege cada um.

## Dados pessoais tratados


| Dado                   | Origem                | Onde fica                        | Observação                                                         |
| ---------------------- | --------------------- | -------------------------------- | ------------------------------------------------------------------ |
| E-mail                 | Informado no registro | Postgres (`usuarios.email`)      | Identifica o titular e é o canal de notificação.                   |
| Senha                  | Informada no registro | Postgres (`usuarios.senha_hash`) | **Nunca armazenada em texto puro** — apenas o hash bcrypt.         |
| Vídeo enviado          | Upload do usuário     | Volume (`/data/uploads`)         | Pode conter imagem de pessoas — é o dado mais sensível do sistema. |
| Frames / pacote `.zip` | Gerado do vídeo       | Volume (`/data/outputs`)         | Herda a sensibilidade do vídeo de origem.                          |


O ponto de atenção real é o **conteúdo do vídeo**: um vídeo pode conter a imagem de pessoas, o que
é dado pessoal. Os frames extraídos herdam exatamente a mesma sensibilidade do vídeo original.

## Princípios aplicados



### Finalidade

Os dados são usados **somente** para autenticar o usuário e processar o vídeo que ele mesmo enviou, devolvendo o pacote de frames. Não há uso secundário: nada de perfilamento, analytics sobre o conteúdo, treino de modelo ou compartilhamento com terceiros.

### Necessidade

Coletamos o mínimo para a finalidade: **e-mail e senha**. Não pedimos nome, CPF, telefone, data de
nascimento nem qualquer outro dado. O e-mail existe porque é necessário para o login e para avisar
o usuário quando o processamento falha.

### Segurança

- Senha protegida com **bcrypt** (hash com salt); a senha original nunca é gravada nem logada.
- Acesso autenticado por **JWT**; upload, listagem e download exigem token válido.
- **Isolamento por titular**: a listagem filtra pelo usuário do token e o download só é permitido
se o vídeo pertencer a quem está pedindo. Um usuário nunca acessa o vídeo de outro.
- O serviço de processamento de vídeos processa o vídeo sem saber de quem ele é. Ele não tem acesso ao banco nem ao e-mail. A separação de contextos limita naturalmente a exposição do dado pessoal.
- Segredos (senha do banco, `JWT_SECRET`) vêm de variáveis de ambiente, fora do código.



### Transparência e direitos do titular

O usuário vê a lista dos próprios vídeos e o status de cada um a qualquer momento.

### Retenção e eliminação

- O **vídeo de entrada** é removido do volume assim que o processamento termina — ele não é mais
necessário depois que os frames foram extraídos. Guardar seria acumular dado pessoal sem
finalidade.
- O **pacote de frames** é retido por **7 dias**, prazo para o usuário fazer o download, e depois é
elegível à remoção.


## Decisões de arquitetura com impacto em privacidade


| Decisão                                | Efeito na proteção de dados                                                    |
| -------------------------------------- | ------------------------------------------------------------------------------ |
| Worker **stateless**, sem banco        | Reduz a superfície de exposição: quem processa a imagem não conhece o titular. |
| **Database-per-service**               | Só a api acessa dados pessoais; os demais serviços não têm como lê-los.        |
| Notificação disparada pela api         | O e-mail do usuário só trafega no momento e na medida necessária para o aviso. |
| Descarte do vídeo após o processamento | Aplica minimização também ao longo do tempo, não só na coleta.                 |




## Limitações

As lacunas atuais de privacidade e proteção de dados — criptografia em repouso, automação do
expurgo, exclusão pelo titular, consentimento e auditoria — estão consolidadas, com impacto e
encaminhamento, em [Limitações conhecidas](limitacoes-conhecidas.md).

