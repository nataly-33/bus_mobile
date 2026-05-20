class Punto {
  final int id;
  final double latitud;
  final double longitud;
  final String? descripcion;
  final int orden;

  const Punto({
    required this.id,
    required this.latitud,
    required this.longitud,
    this.descripcion,
    required this.orden,
  });

  factory Punto.fromJson(Map<String, dynamic> json) => Punto(
        id: json['id'],
        latitud: double.parse(json['latitud'].toString()),
        longitud: double.parse(json['longitud'].toString()),
        descripcion: json['descripcion'],
        orden: json['orden'] ?? 0,
      );
}
