import 'dart:math' show sqrt, sin, cos, atan2, pi;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../shared/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/resultado_ruta.dart';
import '../../config/app_config.dart';
import 'resultados_ruta_screen.dart';

class BuscarRutaScreen extends StatefulWidget {
  const BuscarRutaScreen({super.key});

  @override
  State<BuscarRutaScreen> createState() => _BuscarRutaScreenState();
}

class _BuscarRutaScreenState extends State<BuscarRutaScreen> {
  final _api = ApiService();
  final _mapController = MapController();

  // Todas las paradas Stop='S' — se almacena la lista completa solo para snap
  List<Map<String, dynamic>> _paradas = [];
  // Círculos precalculados una sola vez (mucho más rápido que MarkerLayer)
  List<CircleMarker> _stopCircles = [];
  bool _loadingParadas = true;

  // Modo actual: 'origen' | 'destino'
  String _modo = 'origen';

  // Paradas seleccionadas
  Map<String, dynamic>? _paradaOrigen;
  Map<String, dynamic>? _paradaDestino;

  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _cargarParadas();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _cargarParadas() async {
    try {
      final data = await _api.getParadas();
      // Pre-construir círculos una sola vez en un isolate-friendly loop
      final circles = data.map((p) => CircleMarker(
            point: LatLng(
              double.parse(p['latitud'].toString()),
              double.parse(p['longitud'].toString()),
            ),
            radius: 5,
            color: Colors.red.withOpacity(0.85),
            borderColor: Colors.white,
            borderStrokeWidth: 1.5,
          )).toList();
      setState(() {
        _paradas = data;
        _stopCircles = circles;
        _loadingParadas = false;
      });
    } catch (_) {
      setState(() => _loadingParadas = false);
    }
  }

