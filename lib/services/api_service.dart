import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/resultado_ruta.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String base = AppConfig.baseUrl;

  static const _timeout = Duration(seconds: 10);

  Future<http.Response> _get(String url) async {
    debugPrint('[API] GET $url');
    try {
      final res = await http.get(Uri.parse(url)).timeout(_timeout);
      debugPrint('[API] ${res.statusCode} $url');
      if (res.statusCode != 200) {
        debugPrint('[API] ERROR body: ${res.body}');
      }
      return res;
    } catch (e, st) {
      debugPrint('[API] EXCEPTION en GET $url\n$e\n$st');
      rethrow;
    }
  }

  Future<http.Response> _post(String url, Map<String, dynamic> body) async {
    debugPrint('[API] POST $url body=$body');
    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      debugPrint('[API] ${res.statusCode} $url');
      if (res.statusCode != 200) {
        debugPrint('[API] ERROR body: ${res.body}');
      }
      return res;
    } catch (e, st) {
      debugPrint('[API] EXCEPTION en POST $url\n$e\n$st');
      rethrow;
    }
  }

  // ── LÍNEAS ──────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getLineas() async {
    final res = await _get('$base/api/lineas/');
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getPuntosRuta(int lineaRutaId) async {
    final res = await _get('$base/api/lineas-ruta/$lineaRutaId/puntos/');
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getLineasCercanas(
      double lat, double lng, double radioMetros) async {
    final res = await _get(
        '$base/api/lineas/cercanas/?lat=$lat&lng=$lng&radio=$radioMetros');
    return jsonDecode(res.body);
  }

  // ── PARADAS (para mapa de búsqueda de ruta) ──────────────────────────────

  Future<List<Map<String, dynamic>>> getParadas() async {
    final res = await _get('$base/api/paradas/');
    final List<dynamic> data = jsonDecode(res.body);
    return data.cast<Map<String, dynamic>>();
  }

  // ── BUSCAR RUTA (Dijkstra) ────────────────────────────────────────────────

  Future<List<ResultadoRuta>> buscarRuta({
    required double origenLat,
    required double origenLng,
    required double destinoLat,
    required double destinoLng,
  }) async {
    final res = await _post('$base/api/buscar-ruta/', {
      'origen_lat': origenLat,
      'origen_lng': origenLng,
      'destino_lat': destinoLat,
      'destino_lng': destinoLng,
    });
    if (res.statusCode != 200) return [];
    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((j) => ResultadoRuta.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── MICROBUSES ACTIVOS ────────────────────────────────────────────────────

  Future<List<dynamic>> getMicrobusesActivos(int lineaId) async {
    final res =
        await _get('$base/api/posiciones/activos/?linea=$lineaId');
    return jsonDecode(res.body);
  }

  // ── CONDUCTOR ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loginConductor(
      String email, String password) async {
    final res = await _post('$base/api/conductores/login/',
        {'email': email, 'password': password});
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> registrarConductor(
      Map<String, dynamic> data) async {
    final res = await _post('$base/api/conductores/', data);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> registrarMicrobus(
      Map<String, dynamic> data) async {
    final res = await _post('$base/api/microbuses/', data);
    return jsonDecode(res.body);
  }

  // ── GPS / RECORRIDO ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> iniciarRecorrido(
      Map<String, dynamic> data) async {
    final res = await _post('$base/api/recorridos/iniciar/', data);
    return jsonDecode(res.body);
  }

  Future<void> enviarPosicion({
    required int recorridoId,
    required double lat,
    required double lng,
    required double velocidad,
    required double distancia,
    required int tiempoSeg,
  }) async {
    await _post('$base/api/posiciones/', {
      'recorrido': recorridoId,
      'latitud': double.parse(lat.toStringAsFixed(6)),
      'longitud': double.parse(lng.toStringAsFixed(6)),
      'velocidad': velocidad,
      'distancia': distancia,
      'tiempo_seg': tiempoSeg,
      'activo': true,
    });
  }

  Future<void> terminarRecorrido(int recorridoId, {String? motivo}) async {
    await http
        .patch(
          Uri.parse('$base/api/recorridos/$recorridoId/finalizar/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'motivo_salida': motivo}),
        )
        .timeout(_timeout);
  }
}
