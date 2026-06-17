import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../shared/app_theme.dart';
import '../../models/resultado_ruta.dart';
import '../../config/app_config.dart';

class MapaRutaScreen extends StatefulWidget {
  final ResultadoRuta resultado;

  const MapaRutaScreen({super.key, required this.resultado});

  @override
  State<MapaRutaScreen> createState() => _MapaRutaScreenState();
}

class _MapaRutaScreenState extends State<MapaRutaScreen> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapa());
  }

  void _fitMapa() {
    final allPoints = _allLatLng();
    if (allPoints.isEmpty) return;
    if (allPoints.length == 1) {
      _mapController.move(allPoints.first, 15.0);
      return;
    }
    final bounds = LatLngBounds.fromPoints(allPoints);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  List<LatLng> _allLatLng() {
    final pts = <LatLng>[];
    for (final paso in widget.resultado.pasos) {
      if (paso.tipo == 'ruta') {
        for (final p in paso.puntos) {
          pts.add(LatLng(p.lat, p.lng));
        }
      }
    }
    return pts;
  }

  // Polilíneas: una por cada paso tipo 'ruta'
  List<Polyline> get _polylines {
    final result = <Polyline>[];
    for (final paso in widget.resultado.pasos) {
      if (paso.tipo != 'ruta' || paso.puntos.isEmpty) continue;
      final color = _hexColor(paso.color);
      result.add(Polyline(
        points: paso.puntos.map((p) => LatLng(p.lat, p.lng)).toList(),
        color: color,
        strokeWidth: 5.0,
        borderColor: Colors.white,
        borderStrokeWidth: 1.5,
      ));
    }
    return result;
  }

  // Marcadores: origen, destino, trasbordos
  List<Marker> get _markers {
    final result = <Marker>[];
    final pasoRuta =
        widget.resultado.pasos.where((p) => p.tipo == 'ruta').toList();

    // Origen (primer punto del primer paso)
    if (pasoRuta.isNotEmpty && pasoRuta.first.puntos.isNotEmpty) {
      final p = pasoRuta.first.puntos.first;
      result.add(Marker(
        point: LatLng(p.lat, p.lng),
        width: 44,
        height: 44,
        child: _PinMarker(
          color: Colors.green.shade700,
          icon: Icons.trip_origin,
          label: 'A',
        ),
      ));
    }

    // Destino (último punto del último paso)
    if (pasoRuta.isNotEmpty && pasoRuta.last.puntos.isNotEmpty) {
      final p = pasoRuta.last.puntos.last;
      result.add(Marker(
        point: LatLng(p.lat, p.lng),
        width: 44,
        height: 44,
        child: _PinMarker(
          color: Colors.blue.shade700,
          icon: Icons.location_on,
          label: 'B',
        ),
      ));
    }

    // Trasbordos: último punto del paso anterior = primero del siguiente
    for (int i = 0; i < widget.resultado.pasos.length; i++) {
      final paso = widget.resultado.pasos[i];
      if (paso.tipo != 'transbordo') continue;
      // El punto de trasbordo está al final del paso 'ruta' anterior
      if (i > 0) {
        final anterior = widget.resultado.pasos[i - 1];
        if (anterior.tipo == 'ruta' && anterior.puntos.isNotEmpty) {
          final p = anterior.puntos.last;
          result.add(Marker(
            point: LatLng(p.lat, p.lng),
            width: 48,
            height: 48,
            child: _TransbordoMarker(
              deLinea: paso.deLinea ?? '',
              aLinea: paso.aLinea ?? '',
            ),
          ));
        }
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.resultado.tiempoFormateado} · '
          '${widget.resultado.lineas.join(' → ')}',
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  const LatLng(AppConfig.mapLat, AppConfig.mapLng),
              initialZoom: AppConfig.mapZoom,
            ),
            children: [
              TileLayer(urlTemplate: AppTheme.mapTileUrl, userAgentPackageName: AppTheme.mapTileUserAgent),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Leyenda flotante
          Positioned(
            bottom: 16,
            left: 12,
            right: 12,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Líneas de ruta
                    ...widget.resultado.pasos
                        .where((p) => p.tipo == 'ruta')
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _hexColor(p.color),
                                      borderRadius:
                                          BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${p.linea ?? '?'}: '
                                    '${p.desdeDesc ?? ''} → ${p.hastaDesc ?? ''}',
                                    style:
                                        const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            )),

                    // Trasbordos
                    if (widget.resultado.trasbordos > 0) ...[
                      const Divider(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.transfer_within_a_station,
                              size: 14, color: AppTheme.secondary),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.resultado.trasbordos} trasbordo(s)',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 10),
                    // Leyenda de marcadores
                    Row(
                      children: [
                        _LeyendaDot(color: Colors.green.shade700, label: 'Origen'),
                        const SizedBox(width: 14),
                        _LeyendaDot(color: Colors.blue.shade700, label: 'Destino'),
                        if (widget.resultado.trasbordos > 0) ...[
                          const SizedBox(width: 14),
                          _LeyendaDot(
                              color: Colors.orange.shade700,
                              label: 'Trasbordo'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _fitMapa,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.fit_screen, color: Colors.white),
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _PinMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _PinMarker(
      {required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ),
        Container(
          width: 2,
          height: 8,
          color: color,
        ),
      ],
    );
  }
}

class _TransbordoMarker extends StatelessWidget {
  final String deLinea;
  final String aLinea;

  const _TransbordoMarker({required this.deLinea, required this.aLinea});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.transfer_within_a_station,
          color: Colors.white, size: 22),
    );
  }
}

class _LeyendaDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LeyendaDot({required this.color, required this.label});

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
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}
