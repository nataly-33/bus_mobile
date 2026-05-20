import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../shared/app_theme.dart';
import '../../services/api_service.dart';
import 'conductor_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _checking = true;
  bool _loading = false;
  bool _modoLogin = false; // false = registro, true = login

  // Campos registro
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _ciCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _sexo = 'M';
  DateTime? _fechaNacimiento;
  File? _foto;

  // Campos login
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('conductor_id');
    if (id != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ConductorHomeScreen()),
      );
    } else {
      setState(() => _checking = false);
    }
  }

  Future<void> _pickFoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) setState(() => _foto = File(picked.path));
  }

  Future<void> _pickFecha() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (date != null) setState(() => _fechaNacimiento = date);
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      _showError('Selecciona tu fecha de nacimiento');
      return;
    }
    setState(() => _loading = true);

    final datos = {
      'nombre': '${_nombreCtrl.text.trim()} ${_apellidoCtrl.text.trim()}',
      'ci': _ciCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'sexo': _sexo,
      'fecha_nacimiento':
          '${_fechaNacimiento!.year}-${_fechaNacimiento!.month.toString().padLeft(2, '0')}-${_fechaNacimiento!.day.toString().padLeft(2, '0')}',
      'categoria_licencia': 'B',
    };

    try {
      final res = await _api.registrarConductor(datos);
      if (res.containsKey('id')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('conductor_id', res['id']);
        await prefs.setString('conductor_nombre', datos['nombre']!);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConductorHomeScreen()),
        );
      } else {
        setState(() => _loading = false);
        _showError(res['email']?.toString() ??
            res['ci']?.toString() ??
            'Error al registrar. Intenta de nuevo.');
      }
    } catch (_) {
      setState(() => _loading = false);
      _showError('No se pudo conectar al servidor.');
    }
  }

  Future<void> _login() async {
    if (_loginEmailCtrl.text.isEmpty || _loginPasswordCtrl.text.isEmpty) {
      _showError('Ingresa tu correo y contraseña');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _api.loginConductor(
        _loginEmailCtrl.text.trim(),
        _loginPasswordCtrl.text,
      );
      if (res.containsKey('conductor_id')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('conductor_id', res['conductor_id']);
        await prefs.setString(
            'conductor_nombre', res['nombre'] ?? 'Conductor');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConductorHomeScreen()),
        );
      } else {
        setState(() => _loading = false);
        _showError(res['error']?.toString() ?? 'Credenciales incorrectas.');
      }
    } catch (_) {
      setState(() => _loading = false);
      _showError('No se pudo conectar al servidor.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.danger));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _ciCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person,
                        color: AppTheme.accent, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _modoLogin ? 'Iniciar Sesión' : 'Registro de Conductor',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary),
                      ),
                      Text(
                        _modoLogin
                            ? 'Ingresa tus credenciales'
                            : 'Completa tus datos personales',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_modoLogin) _buildLoginForm() else _buildRegistroForm(),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    setState(() => _modoLogin = !_modoLogin),
                child: Text(
                  _modoLogin
                      ? '¿No tienes cuenta? Regístrate'
                      : '¿Ya tienes cuenta? Inicia sesión',
                  style: const TextStyle(color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _loginEmailCtrl,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _loginPasswordCtrl,
          decoration: const InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: Icon(Icons.lock_outlined),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _login,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent),
            child: _loading
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
                : const Text('INICIAR SESIÓN'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistroForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickFoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.accent.withOpacity(0.15),
                    backgroundImage:
                        _foto != null ? FileImage(_foto!) : null,
                    child: _foto == null
                        ? const Icon(Icons.camera_alt,
                            size: 36, color: AppTheme.accent)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Foto (opcional)',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _apellidoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Apellido *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _ciCtrl,
            decoration: const InputDecoration(
              labelText: 'Cédula de Identidad (CI) *',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            keyboardType: TextInputType.number,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _telefonoCtrl,
            decoration: const InputDecoration(
              labelText: 'Teléfono *',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: 'Ej: 70012345',
            ),
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico *',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Campo requerido';
              if (!v.contains('@')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _passwordCtrl,
            decoration: const InputDecoration(
              labelText: 'Contraseña *',
              prefixIcon: Icon(Icons.lock_outlined),
            ),
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Campo requerido';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: _sexo,
            decoration: const InputDecoration(
              labelText: 'Sexo *',
              prefixIcon: Icon(Icons.wc_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'M', child: Text('Masculino')),
              DropdownMenuItem(value: 'F', child: Text('Femenino')),
            ],
            onChanged: (v) => setState(() => _sexo = v!),
          ),
          const SizedBox(height: 14),

          GestureDetector(
            onTap: _pickFecha,
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Fecha de Nacimiento *',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  hintText: _fechaNacimiento == null
                      ? 'Seleccionar fecha'
                      : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                ),
                controller: TextEditingController(
                  text: _fechaNacimiento == null
                      ? ''
                      : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _registrar,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent),
              child: _loading
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : const Text('REGISTRARME'),
            ),
          ),
        ],
      ),
    );
  }
}
