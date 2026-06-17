import 'package:flutter/material.dart';
import '../shared/app_theme.dart';
import 'recorrido_linea_screen.dart';
import 'lineas_cercanas_screen.dart';
import 'esperando_microbus_screen.dart';
import 'buscar_ruta_screen.dart';

class UsuarioHomeScreen extends StatelessWidget {
  const UsuarioHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
                child: const SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Icon(Icons.directions_bus_rounded,
                          size: 48, color: Colors.white70),
                      SizedBox(height: 8),
                      Text(
                        'MicroBus SCZ',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Santa Cruz de la Sierra',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Text('MicroBus SCZ',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  '¿Qué deseas hacer?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _MenuCard(
                  icon: Icons.alt_route,
                  iconColor: AppTheme.primary,
                  title: 'Buscar ruta óptima',
                  subtitle:
                      'Encuentra la mejor ruta entre dos paradas usando Dijkstra con trasbordos',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BuscarRutaScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                _MenuCard(
                  icon: Icons.map_outlined,
                  iconColor: AppTheme.secondary,
                  title: 'Recorrido de línea',
                  subtitle:
                      'Visualiza el trayecto completo de cualquier línea de microbús en el mapa',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RecorridoLineaScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                _MenuCard(
                  icon: Icons.location_searching,
                  iconColor: const Color(0xFF2E7D32),
                  title: '¿Qué líneas pasan aquí?',
                  subtitle:
                      'Detecta automáticamente las líneas que pasan cerca de tu ubicación actual',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LineasCercanasScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                _MenuCard(
                  icon: Icons.access_time_rounded,
                  iconColor: AppTheme.accent,
                  title: 'Esperando microbús',
                  subtitle:
                      'Ve en tiempo real dónde están los microbuses activos de tu línea',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EsperandoMicrobusScreen()),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.primary, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Las posiciones se actualizan cada 30 segundos en tiempo real.',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: iconColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
