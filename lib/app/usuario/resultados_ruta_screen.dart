import 'package:flutter/material.dart';
import '../shared/app_theme.dart';
import '../../models/resultado_ruta.dart';
import 'detalle_ruta_screen.dart';
import 'mapa_ruta_screen.dart';

class ResultadosRutaScreen extends StatelessWidget {
  final List<ResultadoRuta> resultados;

  const ResultadosRutaScreen({super.key, required this.resultados});

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
    return Scaffold(
      appBar: AppBar(
        title: Text('${resultados.length} Ruta(s) Encontradas'),
      ),
      body: Column(
        children: [
          // Cabecera origen → destino
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.trip_origin, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resultados.first.origenDesc,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward,
                      color: AppTheme.textSecondary, size: 16),
                ),
                Expanded(
                  child: Text(
                    resultados.first.destinoDesc,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.location_on, color: Colors.blue, size: 20),
              ],
            ),
          ),

          // Lista de resultados
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: resultados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final r = resultados[i];
                final esMejor = i == 0;
                return _ResultadoCard(
                  resultado: r,
                  esMejor: esMejor,
                  hexColor: _hexColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetalleRutaScreen(resultado: r),
                    ),
                  ),
                  onVerMapa: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapaRutaScreen(resultado: r),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultadoCard extends StatelessWidget {
  final ResultadoRuta resultado;
  final bool esMejor;
  final Color Function(String?) hexColor;
  final VoidCallback onTap;
  final VoidCallback onVerMapa;

  const _ResultadoCard({
    required this.resultado,
    required this.esMejor,
    required this.hexColor,
    required this.onTap,
    required this.onVerMapa,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      elevation: esMejor ? 4 : 2,
      shadowColor: esMejor
          ? AppTheme.primary.withOpacity(0.2)
          : Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: esMejor
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primary.withOpacity(0.5), width: 1.5),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header fila
                Row(
                  children: [
                    if (esMejor)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Mejor ruta',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (esMejor) const SizedBox(width: 8),
                    const Icon(Icons.schedule,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      resultado.tiempoFormateado,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    if (resultado.trasbordos > 0)
                      Chip(
                        label: Text(
                            '${resultado.trasbordos} trasbordo(s)',
                            style:
                                const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor:
                            AppTheme.accent.withOpacity(0.3),
                        side: BorderSide.none,
                      )
                    else
                      const Chip(
                        label: Text('Sin trasbordo',
                            style: TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Color(0xFFE8F5E9),
                        side: BorderSide.none,
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Chips de líneas
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: resultado.lineas.indexed.map((entry) {
                    final pasos = resultado.pasos
                        .where((p) =>
                            p.tipo == 'ruta' && p.linea == entry.$2)
                        .toList();
                    final color = pasos.isNotEmpty
                        ? hexColor(pasos.first.color)
                        : AppTheme.primary;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: color.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.$2,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.list_alt, size: 16),
                        label: const Text('Paso a paso',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(
                              color: AppTheme.primary.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onVerMapa,
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Ver en mapa',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
