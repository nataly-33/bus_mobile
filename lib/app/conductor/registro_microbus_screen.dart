import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../shared/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/linea.dart';
import 'conductor_home_screen.dart';

class RegistroMicrobusScreen extends StatefulWidget {
  const RegistroMicrobusScreen({super.key});

  @override
  State<RegistroMicrobusScreen> createState() =>
      _RegistroMicrobusScreenState();
}

class _RegistroMicrobusScreenState extends State<RegistroMicrobusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _asientosCtrl = TextEditingController(text: '20');
  final _numInternoCtrl = TextEditingController();
  Linea? _lineaSeleccionada;
  File? _foto;
  bool _loading = false;
  List<Linea> _lineas = [];

  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadLineas();
  }

  Future<void> _loadLineas() async {
    try {
      final raw = await _api.getLineas();
      setState(() => _lineas =
          raw.map((j) => Linea.fromJson(j as Map<String, dynamic>)).toList());
    } catch (_) {}
  }

  Future<void> _pickFoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _foto = File(picked.path));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lineaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona la línea que recorres'),
            backgroundColor: AppTheme.danger),
      );
      return;
    }
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final conductorId = prefs.getInt('conductor_id') ?? 0;
    final hoy =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    final datos = {
      'placa': _placaCtrl.text.trim().toUpperCase(),
      'modelo': _modeloCtrl.text.trim(),
      'cantidad_asientos': int.tryParse(_asientosCtrl.text) ?? 20,
      'numero_interno': _numInternoCtrl.text.trim().isNotEmpty
          ? _numInternoCtrl.text.trim()
          : _placaCtrl.text.trim().toUpperCase(),
      'conductor': conductorId,
      'linea': _lineaSeleccionada!.id,
      'fecha_asignacion': hoy,
    };

    try {
      final res = await _api.registrarMicrobus(datos);
      if (res.containsKey('id')) {
        await prefs.setInt('microbus_id', res['id']);
        await prefs.setString(
            'microbus_placa', datos['placa'] as String);
        await prefs.setInt(
            'microbus_linea_id', _lineaSeleccionada!.id);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConductorHomeScreen()),
        );
      } else {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(res.toString()),
                backgroundColor: AppTheme.danger),
          );
        }
      }
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo conectar al servidor.'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  void dispose() {
    _placaCtrl.dispose();
    _modeloCtrl.dispose();
    _colorCtrl.dispose();
    _asientosCtrl.dispose();
    _numInternoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Microbús'),
        backgroundColor: AppTheme.accent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foto del microbús
              Center(
                child: GestureDetector(
                  onTap: _pickFoto,
                  child: Container(
                    width: 160,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.accent.withOpacity(0.3), width: 2),
                      image: _foto != null
                          ? DecorationImage(
                              image: FileImage(_foto!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _foto == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_bus,
                                  size: 40, color: AppTheme.accent),
                              SizedBox(height: 4),
                              Text('Agregar foto',
                                  style: TextStyle(
                                      color: AppTheme.accent, fontSize: 12)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _placaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Placa *',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                  hintText: 'Ej: ABC-1234',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _modeloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Modelo *',
                  prefixIcon: Icon(Icons.directions_bus_outlined),
                  hintText: 'Ej: Toyota Hiace',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _numInternoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Número interno',
                  prefixIcon: Icon(Icons.tag),
                  hintText: 'Ej: 007 (opcional)',
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _asientosCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de asientos *',
                  prefixIcon: Icon(Icons.airline_seat_recline_normal),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 5 || n > 60) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Selector de línea
              const Text(
                'Línea principal que recorre:',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),
              if (_lineas.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _lineas.map((l) {
                    final selected = _lineaSeleccionada?.id == l.id;
                    return GestureDetector(
                      onTap: () => setState(() => _lineaSeleccionada = l),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? l.color
                              : l.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: l.color, width: 1.5),
                        ),
                        child: Text(
                          l.nombre,
                          style: TextStyle(
                            color: selected ? Colors.white : l.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent),
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text('GUARDAR MICROBÚS'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
