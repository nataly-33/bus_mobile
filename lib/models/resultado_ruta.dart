class PuntoGPS {
  final double lat;
  final double lng;
  const PuntoGPS(this.lat, this.lng);
}

class PasoRuta {
  final String tipo; // 'ruta' | 'transbordo'

  // tipo == 'ruta'
  final String? linea;
  final String? color;
  final String? desdeDesc;
  final String? hastaDesc;
  final double? tiempoMin;
  final List<PuntoGPS> puntos; // GPS waypoints para dibujar polilínea

  // tipo == 'transbordo'
  final String? enDesc;
  final String? deLinea;
  final String? aLinea;
  final double? penalizacionMin;

  const PasoRuta({
    required this.tipo,
    this.linea,
    this.color,
    this.desdeDesc,
    this.hastaDesc,
    this.tiempoMin,
    this.puntos = const [],
    this.enDesc,
    this.deLinea,
    this.aLinea,
    this.penalizacionMin,
  });

  factory PasoRuta.fromJson(Map<String, dynamic> j) => PasoRuta(
        tipo: j['tipo'] as String,
        linea: j['linea'] as String?,
        color: j['color'] as String?,
        desdeDesc: j['desde_desc'] as String?,
        hastaDesc: j['hasta_desc'] as String?,
        tiempoMin: (j['tiempo_min'] as num?)?.toDouble(),
        puntos: j['puntos'] != null
            ? (j['puntos'] as List)
                .map((p) => PuntoGPS(
                      (p['lat'] as num).toDouble(),
                      (p['lng'] as num).toDouble(),
                    ))
                .toList()
            : const [],
        enDesc: j['en_desc'] as String?,
        deLinea: j['de_linea'] as String?,
        aLinea: j['a_linea'] as String?,
        penalizacionMin: (j['penalizacion_min'] as num?)?.toDouble(),
      );
}

class ResultadoRuta {
  final double tiempoTotalMin;
  final int trasbordos;
  final List<String> lineas;
  final String origenDesc;
  final String destinoDesc;
  final List<PasoRuta> pasos;

  const ResultadoRuta({
    required this.tiempoTotalMin,
    required this.trasbordos,
    required this.lineas,
    required this.origenDesc,
    required this.destinoDesc,
    required this.pasos,
  });

  factory ResultadoRuta.fromJson(Map<String, dynamic> j) => ResultadoRuta(
        tiempoTotalMin: (j['tiempo_total_min'] as num).toDouble(),
        trasbordos: j['trasbordos'] as int,
        lineas: List<String>.from(j['lineas'] as List),
        origenDesc: j['origen_desc'] as String,
        destinoDesc: j['destino_desc'] as String,
        pasos: (j['pasos'] as List)
            .map((p) => PasoRuta.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  String get tiempoFormateado {
    final mins = tiempoTotalMin.round();
    if (mins < 60) return '${mins} min';
    return '${mins ~/ 60}h ${mins % 60}min';
  }
}
