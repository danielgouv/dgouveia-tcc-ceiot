import paho.mqtt.client as mqtt
import pika
import logging, re, os

connection = pika.BlockingConnection(pika.ConnectionParameters(host=os.environ['RABBITMQ_HOST'], virtual_host='/'))
channel = connection.channel()
channel.queue_declare(queue='data_smartfarm',durable=True)

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)-12s %(levelname)-8s %(message)s',
                    datefmt='%d-%m-%Y %H:%M:%S')

def on_connect(client, userdata, flags, rc):
    client.subscribe("smart-farm/+/dados") 
    logging.debug("Conectado mqtt")
def on_message(client, userdata, msg):
    id_no = re.match(r'smart-farm/([A-F0-9]{16})/dados',msg.topic).group(1)
    payload = id_no+ ";" +msg.payload.decode('ascii')
    logging.info("Publicando para "+id_no)
    channel.basic_publish(exchange='smartfarm',
                      routing_key='smartfarm-data_smartfarm',
                      body=payload)
def on_disconnect(client, userdata, rc):
    pass

def on_open(connection):
    """Callback when we have connected to the AMQP broker."""
    connection.channel(on_channel_open)


def on_channel_open(channel):
    """Callback when we have opened a channel on the connection."""
    channel.exchange_declare(exchange='smartfarm', exchange_type='direct',
                             durable=True,
                             callback=partial(on_exchange, channel))


def on_exchange(channel, frame):
    """Callback when we have successfully declared the exchange."""
    logging.info('Have exchange')
    send_message(channel, 0)


def send_message(channel, i):
    """Send a message to the queue.

    This function also registers itself as a timeout function, so the
    main :mod:`pika` loop will call this function again every 5 seconds.

    """
    channel.basic_publish('smartfarm', 'smartfarm-data_smartfarm', msg,
                          pika.BasicProperties(content_type='text/plain',
                                               delivery_mode=2))
    channel.connection.add_timeout(DELAY,
                                   partial(send_message, channel, i+1))

cliente = mqtt.Client("mqtt-leitor")
cliente.on_connect = on_connect  # Define callback function for successful connection
cliente.on_message = on_message  # Define callback function for receipt of a message
cliente.on_disconnect = on_disconnect
cliente.connect(os.environ['MQTT_HOST'], 1883, 60)

cliente.loop_forever()


