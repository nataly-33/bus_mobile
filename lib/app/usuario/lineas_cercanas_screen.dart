import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../shared/app_theme.dart';
import '../shared/widgets/mock_map.dart';
import '../../models/linea.dart';
import '../../services/arcgis_service.dart';
import 'recorrido_linea_screen.dart';

class LineasCercanasScreen extends StatefulWidget {
  const LineasCercanasScreen({super.key});

  @override
  State<LineasCercanasScreen> createState() =>
      _LineasCercanasScreenState();
}

class _LineasCercanasScreenState extends State<LineasCercanasScreen> {
  List<Linea> _lineasCercanas = [];
  bool _loading = false;
  bool _buscado = false;
  String _statusMsg = '';
  double _radioMetros = 300;

  final _arcgis = ArcGISService();

  Future<void> _buscarConGPS() async {
    setState(() {
      _loading = true;
      _statusMsg = 'Obteniendo tu ubicación...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('El GPS está desactivado. Actívalo e intenta de nuevo.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Permiso de ubicación denegado.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _setError('Permiso de ubicación denegado permanentemente.');
        return;
      }

      setState(() => _statusMsg = 'Buscando líneas cercanas...');
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      final lineas = await _arcgis.getLineasCercanas(
        pos.latitude,
        pos.longitude,
        radioMetros: _radioMetros,
      );

      setState(() {
        _lineasCercanas = lineas;
        _loading = false;
        _buscado = true;
        _statusMsg = '';
      });
    } catch (e) {
      _setError('Error al obtener ubicación. Intenta de nuevo.');
    }
  }

  Future<void> _buscarEnPunto() async {
    // Simulamos selección de punto en el mapa
    setState(() {
      _loading = true;
      _statusMsg = 'Buscando en punto seleccionado...';
    });
    await Future.delayed(const Duration(seconds: 1));
    final lineas = await _arcgis.getLineasCercanas(
      -17.7833,
      -63.1824,
      radioMetros: _radioMetros,
    );
    setState(() {
      _lineasCercanas = lineas;
      _loading = false;
      _buscado = true;
      _statusMsg = '';
    });
  }

  void _setError(String msg) {
    setState(() {
      _loading = false;
      _statusMsg = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Líneas Cercanas'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Column(
        children: [
          // Panel superior
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Radio selector
                Row(
                  children: [
                    const Icon(Icons.radar,
                        size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    const Text('Radio de búsqueda:',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    const Spacer(),
                    Text(
                      '${_radioMetros.toInt()} m',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          fontSize: 13),
                    ),
                  ],
                ),
                Slider(
                  value: _radioMetros,
                  min: 100,
                  max: 1000,
                  divisions: 9,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (v) => setState(() => _radioMetros = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _buscarConGPS,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Usar mi GPS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _buscarEnPunto,
                        icon: const Icon(Icons.touch_app, size: 18),
                        label: const Text('Punto en mapa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          side: const BorderSide(color: Color(0xFF2E7D32)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mapa (mitad superior cuando no hay resultados, más pequeño cuando hay)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _buscado && _lineasCercanas.isNotEmpty ? 200 : 280,
            child: Stack(
              children: [
                MockMapWidget(
                  showUserPin: true,
                  routes: _buscado
                      ? _lineasCercanas
                          .map((l) => MockRouteOverlay(
                              color: l.color, nombre: l.nombre))
                          .toList()
                      : [],
                ),
                // Radio visual
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF2E7D32).withOpacity(0.4),
                          width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Estado / loading
          if (_loading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text(_statusMsg,
                      style:
                          const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          else if (_statusMsg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: AppTheme.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_statusMsg,
                        style: const TextStyle(color: AppTheme.danger)),
                  ),
                ],
              ),
            )
          // Lista de líneas encontradas
          else if (_buscado)
            Expanded(
              child: _lineasCercanas.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 48, color: AppTheme.textSecondary),
                          SizedBox(height: 8),
                          Text('No se encontraron líneas cercanas',
                              style:
                                  TextStyle(color: AppTheme.textSecondary)),
                          SizedBox(height: 4),
                          Text('Intenta aumentar el radio de búsqueda',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text(
                            '${_lineasCercanas.length} línea(s) encontrada(s) en ${_radioMetros.toInt()} m',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF2E7D32)),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _lineasCercanas.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final l = _lineasCercanas[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: l.color.withOpacity(0.15),
                                  child: Icon(Icons.directions_bus,
                                      color: l.color, size: 22),
                                ),
                                title: Text(l.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: const Text(
                                    'Toca para ver el recorrido completo'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const RecorridoLineaScreen()),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            )
          else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 48, color: AppTheme.textSecondary),
                    SizedBox(height: 8),
                    Text(
                      'Presiona "Usar mi GPS" para buscar\nlíneas que pasan cerca de ti',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
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
