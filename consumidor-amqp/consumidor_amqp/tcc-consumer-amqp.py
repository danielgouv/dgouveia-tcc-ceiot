import pika
import logging, re, datetime, os
from pymongo import MongoClient
#pool mongo, conexao default em localhost. Para outros hosts setar
client = MongoClient()
db =  client.smartfarm
def quebrar_msg(msg: str):
    id_boi, resto=msg.split(";")
    atributos = [r.replace(',','.') for r in resto.split('|')]
    atributos_tipados = [float(a) if ('.' in a) else int(a)  for a in atributos]
    labels = ['temperatura', 'movimento', 'coordenadas', 'alerta']
    retorno = {'temperatura': atributos_tipados[0], 'movimento': atributos_tipados[1], 'coordenadas':[atributos_tipados[2], atributos_tipados[3]], 'alerta': atributos_tipados[4]}
    return id_boi, retorno
def callback(ch, method, properties, body):
    msg = body.decode('ascii')
    id_boi, atributos = quebrar_msg(msg)
    atributos['dt_atualizacao'] = datetime.datetime.now()
    atributos['ativo'] = True
    db.boi.update_one({'_id':id_boi}, {'$set':atributos},upsert=True)
    print(" => %r" % body)
connection = pika.BlockingConnection(pika.ConnectionParameters(host=os.environ['RABBITMQ_HOST'], virtual_host='/'))
channel = connection.channel()
channel.basic_consume(queue='data_smartfarm',
                      auto_ack=True,
                      on_message_callback=callback)
channel.start_consuming()
while True:
    pass

