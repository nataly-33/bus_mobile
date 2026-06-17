import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../shared/app_theme.dart';
import '../shared/widgets/linea_chip.dart';
import '../../models/linea.dart';
import '../../models/posicion_activa.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';

class EsperandoMicrobusScreen extends StatefulWidget {
  const EsperandoMicrobusScreen({super.key});

  @override
  State<EsperandoMicrobusScreen> createState() =>
      _EsperandoMicrobusScreenState();
}

class _EsperandoMicrobusScreenState extends State<EsperandoMicrobusScreen> {
  List<Linea> _lineas = [];
  Linea? _lineaSeleccionada;
  List<PosicionActiva> _microbuses = [];
  bool _loadingLineas = true;
  bool _loadingMicros = false;
  Timer? _refreshTimer;
  DateTime? _ultimaActualizacion;

  final _mapController = MapController();
  List<Marker> _busMarkers = [];

  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadLineas();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
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
      if (_lineaSeleccionada != null) _loadMicrobuses();
    } catch (_) {
      setState(() => _loadingLineas = false);
    }
  }

  Future<void> _loadMicrobuses() async {
    if (_lineaSeleccionada == null) return;
    setState(() => _loadingMicros = true);
    try {
      final raw = await _api.getMicrobusesActivos(_lineaSeleccionada!.id);
      final microbuses = raw
          .map((j) => PosicionActiva.fromJson(j as Map<String, dynamic>))
          .toList();

      final lineaColor = _lineaSeleccionada!.color;
      final markers = <Marker>[];
      for (final m in microbuses) {
        markers.add(Marker(
          point: LatLng(m.latitud, m.longitud),
          width: 48,
          height: 48,
          child: Tooltip(
            message: '${m.placa} · ${m.velocidad.toStringAsFixed(0)} km/h',
            child: Icon(Icons.directions_bus_rounded,
                color: lineaColor, size: 36),
          ),
        ));
      }

      setState(() {
        _microbuses = microbuses;
        _busMarkers = markers;
        _loadingMicros = false;
        _ultimaActualizacion = DateTime.now();
      });

      if (microbuses.isNotEmpty) {
        _mapController.move(
          LatLng(microbuses.first.latitud, microbuses.first.longitud),
          15.0,
        );
      }
    } catch (_) {
      setState(() => _loadingMicros = false);
    }
  }

  void _iniciarAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: AppConfig.intervaloActualizacionSegundos),
      (_) => _loadMicrobuses(),
    );
  }

  String get _tiempoActualizacion {
    if (_ultimaActualizacion == null) return '';
    final diff = DateTime.now().difference(_ultimaActualizacion!);
    if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
    return 'hace ${diff.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esperando Microbús'),
        backgroundColor: AppTheme.secondary,
        actions: [
          IconButton(
            icon: _loadingMicros
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _loadingMicros ? null : _loadMicrobuses,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona tu línea:',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (_loadingLineas)
                  const LinearProgressIndicator()
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
                                    setState(() {
                                      _lineaSeleccionada = l;
                                      _microbuses = [];
                                      _busMarkers = [];
                                    });
                                    _loadMicrobuses();
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(
            height: 300,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(AppConfig.mapLat, AppConfig.mapLng),
                    initialZoom: AppConfig.mapZoom,
                  ),
                  children: [
                    TileLayer(urlTemplate: AppTheme.mapTileUrl, userAgentPackageName: AppTheme.mapTileUserAgent),
                    MarkerLayer(markers: _busMarkers),
                  ],
                ),
                if (_loadingMicros)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: AppTheme.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _microbuses.isNotEmpty
                                ? AppTheme.success.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _microbuses.isNotEmpty
                                  ? AppTheme.success.withOpacity(0.4)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _microbuses.isNotEmpty
                                      ? AppTheme.success
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_microbuses.length} microbus(es) activos',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _microbuses.isNotEmpty
                                      ? AppTheme.success
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (_ultimaActualizacion != null)
                          Text(
                            'Actualizado $_tiempoActualizacion',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary),
                          ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _microbuses.isEmpty && !_loadingMicros
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_bus_outlined,
                                    size: 48,
                                    color: AppTheme.textSecondary),
                                SizedBox(height: 8),
                                Text(
                                  'No hay microbuses activos\nen esta línea ahora',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _microbuses.length,
                            itemBuilder: (context, i) {
                              final m = _microbuses[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _lineaSeleccionada
                                            ?.color
                                            .withOpacity(0.15) ??
                                        AppTheme.accent.withOpacity(0.15),
                                    child: Icon(
                                      Icons.directions_bus_rounded,
                                      color: _lineaSeleccionada?.color ??
                                          AppTheme.accent,
                                    ),
                                  ),
                                  title: Text(m.placa,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      '${m.velocidad.toStringAsFixed(0)} km/h',
                                      style:
                                          const TextStyle(fontSize: 12)),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'En ruta',
                                      style: TextStyle(
                                          color: AppTheme.success,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.autorenew,
                              size: 18, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Actualización automática cada 15s',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                            ),
                          ),
                          Switch(
                            value: _refreshTimer?.isActive ?? false,
                            activeColor: AppTheme.primary,
                            onChanged: (v) {
                              if (v) {
                                _iniciarAutoRefresh();
                              } else {
                                _refreshTimer?.cancel();
                              }
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
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
