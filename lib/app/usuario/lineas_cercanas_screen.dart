import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../shared/app_theme.dart';
import '../../models/linea.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import 'recorrido_linea_screen.dart';

class LineasCercanasScreen extends StatefulWidget {
  const LineasCercanasScreen({super.key});

  @override
  State<LineasCercanasScreen> createState() => _LineasCercanasScreenState();
}

class _LineasCercanasScreenState extends State<LineasCercanasScreen> {
  List<Linea> _lineasCercanas = [];
  bool _loading = false;
  bool _buscado = false;
  String _statusMsg = '';
  double _radioMetros = 300;

  final _mapController = MapController();
  LatLng? _puntoBusqueda; // null = ninguno seleccionado aún
  List<Marker> _markers = [];
  List<CircleMarker> _circles = [];

  final _api = ApiService();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ── Búsqueda por GPS ────────────────────────────────────────────────────────

  Future<void> _buscarConGPS() async {
    setState(() {
      _loading = true;
      _statusMsg = 'Obteniendo tu ubicación...';
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('El GPS está desactivado. Actívalo e intenta de nuevo.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Permiso de ubicación denegado.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _setError('Permiso de ubicación denegado permanentemente.');
        return;
      }
      setState(() => _statusMsg = 'Buscando líneas cercanas...');
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      await _buscarEnCoordenadas(
          LatLng(pos.latitude, pos.longitude), origenGPS: true);
    } catch (_) {
      _setError('Error al obtener ubicación. Intenta de nuevo.');
    }
  }

  // ── Tap en el mapa ──────────────────────────────────────────────────────────

  void _onMapTap(TapPosition _, LatLng punto) {
    if (_loading) return;
    setState(() {
      _puntoBusqueda = punto;
      _loading = true;
      _statusMsg = 'Buscando en punto seleccionado...';
    });
    _buscarEnCoordenadas(punto);
  }

  // ── Búsqueda genérica ───────────────────────────────────────────────────────

  Future<void> _buscarEnCoordenadas(LatLng punto, {bool origenGPS = false}) async {
    try {
      final raw =
          await _api.getLineasCercanas(punto.latitude, punto.longitude, _radioMetros);
      final lineas = raw
          .map((j) => Linea.fromJson(j as Map<String, dynamic>))
          .toList();

      _mapController.move(punto, 15.5);

      setState(() {
        _puntoBusqueda = punto;
        _lineasCercanas = lineas;
        _loading = false;
        _buscado = true;
        _statusMsg = '';
        _markers = [
          Marker(
            point: punto,
            width: 40,
            height: 40,
            child: origenGPS
                ? const Icon(Icons.person_pin_circle,
                    color: Color(0xFF2E7D32), size: 36)
                : Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.search,
                        color: Colors.white, size: 20),
                  ),
          ),
        ];
        _circles = [
          CircleMarker(
            point: punto,
            radius: _radioMetros,
            useRadiusInMeter: true,
            color: (origenGPS
                    ? const Color(0xFF2E7D32)
                    : AppTheme.primary)
                .withOpacity(0.1),
            borderColor: (origenGPS
                    ? const Color(0xFF2E7D32)
                    : AppTheme.primary)
                .withOpacity(0.5),
            borderStrokeWidth: 2,
          ),
        ];
      });
    } catch (_) {
      _setError('Error al buscar líneas. Verifica la conexión.');
    }
  }

  void _setError(String msg) {
    setState(() {
      _loading = false;
      _statusMsg = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Líneas Cercanas'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Column(
        children: [
          // ── Panel superior ──────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar,
                        size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    const Text('Radio de búsqueda:',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    const Spacer(),
                    Text(
                      '${_radioMetros.toInt()} m',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          fontSize: 13),
                    ),
                  ],
                ),
                Slider(
                  value: _radioMetros,
                  min: 100,
                  max: 1000,
                  divisions: 9,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (v) => setState(() => _radioMetros = v),
                ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _buscarConGPS,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Mi GPS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading
                            ? null
                            : () => _buscarEnCoordenadas(
                                const LatLng(AppConfig.mapLat, AppConfig.mapLng)),
                        icon: const Icon(Icons.location_city, size: 18),
                        label: const Text('Centro'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          side: const BorderSide(color: Color(0xFF2E7D32)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Indicador de modo tap
                Row(
                  children: [
                    const Icon(Icons.touch_app,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _puntoBusqueda == null
                          ? 'Toca el mapa para seleccionar cualquier punto'
                          : 'Punto seleccionado — toca otro para cambiar',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Mapa (altura dinámica mayor para permitir exploración) ──────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _buscado && _lineasCercanas.isNotEmpty ? 240 : 300,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(AppConfig.mapLat, AppConfig.mapLng),
                initialZoom: 13.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(urlTemplate: AppTheme.mapTileUrl, userAgentPackageName: AppTheme.mapTileUserAgent),
                CircleLayer(circles: _circles),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),

          // ── Estados / resultados ────────────────────────────────────────────
          if (_loading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text(_statusMsg,
                      style:
                          const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          else if (_statusMsg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: AppTheme.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_statusMsg,
                        style:
                            const TextStyle(color: AppTheme.danger)),
                  ),
                ],
              ),
            )
          else if (_buscado)
            Expanded(
              child: _lineasCercanas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 48,
                              color: AppTheme.textSecondary),
                          const SizedBox(height: 8),
                          const Text('No hay líneas en este punto',
                              style: TextStyle(
                                  color: AppTheme.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            'Intenta aumentar el radio o tocar otro punto del mapa',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppTheme.textSecondary
                                    .withOpacity(0.7),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 10, 16, 6),
                          child: Text(
                            '${_lineasCercanas.length} línea(s) a '
                            '${_radioMetros.toInt()} m del punto',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF2E7D32)),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _lineasCercanas.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final l = _lineasCercanas[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      l.color.withOpacity(0.15),
                                  child: Icon(Icons.directions_bus,
                                      color: l.color, size: 22),
                                ),
                                title: Text(l.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: const Text(
                                    'Toca para ver el recorrido'),
                                trailing:
                                    const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const RecorridoLineaScreen()),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.touch_app_outlined,
                        size: 52, color: AppTheme.textSecondary),
                    const SizedBox(height: 10),
                    const Text(
                      'Toca el mapa para elegir un punto',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'o usa "Mi GPS" para tu ubicación actual',
                      style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.7),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
