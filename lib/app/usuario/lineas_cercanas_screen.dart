import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../shared/app_theme.dart';
import '../../models/linea.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../models/punto.dart';

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
  LatLng? _puntoBusqueda;
  bool _origenGPS = false;

  LatLng _mapCenter = const LatLng(AppConfig.mapLat, AppConfig.mapLng);
  bool _mapMoving = false;

  Linea? _lineaVisualizando;
  List<LatLng> _rutaPoints = [];
  bool _loadingRuta = false;

  final _api = ApiService();

  static const double _resultsHeight = 240.0;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _buscarConGPS() async {
    setState(() {
      _loading = true;
      _statusMsg = 'Obteniendo tu ubicación...';
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('El GPS está desactivado.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Permiso denegado.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _setError('Permiso denegado permanentemente.');
        return;
      }
      setState(() => _statusMsg = 'Buscando líneas...');
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      await _buscarEnCoordenadas(LatLng(pos.latitude, pos.longitude),
          origenGPS: true);
    } catch (_) {
      _setError('Error al obtener ubicación.');
    }
  }

  Future<void> _buscarEnCoordenadas(LatLng punto,
      {bool origenGPS = false}) async {
    setState(() {
      _loading = true;
      _statusMsg = 'Buscando líneas...';
      _lineaVisualizando = null;
      _rutaPoints = [];
    });
    try {
      final raw = await _api.getLineasCercanas(
          punto.latitude, punto.longitude, _radioMetros);
      final lineas =
          raw.map((j) => Linea.fromJson(j as Map<String, dynamic>)).toList();
      _mapController.move(punto, 15.5);
      if (!mounted) return;
      setState(() {
        _puntoBusqueda = punto;
        _origenGPS = origenGPS;
        _lineasCercanas = lineas;
        _loading = false;
        _buscado = true;
        _statusMsg = '';
      });
    } catch (e) {
      _setError('Error: $e');
    }
  }

  Future<void> _mostrarRutaEnMapa(Linea linea) async {
    final rutaId =
        linea.rutaIdForSentido('ida') ?? linea.rutaIdForSentido('vuelta');
    if (rutaId == null) return;
    setState(() {
      _loadingRuta = true;
      _lineaVisualizando = linea;
    });
    try {
      final raw = await _api.getPuntosRuta(rutaId);
      final puntos =
          raw.map((j) => Punto.fromJson(j as Map<String, dynamic>)).toList();
      final points =
          puntos.map((p) => LatLng(p.latitud, p.longitud)).toList();
      if (!mounted) return;
      setState(() {
        _rutaPoints = points;
        _loadingRuta = false;
      });
      if (points.isNotEmpty) {
        final allPoints = [...points];
        if (_puntoBusqueda != null) allPoints.add(_puntoBusqueda!);
        final bounds = LatLngBounds.fromPoints(allPoints);
        _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRuta = false;
        _lineaVisualizando = null;
      });
    }
  }

  void _cerrarRuta() =>
      setState(() {
        _lineaVisualizando = null;
        _rutaPoints = [];
      });

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _statusMsg = msg;
    });
  }

  Color _hexColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppTheme.primary;
    final cleaned = hex.replaceFirst('#', '');
    try {
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineaColor = _lineaVisualizando != null
        ? _hexColor(_lineaVisualizando!.colorHex)
        : AppTheme.primary;

    final showResults = _buscado &&
        _lineasCercanas.isNotEmpty &&
        !_loading &&
        _lineaVisualizando == null;
    final showPin = !_loading && _lineaVisualizando == null && !showResults;
    final showEmpty = _buscado &&
        _lineasCercanas.isEmpty &&
        !_loading &&
        _lineaVisualizando == null;

    // Posición del botón "Buscar líneas aquí" según lo que hay abajo
    final confirmBottom = showResults
        ? _resultsHeight + 12.0
        : showEmpty
            ? 130.0
            : 14.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_lineaVisualizando != null
            ? _lineaVisualizando!.nombre
            : 'Líneas Cercanas'),
        actions: [
          if (_lineaVisualizando != null)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Volver a la lista',
              onPressed: _cerrarRuta,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Panel de controles (oculto al ver recorrido) ───────────────
          if (_lineaVisualizando == null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radar,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      const Text('Radio:',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      const Spacer(),
                      Text('${_radioMetros.toInt()} m',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              fontSize: 13)),
                    ],
                  ),
                  SizedBox(
                    height: 32,
                    child: Slider(
                      value: _radioMetros,
                      min: 100,
                      max: 1000,
                      divisions: 9,
                      onChanged: (v) => setState(() => _radioMetros = v),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _buscarConGPS,
                          icon: const Icon(Icons.my_location, size: 15),
                          label: const Text('Mi GPS',
                              style: TextStyle(fontSize: 13)),
                          style: AppTheme.btnPrimary.copyWith(
                            padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(vertical: 8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _buscarEnCoordenadas(
                                  const LatLng(AppConfig.mapLat, AppConfig.mapLng)),
                          icon: const Icon(Icons.location_city, size: 15),
                          label: const Text('Centro SCZ',
                              style: TextStyle(fontSize: 12)),
                          style: AppTheme.btnOutline.copyWith(
                            padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(vertical: 8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ── Mapa expandido + todos los overlays ────────────────────────
          Expanded(
            child: Stack(
              children: [
                // Mapa base
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        const LatLng(AppConfig.mapLat, AppConfig.mapLng),
                    initialZoom: 13.5,
                    onPositionChanged: (camera, hasGesture) {
                      _mapCenter = camera.center ?? _mapCenter;
                      if (_mapMoving != hasGesture) {
                        setState(() => _mapMoving = hasGesture);
                      }
                    },
                    onTap: _lineaVisualizando != null
                        ? (_, __) => _cerrarRuta()
                        : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: AppTheme.mapTileUrl,
                      userAgentPackageName: AppTheme.mapTileUserAgent,
                    ),
                    if (_puntoBusqueda != null && _lineaVisualizando == null)
                      CircleLayer(circles: [
                        CircleMarker(
                          point: _puntoBusqueda!,
                          radius: _radioMetros,
                          useRadiusInMeter: true,
                          color: AppTheme.primary.withOpacity(0.08),
                          borderColor: AppTheme.primary.withOpacity(0.4),
                          borderStrokeWidth: 1.5,
                        ),
                      ]),
                    if (_rutaPoints.isNotEmpty)
                      PolylineLayer(polylines: [
                        Polyline(
                          points: _rutaPoints,
                          color: lineaColor,
                          strokeWidth: 4.5,
                          borderColor: Colors.white,
                          borderStrokeWidth: 1.5,
                        ),
                      ]),
                    // Marcador del punto donde se buscó
                    if (_puntoBusqueda != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _puntoBusqueda!,
                          width: 38,
                          height: 38,
                          alignment: Alignment.topCenter,
                          child: Icon(
                            _origenGPS
                                ? Icons.person_pin_circle
                                : Icons.location_on,
                            color: _origenGPS
                                ? Colors.green.shade700
                                : AppTheme.secondary,
                            size: 38,
                          ),
                        ),
                      ]),
                  ],
                ),

                // ── Pin arrastrable central ────────────────────────────────
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
                            color: AppTheme.primary,
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

                // ── Brújula ────────────────────────────────────────────────
                Positioned(
                  top: 10,
                  right: 10,
                  child: FloatingActionButton.small(
                    heroTag: 'north_lc',
                    onPressed: () => _mapController.rotate(0),
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                    elevation: 2,
                    child: const Icon(Icons.explore, size: 18),
                  ),
                ),

                // ── Loading ────────────────────────────────────────────────
                if (_loading || _loadingRuta)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),

                // ── Error banner ───────────────────────────────────────────
                if (_statusMsg.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 56,
                    right: 56,
                    child: Card(
                      color: AppTheme.danger,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(
                          _statusMsg,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),

                // ── Panel de resultados (overlay inferior) ─────────────────
                if (showResults)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: _resultsHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, -2))
                        ],
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 6, 16, 2),
                            child: Row(
                              children: [
                                Icon(Icons.directions_bus, size: 14, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  '${_lineasCercanas.length} línea(s) a ${_radioMetros.toInt()} m',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: _lineasCercanas.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 56),
                              itemBuilder: (context, i) {
                                final l = _lineasCercanas[i];
                                final lColor = _hexColor(l.colorHex);
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        lColor.withOpacity(0.15),
                                    radius: 18,
                                    child: Icon(Icons.directions_bus, size: 18, color: lColor),
                                  ),
                                  title: Text(l.nombre,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  subtitle: const Text(
                                      'Toca para ver en el mapa',
                                      style: TextStyle(fontSize: 10)),
                                  trailing: Icon(Icons.map_outlined,
                                      color: lColor, size: 18),
                                  onTap: () => _mostrarRutaEnMapa(l),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Sin resultados ─────────────────────────────────────────
                if (showEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, -2))
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 36, color: AppTheme.textSecondary),
                          SizedBox(height: 6),
                          Text('No hay líneas cerca',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary)),
                          SizedBox(height: 2),
                          Text('Aumenta el radio o mueve el mapa',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),

                // ── Info de ruta visualizada ───────────────────────────────
                if (_lineaVisualizando != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: lineaColor,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _lineaVisualizando!.nombre,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: lineaColor,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.touch_app_outlined,
                              size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          const Text('Toca mapa para cerrar',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),

                // ── Botón "Buscar líneas aquí" ─────────────────────────────
                if (showPin && !_loadingRuta)
                  Positioned(
                    bottom: confirmBottom,
                    left: 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      onPressed: () => _buscarEnCoordenadas(_mapCenter),
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Buscar líneas aquí',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppTheme.primary.withOpacity(0.4),
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
