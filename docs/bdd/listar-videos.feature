# language: pt

Funcionalidade: Consulta dos meus vídeos
  Como usuário do sistema
  Quero ver a situação dos vídeos que enviei
  Para saber quando o pacote de frames está pronto para download

  Cenário: Ver apenas os próprios vídeos
    Dado que estou autenticado como "maria@exemplo.com"
    E que enviei os vídeos "aula.mp4" e "palestra.mp4"
    E que "joao@exemplo.com" enviou o vídeo "reuniao.mp4"
    Quando consulto meus vídeos
    Então vejo "aula.mp4" e "palestra.mp4"
    E não vejo "reuniao.mp4"

  Cenário: Ver o status de cada vídeo
    Dado que estou autenticado como "maria@exemplo.com"
    E que enviei os vídeos abaixo
      | video           | status      |
      | aula.mp4        | CONCLUIDO   |
      | palestra.mp4    | PROCESSANDO |
      | entrevista.mp4  | PENDENTE    |
      | corrompido.mp4  | ERRO        |
    Quando consulto meus vídeos
    Então vejo cada vídeo com o seu status
    E apenas "aula.mp4" oferece o download do pacote de frames

  Cenário: Consultar sem ter enviado nenhum vídeo
    Dado que estou autenticado como "novo@exemplo.com"
    E que ainda não enviei nenhum vídeo
    Quando consulto meus vídeos
    Então vejo uma lista vazia

  Cenário: Baixar o pacote de frames de um vídeo concluído
    Dado que estou autenticado como "maria@exemplo.com"
    E que o vídeo "aula.mp4" está com status "CONCLUIDO"
    Quando baixo o pacote de frames de "aula.mp4"
    Então recebo o arquivo com os frames extraídos

  Cenário: Não baixar o pacote de um vídeo de outro usuário
    Dado que estou autenticado como "maria@exemplo.com"
    E que "joao@exemplo.com" enviou o vídeo "reuniao.mp4"
    E que o vídeo "reuniao.mp4" está com status "CONCLUIDO"
    Quando tento baixar o pacote de frames de "reuniao.mp4"
    Então o download é recusado
    E não é revelado que o vídeo existe

  Cenário: Não baixar o pacote de um vídeo que ainda não terminou
    Dado que estou autenticado como "maria@exemplo.com"
    E que o vídeo "palestra.mp4" está com status "PROCESSANDO"
    Quando tento baixar o pacote de frames de "palestra.mp4"
    Então o download é recusado

  Cenário: Consultar sem estar autenticado
    Dado que não estou autenticado
    Quando consulto meus vídeos
    Então a consulta é recusada por falta de autenticação