  // Haversine en metros (calculado en el cliente para snap offline)
  double _distanciaMetros(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Map<String, dynamic>? _paradaMasCercana(LatLng tap) {
    if (_paradas.isEmpty) return null;
    double minDist = double.infinity;
    Map<String, dynamic>? mejor;
    for (final p in _paradas) {
      final dist = _distanciaMetros(
        tap.latitude,
        tap.longitude,
        double.parse(p['latitud'].toString()),
        double.parse(p['longitud'].toString()),
      );
      if (dist < minDist) {
        minDist = dist;
        mejor = p;
      }
    }
    if (minDist > 2000) return null; // más de 2 km → sin parada cercana
    return mejor;
  }

  void _onMapTap(TapPosition _, LatLng punto) {
    if (_loadingParadas) return;
    final parada = _paradaMasCercana(punto);
    if (parada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay paradas en un radio de 2 km. '
              'Toca más cerca de un punto rojo.'),
          backgroundColor: AppTheme.danger,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final nombre = parada['descripcion'] ?? 'Parada #${parada['id']}';
    setState(() {
      if (_modo == 'origen') {
        _paradaOrigen = parada;
        _modo = 'destino'; // auto-cambio al destino tras elegir origen
      } else {
        _paradaDestino = parada;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${_modo == 'destino' && _paradaDestino == parada ? 'Destino' : 'Origen'}: $nombre'),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _buscarRuta() async {
    if (_paradaOrigen == null || _paradaDestino == null) return;
    setState(() => _buscando = true);
    try {
      final resultados = await _api.buscarRuta(
        origenLat: double.parse(_paradaOrigen!['latitud'].toString()),
        origenLng: double.parse(_paradaOrigen!['longitud'].toString()),
        destinoLat: double.parse(_paradaDestino!['latitud'].toString()),
        destinoLng: double.parse(_paradaDestino!['longitud'].toString()),
      );
      if (!mounted) return;
      if (resultados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No se encontró ruta entre esas paradas.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultadosRutaScreen(resultados: resultados),
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al buscar ruta. Verifica la conexión.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  // Solo origen y destino — los stops usan CircleLayer (mucho más rápido)
  List<Marker> get _selectionMarkers {
    final markers = <Marker>[];
    if (_paradaOrigen != null) {
      markers.add(Marker(
        point: LatLng(
          double.parse(_paradaOrigen!['latitud'].toString()),
          double.parse(_paradaOrigen!['longitud'].toString()),
        ),
        width: 48,
        height: 48,
        child: const Icon(Icons.trip_origin, color: Colors.green, size: 36),
      ));
    }
    if (_paradaDestino != null) {
      markers.add(Marker(
        point: LatLng(
          double.parse(_paradaDestino!['latitud'].toString()),
          double.parse(_paradaDestino!['longitud'].toString()),
        ),
        width: 48,
        height: 48,
        child: const Icon(Icons.location_on, color: Colors.blue, size: 36),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final puedeHacerBusqueda =
        _paradaOrigen != null && _paradaDestino != null && !_buscando;

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Ruta Óptima')),
      body: Column(
        children: [
          // Panel de modo y selección
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Toggle modo
                Row(
                  children: [
                    Expanded(
                      child: _ModoToggle(
                        label: 'Seleccionar Origen',
                        icon: Icons.trip_origin,
                        active: _modo == 'origen',
                        color: Colors.green,
                        onTap: () => setState(() => _modo = 'origen'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ModoToggle(
                        label: 'Seleccionar Destino',
                        icon: Icons.location_on,
                        active: _modo == 'destino',
                        color: Colors.blue,
                        onTap: () => setState(() => _modo = 'destino'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Info paradas seleccionadas
                Row(
                  children: [
                    Expanded(
                      child: _ParadaInfo(
                        label: 'Origen',
                        descripcion: _paradaOrigen?['descripcion'] as String?,
                        color: Colors.green,
                        icon: Icons.trip_origin,
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: AppTheme.textSecondary),
                    Expanded(
                      child: _ParadaInfo(
                        label: 'Destino',
                        descripcion:
                            _paradaDestino?['descripcion'] as String?,
                        color: Colors.blue,
                        icon: Icons.location_on,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mapa
          Expanded(
            child: Stack(
              children: [
                _loadingParadas
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Cargando paradas...',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              const LatLng(AppConfig.mapLat, AppConfig.mapLng),
                          initialZoom: AppConfig.mapZoom,
                          onTap: _onMapTap,
                        ),
                        children: [
                          TileLayer(urlTemplate: AppTheme.mapTileUrl, userAgentPackageName: AppTheme.mapTileUserAgent),
                          // CircleLayer es canvas-drawn: 106 círculos sin overhead de Widget tree
                          CircleLayer(circles: _stopCircles),
                          // Solo 0-2 marcadores para origen/destino
                          MarkerLayer(markers: _selectionMarkers),
                        ],
                      ),

                // Leyenda
                Positioned(
                  top: 12,
                  right: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LeyendaItem(
                              color: Colors.red, label: 'Parada'),
                          const SizedBox(height: 4),
                          _LeyendaItem(
                              color: Colors.green, label: 'Origen'),
                          const SizedBox(height: 4),
                          _LeyendaItem(
                              color: Colors.blue, label: 'Destino'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botón buscar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: puedeHacerBusqueda ? _buscarRuta : null,
                icon: _buscando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search),
                label: Text(
                    _buscando ? 'Buscando...' : 'Buscar Ruta Óptima'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModoToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ModoToggle({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? color : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? color : AppTheme.textSecondary,
                  fontWeight:
                      active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParadaInfo extends StatelessWidget {
  final String label;
  final String? descripcion;
  final Color color;
  final IconData icon;

  const _ParadaInfo({
    required this.label,
    required this.descripcion,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            descripcion ?? 'Toca el mapa',
            style: TextStyle(
              fontSize: 11,
              color: descripcion != null
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
              fontStyle: descripcion != null
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LeyendaItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
