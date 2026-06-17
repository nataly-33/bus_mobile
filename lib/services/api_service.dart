import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/resultado_ruta.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String base = AppConfig.baseUrl;

  // ── LÍNEAS ──────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getLineas() async {
    final res = await http.get(Uri.parse('$base/api/lineas/'));
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getPuntosRuta(int lineaRutaId) async {
    final res = await http.get(
        Uri.parse('$base/api/lineas-ruta/$lineaRutaId/puntos/'));
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getLineasCercanas(
      double lat, double lng, double radioMetros) async {
    final res = await http.get(Uri.parse(
        '$base/api/lineas/cercanas/?lat=$lat&lng=$lng&radio=$radioMetros'));
    return jsonDecode(res.body);
  }

  // ── PARADAS (para mapa de búsqueda de ruta) ──────────────────────────────

  Future<List<Map<String, dynamic>>> getParadas() async {
    final res = await http.get(Uri.parse('$base/api/paradas/'));
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
    final res = await http.post(
      Uri.parse('$base/api/buscar-ruta/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'origen_lat': origenLat,
        'origen_lng': origenLng,
        'destino_lat': destinoLat,
        'destino_lng': destinoLng,
      }),
    );
    if (res.statusCode != 200) return [];
    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((j) => ResultadoRuta.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── MICROBUSES ACTIVOS ────────────────────────────────────────────────────

  Future<List<dynamic>> getMicrobusesActivos(int lineaId) async {
    final res = await http
        .get(Uri.parse('$base/api/posiciones/activos/?linea=$lineaId'));
    return jsonDecode(res.body);
  }

  // ── CONDUCTOR ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loginConductor(
      String email, String password) async {
    final res = await http.post(
      Uri.parse('$base/api/conductores/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> registrarConductor(
      Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$base/api/conductores/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> registrarMicrobus(
      Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$base/api/microbuses/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  // ── GPS / RECORRIDO ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> iniciarRecorrido(
      Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$base/api/recorridos/iniciar/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
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
    await http.post(
      Uri.parse('$base/api/posiciones/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'recorrido': recorridoId,
        'latitud': lat,
        'longitud': lng,
        'velocidad': velocidad,
        'distancia': distancia,
        'tiempo_seg': tiempoSeg,
        'activo': true,
      }),
    );
  }

  Future<void> terminarRecorrido(int recorridoId, {String? motivo}) async {
    await http.patch(
      Uri.parse('$base/api/recorridos/$recorridoId/finalizar/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'motivo_salida': motivo}),
    );
  }
}
