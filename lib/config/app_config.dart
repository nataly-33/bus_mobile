import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Lee del .env en tiempo de ejecución
  static String get baseUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';

  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Centro del mapa: Santa Cruz de la Sierra
  static const double mapLat = -17.7833;
  static const double mapLng = -63.1824;
  static const double mapZoom = 13.0;

  static const double radioBusquedaMetros = 300.0;

  static const int intervaloPosicionSegundos = 30;

  static const int intervaloActualizacionSegundos = 15;
}
