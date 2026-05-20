import 'dart:async';
import 'package:flutter/material.dart';
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

  List<Linea> _lineas = [];
  Linea? _lineaSeleccionada;
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegistroMicrobusScreen()),
      );
      return;
    }

    List<Linea> lineas = [];
    try {
      final raw = await _api.getLineas();
      lineas = raw
          .map((j) => Linea.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    final lineaInicial = lineaId != null && lineas.isNotEmpty
        ? lineas.firstWhere((l) => l.id == lineaId,
            orElse: () => lineas.first)
        : lineas.isNotEmpty
            ? lineas.first
            : null;

    setState(() {
      _nombre = prefs.getString('conductor_nombre') ?? 'Conductor';
      _placa = placa;
      _conductorId = prefs.getInt('conductor_id') ?? 0;
      _microbusId = prefs.getInt('microbus_id') ?? 0;
      _lineas = lineas;
      _lineaSeleccionada = lineaInicial;
    });
  }

  Future<void> _iniciarRecorrido() async {
    if (_lineaSeleccionada == null) return;

    final rutaId = _lineaSeleccionada!.rutaIdForSentido(_sentido);
    if (rutaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta línea aún no tiene ruta configurada.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await _api.iniciarRecorrido({
        'microbus_id': _microbusId,
        'linea_ruta_id': rutaId,
      });
      _recorridoId = res['recorrido_id'];
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo iniciar el recorrido. Verifica conexión.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return;
    }

    setState(() {
      _recorridoActivo = true;
      _loading = false;
      _segundosTranscurridos = 0;
      _distanciaAcumulada = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _segundosTranscurridos++);
    });

    _gpsTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_recorridoId == null) return;
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (_lastPosition != null) {
          _distanciaAcumulada += Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            pos.latitude,
            pos.longitude,
          );
        }
        _lastPosition = pos;
        setState(() => _velocidadActual = (pos.speed * 3.6).clamp(0, 120));

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
      try {
        await _api.terminarRecorrido(_recorridoId!, motivo: motivo);
      } catch (_) {}
    }
    setState(() {
      _recorridoActivo = false;
      _velocidadActual = 0;
      _lastPosition = null;
      _recorridoId = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(motivo != null
              ? 'Salida registrada: $motivo'
              : 'Recorrido terminado. ¡Buen trabajo!'),
          backgroundColor:
              motivo != null ? AppTheme.danger : AppTheme.success,
        ),
      );
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
        content:
            const Text('¿Seguro que quieres cerrar sesión como conductor?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar sesión',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok == true) {
      if (_recorridoActivo) await _terminarRecorrido();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectorScreen()),
        (_) => false,
      );
    }
  }

  String get _tiempoFormato {
    final h = _segundosTranscurridos ~/ 3600;
    final m = (_segundosTranscurridos % 3600) ~/ 60;
    final s = _segundosTranscurridos % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lineas.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Panel Conductor'),
        backgroundColor: AppTheme.accent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de bienvenida
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.accent.withOpacity(0.15),
                      child: const Icon(Icons.person,
                          color: AppTheme.accent, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenido, ${_nombre.split(' ').first}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.directions_bus,
                                  size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Microbús: $_placa',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _recorridoActivo
                            ? AppTheme.success.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _recorridoActivo
                                  ? AppTheme.success
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _recorridoActivo ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _recorridoActivo
                                  ? AppTheme.success
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_recorridoActivo) ...[
              Card(
                color: AppTheme.success.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: AppTheme.success.withOpacity(0.3), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.timer,
                        label: 'Tiempo',
                        value: _tiempoFormato,
                        color: AppTheme.success,
                      ),
                      _StatItem(
                        icon: Icons.speed,
                        label: 'Velocidad',
                        value: '${_velocidadActual.toStringAsFixed(0)} km/h',
                        color: AppTheme.primary,
                      ),
                      _StatItem(
                        icon: Icons.straighten,
                        label: 'Distancia',
                        value:
                            '${(_distanciaAcumulada / 1000).toStringAsFixed(1)} km',
                        color: AppTheme.accent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Línea a recorrer:',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _lineas.map((l) {
                final selected = _lineaSeleccionada?.id == l.id;
                return GestureDetector(
                  onTap: _recorridoActivo
                      ? null
                      : () => setState(() => _lineaSeleccionada = l),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? l.color
                          : l.color.withOpacity(
                              _recorridoActivo ? 0.05 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: l.color
                              .withOpacity(_recorridoActivo ? 0.3 : 1),
                          width: 1.5),
                    ),
                    child: Text(
                      l.nombre,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : l.color.withOpacity(
                                _recorridoActivo ? 0.5 : 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            const Text(
              'Sentido:',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SentidoButton(
                    label: 'Ida',
                    icon: Icons.arrow_forward,
                    selected: _sentido == 'ida',
                    disabled: _recorridoActivo,
                    onTap: () => _recorridoActivo
                        ? null
                        : setState(() => _sentido = 'ida'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SentidoButton(
                    label: 'Vuelta',
                    icon: Icons.arrow_back,
                    selected: _sentido == 'vuelta',
                    disabled: _recorridoActivo,
                    onTap: () => _recorridoActivo
                        ? null
                        : setState(() => _sentido = 'vuelta'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (!_recorridoActivo)
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: (_lineaSeleccionada == null || _loading)
                      ? null
                      : _iniciarRecorrido,
                  icon: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.play_arrow, size: 28),
                  label: const Text('INICIAR RECORRIDO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            if (_recorridoActivo) ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _terminarRecorrido,
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('TERMINAR\nRECORRIDO',
                            textAlign: TextAlign.center),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _salirRuta,
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('SALIR\nDE RUTA',
                            textAlign: TextAlign.center),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _SentidoButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _SentidoButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.disabled,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(disabled ? 0.3 : 1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.primary.withOpacity(disabled ? 0.2 : 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? Colors.white : AppTheme.primary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalirRutaDialog extends StatelessWidget {
  const _SalirRutaDialog();

  final _motivos = const [
    'Avería mecánica',
    'Accidente de tráfico',
    'Fin de turno',
    'Emergencia personal',
    'Otro motivo',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
          SizedBox(width: 8),
          Text('Motivo de salida'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _motivos
            .map((m) => ListTile(
                  leading: const Icon(Icons.circle,
                      size: 8, color: AppTheme.danger),
                  title: Text(m),
                  onTap: () => Navigator.pop(context, m),
                ))
            .toList(),
      ),
    );
  }
}
