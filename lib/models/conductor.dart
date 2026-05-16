class Conductor {
  final int? id;
  final String nombre;
  final String apellido;
  final String ci;
  final String telefono;
  final String sexo;
  final String fechaNacimiento;
  final String? fotoUrl;

  const Conductor({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.ci,
    required this.telefono,
    required this.sexo,
    required this.fechaNacimiento,
    this.fotoUrl,
  });

  String get nombreCompleto => '$nombre $apellido';

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'apellido': apellido,
        'ci': ci,
        'telefono': telefono,
        'sexo': sexo,
        'fecha_nacimiento': fechaNacimiento,
        'foto_url': fotoUrl ?? '',
      };
}
