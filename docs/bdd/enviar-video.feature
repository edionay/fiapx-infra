# language: pt

Funcionalidade: Envio de vídeo para processamento
  Como usuário do sistema
  Quero enviar um vídeo e ser liberado imediatamente
  Para não precisar esperar o processamento terminar

  Cenário: Enviar um vídeo em formato suportado
    Dado que estou autenticado como "maria@exemplo.com"
    Quando envio o vídeo "aula.mp4"
    Então o envio é aceito imediatamente
    E o vídeo "aula.mp4" fica com status "PENDENTE"
    E um pedido de processamento é enfileirado para "aula.mp4"

  Cenário: Recusar arquivo em formato não suportado
    Dado que estou autenticado como "maria@exemplo.com"
    Quando envio o arquivo "contrato.pdf"
    Então o envio é recusado
    E nenhum pedido de processamento é enfileirado

  Cenário: Recusar envio de quem não está autenticado
    Dado que não estou autenticado
    Quando envio o vídeo "aula.mp4"
    Então o envio é recusado por falta de autenticação
    E nenhum pedido de processamento é enfileirado

  Cenário: Enviar vários vídeos em sequência
    Dado que estou autenticado como "maria@exemplo.com"
    Quando envio os vídeos "aula.mp4", "palestra.mp4" e "entrevista.mp4"
    Então os três envios são aceitos
    E os três vídeos ficam com status "PENDENTE"
    E três pedidos de processamento são enfileirados
