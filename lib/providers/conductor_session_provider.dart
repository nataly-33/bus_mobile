import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConductorSessionProvider extends ChangeNotifier {
  int? conductorId;
  String nombre = '';
  String placa = '';
  int microbusId = 0;
  int lineaId = 0;

  bool get isLoggedIn => conductorId != null;

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    conductorId = prefs.getInt('conductor_id');
    nombre = prefs.getString('conductor_nombre') ?? '';
    placa = prefs.getString('microbus_placa') ?? '';
    microbusId = prefs.getInt('microbus_id') ?? 0;
    lineaId = prefs.getInt('microbus_linea_id') ?? 0;
    notifyListeners();
  }

  Future<void> guardarConductor({
    required int id,
    required String nombreCompleto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    conductorId = id;
    nombre = nombreCompleto;
    await prefs.setInt('conductor_id', id);
    await prefs.setString('conductor_nombre', nombreCompleto);
    notifyListeners();
  }

  Future<void> guardarMicrobus({
    required int id,
    required String placaVal,
    required int lineaIdVal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    microbusId = id;
    placa = placaVal;
    lineaId = lineaIdVal;
    await prefs.setInt('microbus_id', id);
    await prefs.setString('microbus_placa', placaVal);
    await prefs.setInt('microbus_linea_id', lineaIdVal);
    notifyListeners();
  }

  Future<void> limpiar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    conductorId = null;
    nombre = '';
    placa = '';
    microbusId = 0;
    lineaId = 0;
    notifyListeners();
  }
}
