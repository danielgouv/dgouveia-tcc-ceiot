import uvicorn

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, validator
import logging
import time
import os
import asyncio
from pymongo import MongoClient
import paho.mqtt.client as mqtt
from fastapi.middleware.cors import CORSMiddleware

client = MongoClient()
db =  client.smartfarm

app = FastAPI()
origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(
    format='%(asctime)s %(levelname)-8s %(message)s',
    level=logging.getLevelName('DEBUG'),
    datefmt='%Y-%m-%d %H:%M:%S')

@app.get('/boi/')
async def listar_bois():
    lista_boi = db.boi.find({'ativo': True})
    bois = list()
    for l in lista_boi:
        bois.append(l)
    return bois

@app.get('/boi/{id_boi}')
async def get_boi(id_boi: str):
    boi = db.boi.find_one({'_id': id_boi})
    return boi

@app.delete('/boi/{id_boi}/alertar')
async def retirar_alerta(id_boi:str):
    msg_enviada = await tratar_alerta(id_boi, 0)
    if msg_enviada == 0:
        raise HTTPException(status_code=500, detail="Nao foi possivel enviar o alerta")
    return {'sucesso':1}

@app.put('/boi/{id_boi}/alertar')
async def alertar_boi(id_boi:str):
    msg_enviada = await tratar_alerta(id_boi, 1)
    if msg_enviada == 0:
        raise HTTPException(status_code=500, detail="Nao foi possivel enviar o alerta")
    return {'sucesso':1}
    
async def tratar_alerta(id_boi:str, payload: int):
    cliente = mqtt.Client("mqtt-alerta-"+id_boi+str(payload))
    msg_enviada = 0
    def on_connect(cln, userdata, flags, rc):
        cln.publish("smart-farm/"+id_boi+"/alerta", str(payload))
        nonlocal msg_enviada
        msg_enviada = 1
        cln.disconnect()
    def on_message(cln, userdata, msg):
        pass
    def on_disconnect(cln, userdata, rc):
        pass
    cliente.on_connect = on_connect  # Define callback function for successful connection
    cliente.on_message = on_message  # Define callback function for successful connection
    cliente.on_disconnect = on_disconnect  # Define callback function for successful connection
    cliente.connect(os.environ['MQTT_HOST'], 1883, 5)
    cliente.loop_start()
    timeout = 0
    while msg_enviada == 0 and timeout <5:
        time.sleep(1)
        timeout = timeout + 1
    return msg_enviada


@app.get('/boi/{id_boi}/ping')
async def pingar_boi(id_boi:str):
    cliente = mqtt.Client("mqtt-ping-"+id_boi)
    pong_ok = 0
    def on_connect(cln, userdata, flags, rc):
        cln.publish("smart-farm/"+id_boi+"/ping", "1")
        cln.subscribe("smart-farm/"+id_boi+"/pong") 
    def on_message(cln, userdata, msg):
        nonlocal pong_ok
        pong_ok = 1
        pass
    def on_disconnect(cln, userdata, rc):
        pass
    cliente.on_connect = on_connect  # Define callback function for successful connection
    cliente.on_message = on_message  # Define callback function for successful connection
    cliente.on_disconnect = on_disconnect  # Define callback function for successful connection
    cliente.connect('mq.daniel.tec.br', 1883, 5)
    cliente.loop_start()
    timeout = 0
    while pong_ok == 0 and timeout <5:
        time.sleep(1)
        timeout = timeout + 1
    if pong_ok == 1:
        return {'sucesso':1}
    else:
        raise HTTPException(status_code=404, detail="Nao respondeu ao ping")