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
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('MicroBus SCZ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono con fondo circular translúcido
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'MicroBus SCZ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Santa Cruz de la Sierra',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_city,
                                size: 13, color: Colors.white70),
                            SizedBox(width: 5),
                            Text(
                              'Sistema de transporte urbano',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
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
                const SizedBox(height: 4),
                const Text(
                  'Elige una opción para comenzar',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Grid 2x2
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.92,
                  children: [
                    _GridCard(
                      icon: Icons.alt_route,
                      title: 'Buscar ruta',
                      subtitle: 'Origen → Destino',
                      color: AppTheme.primary,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const BuscarRutaScreen())),
                    ),
                    _GridCard(
                      icon: Icons.map_outlined,
                      title: 'Recorridos',
                      subtitle: 'Ver trayecto de líneas',
                      color: AppTheme.secondary,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const RecorridoLineaScreen())),
                    ),
                    _GridCard(
                      icon: Icons.location_searching,
                      title: 'Líneas cercanas',
                      subtitle: 'Rutas en mi zona',
                      color: AppTheme.deepPuce,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const LineasCercanasScreen())),
                    ),
                    _GridCard(
                      icon: Icons.directions_bus_rounded,
                      title: 'Buses activos',
                      subtitle: 'Ubicación en tiempo real',
                      color: AppTheme.parrotPink,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const EsperandoMicrobusScreen())),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Tip inferior
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.lavenderBlush,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.paleChestnut),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined,
                          size: 20, color: AppTheme.secondary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Toca el mapa para elegir tu parada de origen '
                          'y destino al buscar rutas.',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
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

class _GridCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GridCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<_GridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_pressed ? 0.22 : 0.12),
                blurRadius: _pressed ? 6 : 14,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _pressed
                  ? widget.color.withOpacity(0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono con fondo cuadrado redondeado
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withOpacity(0.18),
                      widget.color.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(widget.icon, color: widget.color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
