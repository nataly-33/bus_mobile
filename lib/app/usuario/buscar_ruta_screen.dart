import 'dart:math' show sqrt, sin, cos, atan2, pi;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../shared/app_theme.dart';
import '../../services/api_service.dart';
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

  List<Map<String, dynamic>> _paradas = [];
  List<CircleMarker> _stopCircles = [];
  bool _loadingParadas = true;
  String? _errorParadas;

  // 'origen' | 'destino'
  String _modo = 'origen';

  Map<String, dynamic>? _paradaOrigen;
  Map<String, dynamic>? _paradaDestino;

  bool _buscando = false;

  LatLng _mapCenter = const LatLng(AppConfig.mapLat, AppConfig.mapLng);
  bool _mapMoving = false;

  bool get _ambosMarcados => _paradaOrigen != null && _paradaDestino != null;

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
    if (!mounted) return;
    setState(() {
      _loadingParadas = true;
      _errorParadas = null;
    });
    try {
      final data = await _api.getParadas();
      final circles = data
          .map((p) => CircleMarker(
                point: LatLng(
                  double.parse(p['latitud'].toString()),
                  double.parse(p['longitud'].toString()),
                ),
                radius: 5,
                color: Colors.red.withOpacity(0.85),
                borderColor: Colors.white,
                borderStrokeWidth: 1.5,
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        _paradas = data;
        _stopCircles = circles;
        _loadingParadas = false;
        _errorParadas = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingParadas = false;
        _errorParadas = e.toString();
      });
    }
  }

  double _distanciaMetros(
      double lat1, double lng1, double lat2, double lng2) {
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

  Map<String, dynamic>? _paradaMasCercana(LatLng center) {
    if (_paradas.isEmpty) return null;
    double minDist = double.infinity;
    Map<String, dynamic>? mejor;
    for (final p in _paradas) {
      final dist = _distanciaMetros(
        center.latitude,
        center.longitude,
        double.parse(p['latitud'].toString()),
        double.parse(p['longitud'].toString()),
      );
      if (dist < minDist) {
        minDist = dist;
        mejor = p;
      }
    }
    if (minDist > 2000) return null;
    return mejor;
  }

  void _confirmarDesdePin() {
    if (_loadingParadas) return;
    final parada = _paradaMasCercana(_mapCenter);
    if (parada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Desliza el mapa hasta un punto rojo (parada).'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ));
      return;
    }
    final wasOrigen = _modo == 'origen';
    final nombre =
        parada['descripcion'] as String? ?? 'Parada #${parada['id']}';
    setState(() {
      if (_modo == 'origen') {
        _paradaOrigen = parada;
        if (_paradaDestino == null) _modo = 'destino';
      } else {
        _paradaDestino = parada;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${wasOrigen ? 'Origen' : 'Destino'}: $nombre'),
      backgroundColor:
          wasOrigen ? Colors.green.shade700 : AppTheme.primary,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
    ));
  }

  void _clearOrigen() => setState(() {
        _paradaOrigen = null;
        _modo = 'origen';
      });

  void _clearDestino() => setState(() {
        _paradaDestino = null;
        _modo = 'destino';
      });

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se encontró ruta entre esas paradas.'),
          backgroundColor: AppTheme.danger,
        ));
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ResultadosRutaScreen(resultados: resultados)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al buscar ruta. Verifica la conexión.'),
        backgroundColor: AppTheme.danger,
      ));
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  List<Marker> get _selectionMarkers {
    final markers = <Marker>[];
    if (_paradaOrigen != null) {
      markers.add(Marker(
        point: LatLng(
          double.parse(_paradaOrigen!['latitud'].toString()),
          double.parse(_paradaOrigen!['longitud'].toString()),
        ),
        width: 38,
        height: 38,
        alignment: Alignment.topCenter,
        child: Icon(Icons.location_on, color: Colors.green.shade700, size: 38),
      ));
    }
    if (_paradaDestino != null) {
      markers.add(Marker(
        point: LatLng(
          double.parse(_paradaDestino!['latitud'].toString()),
          double.parse(_paradaDestino!['longitud'].toString()),
        ),
        width: 38,
        height: 38,
        alignment: Alignment.topCenter,
        child: Icon(Icons.location_on, color: AppTheme.primary, size: 38),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final modoColor =
        _modo == 'origen' ? Colors.green.shade700 : AppTheme.primary;
    final showPin =
        !_loadingParadas && _errorParadas == null && !_ambosMarcados;

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Ruta Óptima')),
      body: Column(
        children: [
          // ── Panel superior: chips con X ────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: _PointChip(
                    label: _paradaOrigen?['descripcion'] as String? ??
                        'Desliza el mapa',
                    icon: Icons.trip_origin,
                    color: Colors.green,
                    isSet: _paradaOrigen != null,
                    isActive: _modo == 'origen' && !_ambosMarcados,
                    onClear: _paradaOrigen != null ? _clearOrigen : null,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward,
                      color: AppTheme.textSecondary, size: 14),
                ),
                Expanded(
                  child: _PointChip(
                    label: _paradaDestino?['descripcion'] as String? ??
                        'Desliza el mapa',
                    icon: Icons.location_on,
                    color: AppTheme.primary,
                    isSet: _paradaDestino != null,
                    isActive: _modo == 'destino' && !_ambosMarcados,
                    onClear: _paradaDestino != null ? _clearDestino : null,
                  ),
                ),
              ],
            ),
          ),

          // ── Mapa expandido ─────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                if (_loadingParadas)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Cargando paradas...',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                else if (_errorParadas != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off,
                              size: 48, color: AppTheme.danger),
                          const SizedBox(height: 12),
                          const Text('No se pudo conectar al servidor',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_errorParadas!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _cargarParadas,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          const LatLng(AppConfig.mapLat, AppConfig.mapLng),
                      initialZoom: AppConfig.mapZoom,
                      onPositionChanged: (camera, hasGesture) {
                        _mapCenter = camera.center ?? _mapCenter;
                        if (_mapMoving != hasGesture) {
                          setState(() => _mapMoving = hasGesture);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: AppTheme.mapTileUrl,
                        userAgentPackageName: AppTheme.mapTileUserAgent,
                      ),
                      CircleLayer(circles: _stopCircles),
                      MarkerLayer(markers: _selectionMarkers),
                    ],
                  ),

                // ── Pin arrastrable (solo cuando no ambos confirmados) ────
                if (showPin)
                  Center(
                    child: IgnorePointer(
                      child: Transform.translate(
                        offset: const Offset(0, -19),
                        child: AnimatedScale(
                          scale: _mapMoving ? 1.25 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.location_on,
                            size: 38,
                            color: modoColor,
                            shadows: const [
                              Shadow(
                                  color: Colors.black38,
                                  blurRadius: 8,
                                  offset: Offset(0, 3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Brújula ───────────────────────────────────────────────
                if (!_loadingParadas && _errorParadas == null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'north_buscar',
                      onPressed: () => _mapController.rotate(0),
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      elevation: 2,
                      child: const Icon(Icons.explore, size: 20),
                    ),
                  ),

                // ── Leyenda ───────────────────────────────────────────────
                if (!_loadingParadas && _errorParadas == null)
                  Positioned(
                    top: 56,
                    right: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
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
                                color: AppTheme.primary, label: 'Destino'),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Botón único: Confirmar -o- Buscar Ruta Óptima ─────────
                if (!_loadingParadas && _errorParadas == null)
                  Positioned(
                    bottom: 14,
                    left: 16,
                    right: 16,
                    child: _ambosMarcados
                        ? ElevatedButton.icon(
                            onPressed: _buscando ? null : _buscarRuta,
                            icon: _buscando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.search, size: 20),
                            label: Text(
                              _buscando ? 'Buscando...' : 'Buscar Ruta Óptima',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppTheme.primary.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _confirmarDesdePin,
                            icon: Icon(
                              _modo == 'origen'
                                  ? Icons.trip_origin
                                  : Icons.location_on,
                              size: 18,
                            ),
                            label: Text(
                              _modo == 'origen'
                                  ? 'Confirmar origen'
                                  : 'Confirmar destino',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: modoColor,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: modoColor.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────────

class _PointChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSet;
  final bool isActive;
  final VoidCallback? onClear;

  const _PointChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSet,
    required this.isActive,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.08) : AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isActive ? color : Colors.grey.shade300, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSet ? color : Colors.grey, size: 14),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSet
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 11,
                fontStyle:
                    isSet ? FontStyle.normal : FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle),
                child:
                    const Icon(Icons.close, size: 10, color: Colors.white),
              ),
            ),
          ],
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
