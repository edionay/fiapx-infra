# language: pt

Funcionalidade: Processamento do vídeo
  Como usuário do sistema
  Quero acompanhar o resultado do processamento do meu vídeo
  Para baixar os frames quando ficarem prontos, ou saber que algo deu errado

  Cenário: Concluir o processamento com sucesso
    Dado que enviei o vídeo "aula.mp4" e ele está com status "PENDENTE"
    Quando o processamento de "aula.mp4" começa
    Então o vídeo "aula.mp4" fica com status "PROCESSANDO"
    Quando o processamento de "aula.mp4" termina com sucesso
    Então o vídeo "aula.mp4" fica com status "CONCLUIDO"
    E o pacote de frames de "aula.mp4" fica disponível para download
    E nenhum aviso de falha é enviado

  Cenário: Avisar o usuário quando o processamento falha
    Dado que estou autenticado como "maria@exemplo.com"
    E que enviei o vídeo "corrompido.mp4"
    Quando o processamento de "corrompido.mp4" falha
    Então o vídeo "corrompido.mp4" fica com status "ERRO"
    E um e-mail de aviso é enviado para "maria@exemplo.com"
    E o pacote de frames de "corrompido.mp4" não fica disponível para download

  Cenário: Descartar o vídeo original após o processamento
    Dado que enviei o vídeo "aula.mp4"
    Quando o processamento de "aula.mp4" termina com sucesso
    Então o vídeo original "aula.mp4" é removido do armazenamento
    E o pacote de frames de "aula.mp4" é mantido

  Cenário: Não perder pedidos em um pico de envios
    Dado que 20 vídeos foram enviados ao mesmo tempo
    Quando o processamento de todos eles termina
    Então os 20 vídeos ficam com status "CONCLUIDO"
    E nenhum pedido de processamento é perdido

  Cenário: Retomar o processamento após a queda de um processador
    Dado que enviei o vídeo "aula.mp4" e ele está com status "PENDENTE"
    E que o processador cai antes de concluir "aula.mp4"
    Quando um processador volta a ficar disponível
    Então o processamento de "aula.mp4" acontece
    E o vídeo "aula.mp4" fica com status "CONCLUIDO"
