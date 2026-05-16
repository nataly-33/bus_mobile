import 'package:flutter/material.dart';

class Linea {
  final int id;
  final String nombre;
  final String colorHex;

  const Linea({required this.id, required this.nombre, required this.colorHex});

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  static List<Linea> get mockLineas => const [
        Linea(id: 12, nombre: 'Línea 12', colorHex: '#1565C0'),
        Linea(id: 20, nombre: 'Línea 20', colorHex: '#2E7D32'),
        Linea(id: 26, nombre: 'Línea 26', colorHex: '#C62828'),
        Linea(id: 4, nombre: 'Trufí 4', colorHex: '#E65100'),
        Linea(id: 33, nombre: 'Línea 33', colorHex: '#6A1B9A'),
      ];
}
