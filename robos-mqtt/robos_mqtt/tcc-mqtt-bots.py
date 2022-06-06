from threading import Thread
import time, random, string, locale, sys
import paho.mqtt.client as mqtt
import logging
import os

logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)-12s %(levelname)-8s %(message)s',
                    datefmt='%d-%m-%Y %H:%M:%S')

locale.setlocale(locale.LC_ALL, 'pt_BR.UTF_8')

class Boi:
    # coordenadas definidas de modo aleatorio
    LATITUDE_MAXIMA = -15.12980
    LATITUDE_MINIMA = -15.22980

    LONGITUDE_MAXIMA = -52.72355
    LONGITUDE_MINIMA = -52.82355

    def __init__(self):
        #Construtor conecta e fica em loop
        self._id = ''.join(random.choices('ABCDEF' + string.digits, k=16))
        logging.debug("Iniciando: "+self._id)
        self._latitude = (random.randrange(1512980, 1522980)) / -100000
        self._longitude = (random.randrange(5272355, 5282355)) / -100000
        self._temperatura = 35.1
        self._alerta = 0
        self._client = mqtt.Client(self._id)  # Create instance of client with client ID
        self._client.on_connect = self.on_connect  # Define callback function for successful connection
        self._client.on_message = self.on_message  # Define callback function for receipt of a message
        self._client.on_disconnect = self.on_disconnect
        self._client.connect(os.environ['MQTT_HOST'], 1883, 60)
        self._client.loop_start()
        

    def _topic_alerta(self):
        return "smart-farm/"+self._id+"/alerta"

    def _topic_ping(self):
        return "smart-farm/"+self._id+"/ping"

    def _topic_dados(self):
        return "smart-farm/"+self._id+"/dados"

    def _topic_pong(self):
        return "smart-farm/"+self._id+"/pong"
        
    def on_connect(self,client, userdata, flags, rc):
        self._client.subscribe(self._topic_alerta()) 
        self._client.subscribe(self._topic_ping()) 
    def on_message(self,client, userdata, msg): 
        if msg.topic == self._topic_alerta():
            if msg.payload.decode('ascii') == "1":
                self.ligar_alerta()
            elif msg.payload.decode('ascii') == "0":
                self.desligar_alerta()
        elif msg.topic == self._topic_ping():
            self._client.publish(self._topic_pong(), "1")
    def on_disconnect(self, client, userdata, rc):
        pass
    def nome(self):
        return str(self._id) + str(" / ") + str(self._latitude) + str(" / ") + str(self._longitude) + str(" / ") + str(self._temperatura)
    def aumenta_latitude(self):
        if self._latitude >= Boi.LATITUDE_MINIMA:
            self._latitude += 0.0001
            self._movimento = 1
    def diminui_latitude(self):
        if self._latitude <= Boi.LATITUDE_MAXIMA:
            self._latitude -= 0.0001
            self._movimento = 1
    def aumenta_longitude(self):
        if self._longitude >= Boi.LONGITUDE_MINIMA:
            self._longitude += 0.0001
            self._movimento = 1
    def diminui_longitude(self):
        if self._longitude <= Boi.LONGITUDE_MAXIMA:
            self._longitude -= 0.0001
            self._movimento = 1
    def sem_movimento(self):
        self._movimento = 0
    def aumenta_temperatura(self):
        self._temperatura += 0.1
    def diminui_temperatura(self):
        self._temperatura -= 0.1
    def ligar_alerta(self):
        self._alerta = 1
    def desligar_alerta(self):
        self._alerta = 0
    def get_info(self):
        return locale.format_string('%.1f',self._temperatura)+"|"+str(self._movimento)+"|"+locale.format_string('%.5f',self._latitude)+"|"+locale.format_string('%.5f',self._longitude)+"|"+str(self._alerta)
    def atualizar_info(self):
        logging.debug(self.get_info())
        self._client.publish(self._topic_dados(), self.get_info())


class RoboBoi(Thread):

        def __init__ (self):
            Thread.__init__(self)
            self.__boi = Boi()

        def run(self):
            #Em thread ele fica loop alternando posicionamento e temperatura
            while True:
                random.seed(time.time() * 10000000)
                rand = int(random.random() * 100)
                if (rand % 5 == 0):
                    if rand % 2 ==0: self.__boi.aumenta_latitude()
                    else: self.__boi.diminui_latitude()
                elif (rand % 5 == 1):
                    if rand % 2 ==0: self.__boi.aumenta_longitude()
                    else: self.__boi.diminui_longitude()
                else:
                    self.__boi.sem_movimento()

                if (rand%7==0):
                    if rand % 2 ==0: self.__boi.aumenta_temperatura()
                    else: self.__boi.diminui_temperatura()

                self.__boi.atualizar_info()
                time.sleep(5)


if __name__ == "__main__":
    qtd_robos = 0
    try:
        qtd_robos = int(sys.argv[1])
        if qtd_robos == 0:
            logging.warning("Digite a quantidade de robos como parametro > 0")
            exit()
    except:
        logging.warning("Digite a quantidade de robos como parametro")
        exit()
    
    for i in range(0,qtd_robos):
        a = RoboBoi()
        a.start()
    logging.info("Iniciados "+str(qtd_robos)+" robos-boi")
