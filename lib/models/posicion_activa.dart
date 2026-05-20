class PosicionActiva {
  final int recorridoId;
  final String placa;
  final double latitud;
  final double longitud;
  final double velocidad;
  final String? timestamp;

  const PosicionActiva({
    required this.recorridoId,
    required this.placa,
    required this.latitud,
    required this.longitud,
    required this.velocidad,
    this.timestamp,
  });

  factory PosicionActiva.fromJson(Map<String, dynamic> json) => PosicionActiva(
        recorridoId: json['recorrido_id'],
        placa: json['placa'] ?? '',
        latitud: (json['latitud'] as num).toDouble(),
        longitud: (json['longitud'] as num).toDouble(),
        velocidad: (json['velocidad'] as num?)?.toDouble() ?? 0,
        timestamp: json['timestamp']?.toString(),
      );
}
