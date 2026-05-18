import '../models/linea.dart';
import '../models/posicion_gps.dart';

// Cambia a false cuando tengas tu API Key de ArcGIS configurada
const bool _useMock = true;

// ignore: unused_element
const String _arcgisBaseUrl =
    'https://services.arcgis.com/TU_ORG_ID/arcgis/rest/services';
// ignore: unused_element
const String _apiKey = 'TU_API_KEY_AQUI';

class ArcGISService {
  // --- RUTAS ---

  Future<List<Linea>> getLineas() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return Linea.mockLineas;
    }
    // TODO: GET $_arcgisBaseUrl/RutasLineas/FeatureServer/0/query?where=1=1&outFields=*&f=json&token=$_apiKey
    return [];
  }

  Future<List<Linea>> getLineasCercanas(double lat, double lng,
      {double radioMetros = 300}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      // Devuelve 2-3 líneas aleatorias simulando proximidad
      return Linea.mockLineas.take(3).toList();
    }
    // TODO: GET con geometryType=esriGeometryPoint&spatialRel=esriSpatialRelIntersects
    return [];
  }

  // --- POSICIONES GPS ---

  Future<List<PosicionGPS>> getMicrobusesActivos(int lineaId) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return PosicionGPS.mockPosiciones(lineaId);
    }
    // TODO: GET $_arcgisBaseUrl/PosicionesGPS/FeatureServer/0/query?where=linea_id=$lineaId AND activo=1&f=geojson&token=$_apiKey
    return [];
  }

  Future<bool> enviarPosicion({
    required int conductorId,
    required String placa,
    required int lineaId,
    required String sentido,
    required double lat,
    required double lng,
    required double velocidad,
    required double distancia,
    required int tiempoSeg,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    }
    // TODO: POST $_arcgisBaseUrl/PosicionesGPS/FeatureServer/0/applyEdits
    return false;
  }

  Future<bool> terminarRecorrido(int conductorId) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    }
    // TODO: POST applyEdits con activo=0 para el feature del conductor
    return false;
  }

  // --- CONDUCTORES ---

  Future<int?> registrarConductor(Map<String, dynamic> datos) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return 1; // ID mock
    }
    // TODO: POST a la tabla Conductores en ArcGIS Online
    return null;
  }

  Future<bool> registrarMicrobus(Map<String, dynamic> datos) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    }
    // TODO: POST a la tabla Microbuses en ArcGIS Online
    return false;
  }
}
