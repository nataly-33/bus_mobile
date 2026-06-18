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
        width: 34,
        height: 44,
        alignment: Alignment.topCenter,
        child: _PinMarker(color: Colors.green.shade700, label: 'A'),
      ));
    }

    // Destino (último punto del último paso)
    if (pasoRuta.isNotEmpty && pasoRuta.last.puntos.isNotEmpty) {
      final p = pasoRuta.last.puntos.last;
      result.add(Marker(
        point: LatLng(p.lat, p.lng),
        width: 34,
        height: 44,
        alignment: Alignment.topCenter,
        child: _PinMarker(color: AppTheme.secondary, label: 'B'),
      ));
    }

    // Trasbordos
    for (int i = 0; i < widget.resultado.pasos.length; i++) {
      final paso = widget.resultado.pasos[i];
      if (paso.tipo != 'transbordo') continue;
      if (i > 0) {
        final anterior = widget.resultado.pasos[i - 1];
        if (anterior.tipo == 'ruta' && anterior.puntos.isNotEmpty) {
          final p = anterior.puntos.last;
          result.add(Marker(
            point: LatLng(p.lat, p.lng),
            width: 30,
            height: 30,
            child: _TransbordoMarker(),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'north',
            onPressed: () => _mapController.rotate(0),
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primary,
            child: const Icon(Icons.explore, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'fit',
            onPressed: _fitMapa,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.fit_screen, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _PinMarker extends StatelessWidget {
  final Color color;
  final String label;

  const _PinMarker({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.45), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        Container(width: 2, height: 6, color: color),
      ],
    );
  }
}

class _TransbordoMarker extends StatelessWidget {
  const _TransbordoMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(color: AppTheme.secondary.withOpacity(0.4), blurRadius: 4),
        ],
      ),
      child: const Icon(Icons.swap_horiz, color: Colors.white, size: 16),
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
