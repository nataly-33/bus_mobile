class Microbus {
  final String placa;
  final String modelo;
  final String color;
  final int anio;
  final int numAsientos;
  final int conductorId;
  final int lineaId;
  final String? fotoUrl;

  const Microbus({
    required this.placa,
    required this.modelo,
    required this.color,
    required this.anio,
    required this.numAsientos,
    required this.conductorId,
    required this.lineaId,
    this.fotoUrl,
  });

  Map<String, dynamic> toMap() => {
        'placa': placa,
        'modelo': modelo,
        'color': color,
        'anio': anio,
        'num_asientos': numAsientos,
        'conductor_id': conductorId,
        'linea_id': lineaId,
        'foto_url': fotoUrl ?? '',
      };
}
