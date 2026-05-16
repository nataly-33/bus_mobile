import 'dart:async';
import 'package:flutter/material.dart';
import '../shared/app_theme.dart';
import '../shared/widgets/mock_map.dart';
import '../shared/widgets/linea_chip.dart';
import '../../models/linea.dart';
import '../../models/posicion_gps.dart';
import '../../services/arcgis_service.dart';

class EsperandoMicrobusScreen extends StatefulWidget {
  const EsperandoMicrobusScreen({super.key});

  @override
  State<EsperandoMicrobusScreen> createState() =>
      _EsperandoMicrobusScreenState();
}

class _EsperandoMicrobusScreenState
    extends State<EsperandoMicrobusScreen> {
  List<Linea> _lineas = [];
  Linea? _lineaSeleccionada;
  List<PosicionGPS> _microbuses = [];
  bool _loadingLineas = true;
  bool _loadingMicros = false;
  Timer? _refreshTimer;
  DateTime? _ultimaActualizacion;

  final _arcgis = ArcGISService();

  @override
  void initState() {
    super.initState();
    _loadLineas();
  }

  Future<void> _loadLineas() async {
    final lineas = await _arcgis.getLineas();
    setState(() {
      _lineas = lineas;
      _lineaSeleccionada = lineas.isNotEmpty ? lineas.first : null;
      _loadingLineas = false;
    });
    if (_lineaSeleccionada != null) _loadMicrobuses();
  }

  Future<void> _loadMicrobuses() async {
    if (_lineaSeleccionada == null) return;
    setState(() => _loadingMicros = true);
    final micros = await _arcgis.getMicrobusesActivos(_lineaSeleccionada!.id);
    setState(() {
      _microbuses = micros;
      _loadingMicros = false;
      _ultimaActualizacion = DateTime.now();
    });
  }

  void _iniciarAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadMicrobuses();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<MockBusMarker> get _busMarkers {
    const positions = [
      [0.25, 0.48],
      [0.55, 0.52],
      [0.75, 0.45],
    ];
    return List.generate(
      _microbuses.length.clamp(0, positions.length),
      (i) => MockBusMarker(
        label: _microbuses[i].placa,
        relX: positions[i][0],
        relY: positions[i][1],
        color: _lineaSeleccionada?.color ?? AppTheme.accent,
      ),
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
        backgroundColor: AppTheme.accent,
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
          // Selector de línea
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

          // Mapa
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                MockMapWidget(
                  busMarkers: _busMarkers,
                  routes: _lineaSeleccionada != null
                      ? [
                          MockRouteOverlay(
                            color: _lineaSeleccionada!.color,
                            nombre: _lineaSeleccionada!.nombre,
                          )
                        ]
                      : [],
                ),
                if (_loadingMicros)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),

          // Panel de microbuses activos
          Expanded(
            child: Container(
              color: AppTheme.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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

                  // Lista
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
                                  title: Text(
                                    m.placa,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Sentido: ${m.sentido}  •  ${m.velocidad.toStringAsFixed(0)} km/h',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.success.withOpacity(0.1),
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

                  // Auto-refresh toggle
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
                              'Actualización automática cada 15 segundos',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                            ),
                          ),
                          Switch(
                            value: _refreshTimer?.isActive ?? false,
                            activeColor: AppTheme.accent,
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
