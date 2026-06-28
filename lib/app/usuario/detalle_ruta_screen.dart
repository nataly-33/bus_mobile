import 'package:flutter/material.dart';
import '../shared/app_theme.dart';
import '../../models/resultado_ruta.dart';

class DetalleRutaScreen extends StatelessWidget {
  final ResultadoRuta resultado;

  const DetalleRutaScreen({super.key, required this.resultado});

  Color _hexColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppTheme.primary;
    final cleaned = hex.replaceFirst('#', '');
    try {
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  String _sentidoLabel(int? idRuta) {
    if (idRuta == 1) return 'Ida';
    if (idRuta == 2) return 'Vuelta';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Ruta'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                resultado.tiempoFormateado,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _ResumenItem(
                  icon: Icons.schedule,
                  label: 'Tiempo total',
                  value: resultado.tiempoFormateado,
                ),
                _ResumenItem(
                  icon: Icons.transfer_within_a_station,
                  label: 'Trasbordos',
                  value: '${resultado.trasbordos}',
                ),
                _ResumenItem(
                  icon: Icons.directions_bus,
                  label: 'Líneas',
                  value: '${resultado.lineas.length}',
                ),
              ],
            ),
          ),

          // Timeline de pasos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: resultado.pasos.length,
              itemBuilder: (context, i) {
                final paso = resultado.pasos[i];
                final isLast = i == resultado.pasos.length - 1;

                if (paso.tipo == 'ruta') {
                  return _PasoRutaWidget(
                    paso: paso,
                    hexColor: _hexColor,
                    sentidoLabel: _sentidoLabel,
                    showLine: !isLast,
                  );
                } else {
                  return _PasoTransbordoWidget(
                    paso: paso,
                    showLine: !isLast,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ResumenItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _PasoRutaWidget extends StatelessWidget {
  final PasoRuta paso;
  final Color Function(String?) hexColor;
  final String Function(int?) sentidoLabel;
  final bool showLine;

  const _PasoRutaWidget({
    required this.paso,
    required this.hexColor,
    required this.sentidoLabel,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    final color = hexColor(paso.color);
    final mins = paso.tiempoMin?.round() ?? 0;
    final tiempoStr = mins < 60 ? '$mins min' : '${mins ~/ 60}h ${mins % 60}min';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline vertical
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child:
                      Icon(Icons.directions_bus, color: color, size: 18),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            paso.linea ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (paso.idRuta != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              border: Border.all(color: color, width: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              sentidoLabel(paso.idRuta),
                              style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        const Spacer(),
                        const Icon(Icons.schedule,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Text(tiempoStr,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.fiber_manual_record,
                            size: 10, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            paso.desdeDesc ?? '-',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Container(
                        width: 1,
                        height: 12,
                        color: color.withOpacity(0.3),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.fiber_manual_record,
                            size: 10, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            paso.hastaDesc ?? '-',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasoTransbordoWidget extends StatelessWidget {
  final PasoRuta paso;
  final bool showLine;

  const _PasoTransbordoWidget(
      {required this.paso, required this.showLine});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.secondary, width: 2),
                  ),
                  child: const Icon(Icons.transfer_within_a_station,
                      color: AppTheme.secondary, size: 18),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.accent.withOpacity(0.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.accent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Trasbordo',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                              fontSize: 13),
                        ),
                        const Spacer(),
                        const Icon(Icons.schedule,
                            size: 13,
                            color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '${paso.penalizacionMin?.round() ?? 5} min',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'En: ${paso.enDesc ?? '-'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${paso.deLinea ?? '?'} → ${paso.aLinea ?? '?'}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
