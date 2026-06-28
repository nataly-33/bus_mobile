import 'package:flutter/material.dart';

/// Widget que muestra el icono de bus rosa personalizado.
/// Reemplaza Icons.directions_bus en toda la aplicación.
class BusIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const BusIcon({
    Key? key,
    this.size = 24.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/icono_rosa.png',
      width: size,
      height: size,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : BlendMode.dst,
    );
  }
}
