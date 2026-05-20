import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../shared/app_theme.dart';
import '../shared/widgets/linea_chip.dart';
import '../../models/linea.dart';
import '../../models/punto.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';

class RecorridoLineaScreen extends StatefulWidget {
  const RecorridoLineaScreen({super.key});

  @override
  State<RecorridoLineaScreen> createState() => _RecorridoLineaScreenState();
}

class _RecorridoLineaScreenState extends State<RecorridoLineaScreen> {
  List<Linea> _lineas = [];
  Linea? _lineaSeleccionada;
  String _sentido = 'ida';
  bool _loadingLineas = true;
  bool _loadingPuntos = false;

  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadLineas();
  }

  Future<void> _loadLineas() async {
    try {
      final raw = await _api.getLineas();
      final lineas =
          raw.map((j) => Linea.fromJson(j as Map<String, dynamic>)).toList();
      setState(() {
        _lineas = lineas;
        _lineaSeleccionada = lineas.isNotEmpty ? lineas.first : null;
        _loadingLineas = false;
      });
      if (_lineaSeleccionada != null) _loadPuntos();
    } catch (_) {
      setState(() => _loadingLineas = false);
    }
  }

  Future<void> _loadPuntos() async {
    if (_lineaSeleccionada == null) return;
    final rutaId = _lineaSeleccionada!.rutaIdForSentido(_sentido);
    if (rutaId == null) {
      setState(() {
        _polylines = {};
        _markers = {};
      });
      return;
    }

    setState(() => _loadingPuntos = true);
    try {
      final raw = await _api.getPuntosRuta(rutaId);
      final puntos =
          raw.map((j) => Punto.fromJson(j as Map<String, dynamic>)).toList();

      final color = _lineaSeleccionada!.color;
      final polyline = Polyline(
        polylineId: const PolylineId('ruta'),
        points: puntos.map((p) => LatLng(p.latitud, p.longitud)).toList(),
        color: color,
        width: 4,
      );

      final markers = <Marker>{};
      if (puntos.isNotEmpty) {
        markers.add(Marker(
          markerId: const MarkerId('inicio'),
          position: LatLng(puntos.first.latitud, puntos.first.longitud),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Inicio'),
        ));
        markers.add(Marker(
          markerId: const MarkerId('fin'),
          position: LatLng(puntos.last.latitud, puntos.last.longitud),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Fin'),
        ));

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            _boundsFromPuntos(puntos),
            50,
          ),
        );
      }

      setState(() {
        _polylines = {polyline};
        _markers = markers;
        _loadingPuntos = false;
      });
    } catch (_) {
      setState(() => _loadingPuntos = false);
    }
  }

  LatLngBounds _boundsFromPuntos(List<Punto> puntos) {
    double minLat = puntos.first.latitud;
    double maxLat = puntos.first.latitud;
    double minLng = puntos.first.longitud;
    double maxLng = puntos.first.longitud;
    for (final p in puntos) {
      if (p.latitud < minLat) minLat = p.latitud;
      if (p.latitud > maxLat) maxLat = p.latitud;
      if (p.longitud < minLng) minLng = p.longitud;
      if (p.longitud > maxLng) maxLng = p.longitud;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recorrido de Línea')),
      body: Column(
        children: [
          // Panel de selección
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona una línea:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      fontSize: 12),
                ),
                const SizedBox(height: 10),
                if (_loadingLineas)
                  const Center(child: CircularProgressIndicator())
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _lineas
                          .map((l) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: LineaChip(
                                  linea: l,
                                  selected: _lineaSeleccionada?.id == l.id,
                                  onTap: () {
                                    setState(() => _lineaSeleccionada = l);
                                    _loadPuntos();
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Sentido: ',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    _SentidoToggle(
                      sentido: _sentido,
                      onChanged: (s) {
                        setState(() => _sentido = s);
                        _loadPuntos();
                      },
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
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target:
                        LatLng(AppConfig.mapLat, AppConfig.mapLng),
                    zoom: AppConfig.mapZoom,
                  ),
                  polylines: _polylines,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) =>
                      _mapController = controller,
                ),
                if (_loadingPuntos)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                // Info card de la línea
                if (_lineaSeleccionada != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 56,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _lineaSeleccionada!.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_lineaSeleccionada!.nombre} — ${_sentido == 'ida' ? 'Ida' : 'Vuelta'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                            _LeyendaDot(
                                color: Colors.green.shade700,
                                label: 'Inicio'),
                            const SizedBox(width: 10),
                            _LeyendaDot(
                                color: Colors.red.shade700, label: 'Fin'),
                          ],
                        ),
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

class _SentidoToggle extends StatelessWidget {
  final String sentido;
  final ValueChanged<String> onChanged;

  const _SentidoToggle(
      {required this.sentido, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            label: 'Ida',
            selected: sentido == 'ida',
            onTap: () => onChanged('ida'),
          ),
          _ToggleOption(
            label: 'Vuelta',
            selected: sentido == 'vuelta',
            onTap: () => onChanged('vuelta'),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? Colors.white : AppTheme.textSecondary,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
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
