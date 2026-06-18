import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../shared/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/linea.dart';
import 'registro_microbus_screen.dart';
import '../../main.dart';

class ConductorHomeScreen extends StatefulWidget {
  const ConductorHomeScreen({super.key});

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  String _nombre = '';
  String _placa = '';
  int _conductorId = 0;
  int _microbusId = 0;

  // Solo la línea asignada al conductor
  Linea? _lineaAsignada;
  String _sentido = 'ida';

  bool _recorridoActivo = false;
  bool _loading = false;
  Timer? _timer;
  Timer? _gpsTimer;
  int _segundosTranscurridos = 0;
  double _velocidadActual = 0;
  double _distanciaAcumulada = 0;
  Position? _lastPosition;
  int? _recorridoId;

  // Mapa GPS del conductor
  final _mapController = MapController();
  LatLng? _posActual;
  final List<LatLng> _trail = [];

  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final placa = prefs.getString('microbus_placa');
    final lineaId = prefs.getInt('microbus_linea_id');

    if (placa == null || placa.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const RegistroMicrobusScreen()));
      return;
    }

    // Cargar solo la línea asignada
    Linea? linea;
    try {
      final raw = await _api.getLineas();
      final lineas = raw.map((j) => Linea.fromJson(j as Map<String, dynamic>)).toList();
      if (lineaId != null && lineas.isNotEmpty) {
        try { linea = lineas.firstWhere((l) => l.id == lineaId); }
        catch (_) { linea = lineas.isNotEmpty ? lineas.first : null; }
      } else if (lineas.isNotEmpty) {
        linea = lineas.first;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _nombre = prefs.getString('conductor_nombre') ?? 'Conductor';
      _placa = placa;
      _conductorId = prefs.getInt('conductor_id') ?? 0;
      _microbusId = prefs.getInt('microbus_id') ?? 0;
      _lineaAsignada = linea;
    });
  }

  Future<void> _iniciarRecorrido() async {
    if (_lineaAsignada == null) return;
    final rutaId = _lineaAsignada!.rutaIdForSentido(_sentido);
    if (rutaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Esta línea no tiene ruta configurada.'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    // Solicitar permiso GPS antes de iniciar
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Activa el GPS para registrar el recorrido.'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();

    setState(() => _loading = true);
    try {
      final res = await _api.iniciarRecorrido({'microbus_id': _microbusId, 'linea_ruta_id': rutaId});
      _recorridoId = res['recorrido_id'];
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se pudo iniciar. Verifica conexión.'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    // Obtener posición inicial
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final punto = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _posActual = punto;
        _trail.add(punto);
      });
      _mapController.move(punto, 15.5);
    } catch (_) {}

    setState(() {
      _recorridoActivo = true;
      _loading = false;
      _segundosTranscurridos = 0;
      _distanciaAcumulada = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _segundosTranscurridos++);
    });

    _gpsTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (_recorridoId == null) return;
      try {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (_lastPosition != null) {
          _distanciaAcumulada += Geolocator.distanceBetween(
            _lastPosition!.latitude, _lastPosition!.longitude,
            pos.latitude, pos.longitude,
          );
        }
        _lastPosition = pos;
        final punto = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _velocidadActual = (pos.speed * 3.6).clamp(0, 120);
          _posActual = punto;
          _trail.add(punto);
        });
        // Auto-centrar mapa en posición actual
        _mapController.move(punto, _mapController.camera.zoom);

        await _api.enviarPosicion(
          recorridoId: _recorridoId!,
          lat: pos.latitude,
          lng: pos.longitude,
          velocidad: _velocidadActual,
          distancia: _distanciaAcumulada,
          tiempoSeg: _segundosTranscurridos,
        );
      } catch (_) {}
    });
  }

  Future<void> _terminarRecorrido({String? motivo}) async {
    _timer?.cancel();
    _gpsTimer?.cancel();
    if (_recorridoId != null) {
      try { await _api.terminarRecorrido(_recorridoId!, motivo: motivo); } catch (_) {}
    }
    setState(() {
      _recorridoActivo = false;
      _velocidadActual = 0;
      _lastPosition = null;
      _recorridoId = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(motivo != null ? 'Salida: $motivo' : '¡Recorrido finalizado!'),
        backgroundColor: motivo != null ? AppTheme.danger : AppTheme.success,
      ));
    }
  }

  Future<void> _salirRuta() async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => const _SalirRutaDialog(),
    );
    if (motivo == null) return;
    await _terminarRecorrido(motivo: motivo);
  }

  Future<void> _cerrarSesion() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Salir de tu cuenta de conductor?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok == true) {
      if (_recorridoActivo) await _terminarRecorrido();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const RoleSelectorScreen()), (_) => false);
    }
  }

  String get _tiempoFormato {
    final h = _segundosTranscurridos ~/ 3600;
    final m = (_segundosTranscurridos % 3600) ~/ 60;
    final s = _segundosTranscurridos % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lineaAsignada == null && _nombre.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final lineaColor = _lineaAsignada?.color ?? AppTheme.secondary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Panel Conductor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Tarjeta bienvenida ──────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.primary.withOpacity(0.15),
                      child: const Icon(Icons.person, color: AppTheme.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nombre.split(' ').first,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary),
                          ),
                          Text('Microbús $_placa',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    _EstadoBadge(activo: _recorridoActivo),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Línea asignada ──────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: lineaColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.route, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lineaAsignada?.nombre ?? 'Sin línea asignada',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: lineaColor,
                                fontSize: 15),
                          ),
                          Text('Línea asignada',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    // Selector de sentido
                    if (!_recorridoActivo) ...[
                      _SentidoChip(
                        label: 'Ida',
                        selected: _sentido == 'ida',
                        color: lineaColor,
                        onTap: () => setState(() => _sentido = 'ida'),
                      ),
                      const SizedBox(width: 6),
                      _SentidoChip(
                        label: 'Vuelta',
                        selected: _sentido == 'vuelta',
                        color: lineaColor,
                        onTap: () => setState(() => _sentido = 'vuelta'),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: lineaColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _sentido == 'ida' ? '→ Ida' : '← Vuelta',
                          style: TextStyle(
                              color: lineaColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Stats del recorrido activo ──────────────────────────────────
            if (_recorridoActivo) ...[
              Card(
                color: AppTheme.primary.withOpacity(0.04),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppTheme.primary.withOpacity(0.2))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(Icons.timer, _tiempoFormato, 'Tiempo', AppTheme.primary),
                      _Divider(),
                      _StatItem(Icons.speed, '${_velocidadActual.toStringAsFixed(0)} km/h',
                          'Velocidad', AppTheme.secondary),
                      _Divider(),
                      _StatItem(Icons.straighten,
                          '${(_distanciaAcumulada / 1000).toStringAsFixed(2)} km',
                          'Distancia', AppTheme.parrotPink),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Mapa GPS con trail ────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 220,
                  child: Stack(children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: LatLng(-17.7833, -63.1824),
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: AppTheme.mapTileUrl,
                          userAgentPackageName: AppTheme.mapTileUserAgent,
                        ),
                        if (_trail.length >= 2)
                          PolylineLayer(polylines: [
                            Polyline(
                              points: _trail,
                              color: lineaColor,
                              strokeWidth: 5.0,
                              borderColor: Colors.white,
                              borderStrokeWidth: 1.5,
                            ),
                          ]),
                        if (_posActual != null)
                          MarkerLayer(markers: [
                            Marker(
                              point: _posActual!,
                              width: 36,
                              height: 44,
                              alignment: Alignment.bottomCenter,
                              child: Icon(Icons.navigation_rounded,
                                  color: lineaColor, size: 34),
                            ),
                          ]),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: FloatingActionButton.small(
                        heroTag: 'north_cond',
                        onPressed: () => _mapController.rotate(0),
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        elevation: 2,
                        child: const Icon(Icons.explore, size: 18),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Botones ──────────────────────────────────────────────────────
            if (!_recorridoActivo)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_lineaAsignada == null || _loading) ? null : _iniciarRecorrido,
                  icon: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.play_arrow_rounded, size: 26),
                  label: const Text('INICIAR RECORRIDO',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : () => _terminarRecorrido(),
                        icon: const Icon(Icons.stop_circle_outlined, size: 22),
                        label: const Text('TERMINAR',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _salirRuta,
                        icon: const Icon(Icons.exit_to_app, size: 22),
                        label: const Text('SALIR',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _EstadoBadge extends StatelessWidget {
  final bool activo;
  const _EstadoBadge({required this.activo});

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppTheme.success : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(activo ? 'Activo' : 'Inactivo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatItem(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppTheme.lavenderBlush);
  }
}

class _SentidoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _SentidoChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : color),
        ),
      ),
    );
  }
}

class _SalirRutaDialog extends StatelessWidget {
  const _SalirRutaDialog();
  static const _motivos = [
    'Avería mecánica',
    'Accidente de tráfico',
    'Fin de turno',
    'Emergencia personal',
    'Otro motivo',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
        SizedBox(width: 8),
        Text('Motivo de salida'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _motivos
            .map((m) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.circle, size: 8, color: AppTheme.danger),
                  title: Text(m, style: const TextStyle(fontSize: 14)),
                  onTap: () => Navigator.pop(context, m),
                ))
            .toList(),
      ),
    );
  }
}
