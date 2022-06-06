import 'dart:async';
import 'dart:convert';

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(const SmartFarmApp());

class SmartFarmApp extends StatelessWidget {
  const SmartFarmApp({Key? key}) : super(key: key);

  static const String _title = 'Smartfarm';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: TelaInicial(),
    );
  }
}

class TelaInicial extends StatelessWidget {
  const TelaInicial({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[900],
          title: const Text('Smartfarm - Gerenciador'),
        ),
        body: BotoesInicio());
  }
}

class ListaAnimaisWidget extends StatelessWidget {
  const ListaAnimaisWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[900],
        title: const Text('Listagem de animais'),
      ),
      body: const Center(
        child: Text(
          'This is the next page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class BoiLista extends StatefulWidget {
  const BoiLista({Key? key}) : super(key: key);

  @override
  State<BoiLista> createState() => _BoiListaState();
}

class _BoiListaState extends State<BoiLista> {
  late Future<List<Boi>> bois;
  late List<Boi> boiada;

  Future<void> _buscarAnimais() async {
    final response =
    await http.get(Uri.parse('http://192.168.100.108:5000/boi/'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);

      setState(() {
        boiada = jsonResponse.map((data) => Boi.fromJson(data)).toList();
      });
    } else {
      throw Exception("Failed to load");
    }
  }

  @override
  Widget build(BuildContext context) {
    bois = buscarAnimais();
    bois.then((value) =>
    {
      value.forEach((element) {
        print(element.id);
      })
    });

    return FutureBuilder(
      future: bois,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          boiada = (snapshot.data as List<Boi>?)!;

          return RefreshIndicator(
            // trigger the _loadData function when the user pulls down
              onRefresh: _buscarAnimais,
              child: ListView.builder(
                itemCount: boiada.length,
                itemBuilder: (BuildContext context, int index) {
                  return BoiCard(boi: boiada[index]);
                },
              ));
          //return const Text("Chegou os dados...");
        } else if (snapshot.hasError) {
          return const Text("Erro...");
        } else {
          return const Text("Loading data...");
        }
      },
    );
  }
}

class BoiCard extends StatelessWidget {
  const BoiCard({Key? key, required this.boi}) : super(key: key);
  final Boi boi;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Card(
        child: ListTile(
          leading: Image.asset('images/vaca.png'),
          title: Text("ID: " + this.boi.id),
          subtitle: Text(this.boi.subtitulo()),
          onTap: () {
            Navigator.push(context, MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return Scaffold(
                  appBar: AppBar(
                    actions: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                        onPressed: () {

                        },
                      )
                    ],
                    backgroundColor: Colors.green[900],
                    title: Text("Detalhe do animal"),
                  ),
                  body: new BoiDetalhe(boi: this.boi),
                );
              },
            ));
          },
        ),
      ),
    );
  }
}

class BoiDetalhe extends StatelessWidget {
  const BoiDetalhe({Key? key, required this.boi}) : super(key: key);
  final Boi boi;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(children: <Widget>[
        Card(
          borderOnForeground: false,
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(boi.id,
                style: TextStyle(fontWeight: FontWeight.bold),
                textScaleFactor: 2),
          ),
        ),
        Card(
          borderOnForeground: false,
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.device_thermostat),
            title: Text("Temperatura: " + boi.temperatura.toString()),
          ),
        ),
        Card(
          borderOnForeground: false,
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.light_mode),
            title: Text(
                "Alerta ligado? " + (this.boi.alerta == 1 ? "Sim" : "Nao")),
          ),
        ),
        Card(
            borderOnForeground: false,
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.gps_fixed),
              title: Text("Coordenadas: " + this.boi.coordenadas.toString()),
            )),
        Card(
            borderOnForeground: false,
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.timer),
              title: Text("Ultima atualizacao: " + this.boi.ultimaAtualizacao),
            )),
        ListTile(
            title: Text("Acoes",
                style: TextStyle(fontWeight: FontWeight.bold),
                textScaleFactor: 1.5)),
        Card(
          child: ListTile(
            leading: Icon(Icons.lightbulb),
            title: Text((this.boi.alerta == 1 ? "Retirar alerta" : "Alertar")),
            onTap: () {
              Future<bool> resposta;
              String msgAlerta = "";
              if (this.boi.alerta == 1) {
                msgAlerta =
                    "Alerta retirado com sucesso. O boi " + this.boi.id +
                        " parou de piscar agora.";
                resposta = retirarAlerta(this.boi);
              } else {
                msgAlerta = "Alerta enviado com sucesso. O boi " + this.boi.id +
                    " deve estar piscando agora.";
                resposta = alertar(this.boi);
              }

              resposta.then((value) =>
              {
                if (value)
                  {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(msgAlerta)))
                  }
              });
            },
          ),
        ),
      ]),
    );
  }
}

Future<List<Boi>> buscarAnimais() async {
  final response =
  await http.get(Uri.parse('http://api.daniel.tec.br:5000/boi/'));
  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((data) => Boi.fromJson(data)).toList();
  } else {
    throw Exception("Failed to load");
  }
}

