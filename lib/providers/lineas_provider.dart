import 'package:flutter/material.dart';
import '../models/linea.dart';
import '../services/api_service.dart';

class LineasProvider extends ChangeNotifier {
  List<Linea> _lineas = [];
  bool _loading = false;
  String? _error;

  List<Linea> get lineas => _lineas;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> cargar({bool forzar = false}) async {
    if (_lineas.isNotEmpty && !forzar) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await ApiService().getLineas();
      _lineas = raw
          .map((j) => Linea.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _error = 'No se pudieron cargar las líneas. Verifica la conexión.';
    }
    _loading = false;
    notifyListeners();
  }
}
