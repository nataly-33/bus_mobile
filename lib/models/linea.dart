import 'package:flutter/material.dart';

class Linea {
  final int id;
  final String codigo;
  final String nombre;
  final String colorHex;
  final int? rutaIdaId;
  final int? rutaVueltaId;

  const Linea({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.colorHex,
    this.rutaIdaId,
    this.rutaVueltaId,
  });

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  int? rutaIdForSentido(String sentido) =>
      sentido == 'ida' ? rutaIdaId : rutaVueltaId;

  factory Linea.fromJson(Map<String, dynamic> json) => Linea(
        id: json['id'],
        codigo: json['codigo'] ?? '',
        nombre: json['nombre'],
        colorHex: json['color'] ?? '#1565C0',
        rutaIdaId: json['ruta_ida_id'],
        rutaVueltaId: json['ruta_vuelta_id'],
      );
}