Future<Uint8List?> getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec =
  await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))?.buffer
      .asUint8List();
}

Future<bool> retirarAlerta(Boi boi) async {
  final response = await http.delete(
      Uri.parse('http://api.daniel.tec.br:5000/boi/' + boi.id + '/alertar'));
  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}

Future<bool> alertar(Boi boi) async {
  final response = await http
      .put(Uri.parse('http://api.daniel.tec.br:5000/boi/' + boi.id + '/alertar'));
  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}

class Coordenadas {
  Coordenadas(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  String toString() {
    return "[" + latitude.toString() + ", " + longitude.toString() + "]";
  }
}

class Boi {
  Boi(this.id, this.alerta, this.ativo, this.coordenadas,
      this.ultimaAtualizacao, this.movimento, this.temperatura);

  final String id;
  final int alerta;
  final bool ativo;
  final Coordenadas coordenadas;
  final String ultimaAtualizacao;
  final int movimento;
  final double temperatura;

  factory Boi.fromJson(Map<String, dynamic> json) {
    return Boi(
        json['_id'],
        json['alerta'],
        true,
        Coordenadas(json['coordenadas'][0], json['coordenadas'][1]),
        json['dt_atualizacao'],
        json['movimento'],
        json['temperatura']);
  }

  String subtitulo() {
    String retorno = "";
    if (alerta == 1) {
      retorno += "Alerta ligado.";
    } else {
      retorno += "Alerta desligado.";
    }
    retorno += " Temperatura: " + temperatura.toString();

    retorno += "\nEm movimento? " + ((movimento == 1) ? "Sim" : "Não");
    retorno += "\nCoordenadas: " + coordenadas.toString();

    return retorno;
  }

  String getNome() {
    return this.id;
  }
}

class BotoesInicio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Card(
        child: ListTile(
          leading: Icon(Icons.map),
          title: Text("Mapa da fazenda"),
          onTap: () {
            Navigator.push(context, MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return MapaFazenda();
              },
            ));
          },
        ),
      ),
      Card(
        child: ListTile(
          leading: Icon(Icons.list),
          title: Text("Lista dos animais"),
          onTap: () {
            Navigator.push(context, MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.green[900],
                    title: const Text('Animais'),
                  ),
                  body: new BoiLista(),
                );
              },
            ));
          },
        ),
      ),
    ]);
  }
}


class MapaFazenda extends StatefulWidget {
  @override
  _MapaFazendaState createState() => _MapaFazendaState();
}

class _MapaFazendaState extends State<MapaFazenda> {
  Completer<GoogleMapController> _controller = Completer();

  static const LatLng _center = const LatLng(-15.1705192, -52.7735904);

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  late Set<Marker> markers;

  @override
  Widget build(BuildContext context) {
    Future<Set<Marker>> _buscarPosicoes() async {
      final response =
      await http.get(Uri.parse('http://api.daniel.tec.br:5000/boi/'));
      Set<Marker> mark = {};
      final Uint8List? markerIcon = await getBytesFromAsset(
          'images/cow.png', 100);
      final Uint8List? markerIconAlerta = await getBytesFromAsset('images/vaca-alerta.png', 100);
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        List<Boi> boiada = jsonResponse.map((data) => Boi.fromJson(data))
            .toList();
        for (Boi b in boiada) {
          mark.add(Marker(markerId: MarkerId(b.id),
              infoWindow: InfoWindow(
                title: 'ID: ' + b.id,
                snippet: 'Atualizacao: ' + b.ultimaAtualizacao,
              ),
              //icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              icon: (b.alerta==1)?BitmapDescriptor.fromBytes(markerIconAlerta!):BitmapDescriptor.fromBytes(markerIcon!),
              position: LatLng(
                  b.coordenadas.latitude, b.coordenadas.longitude)));
        }
        return mark;
      } else {
        throw Exception("Failed to load");
      }
    }

    var timer = Timer(Duration(seconds: 3), () => setState(() {
      _buscarPosicoes().then((value) => this.markers = value);
    }));
    Future<Set<Marker>> futureMarkers = _buscarPosicoes();
    return FutureBuilder(
      future: futureMarkers,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Set<Marker>? marcadores = snapshot.data as Set<Marker>?;
          markers = marcadores!.cast();
          return Scaffold(
            appBar: AppBar(
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () {
                    setState(() {
                      _buscarPosicoes().then((value) => this.markers = value);
                      print("Refresh");
                    });
                  },
                )
              ],
              title: Text('Minha fazenda'),
              backgroundColor: Colors.green[900],
            ),
            body: GoogleMap(
              onMapCreated: _onMapCreated,
              mapType: MapType.satellite,
              markers: markers,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 12.0,
              ),
            ),
          );


        } else if (snapshot.hasError) {
          return const Text("Erro...");
        } else {
          return const Text("Loading data...");
        }
      },
    );
  }
}
