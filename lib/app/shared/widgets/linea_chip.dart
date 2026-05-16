import 'package:flutter/material.dart';
import '../../../models/linea.dart';

class LineaChip extends StatelessWidget {
  final Linea linea;
  final bool selected;
  final VoidCallback? onTap;

  const LineaChip({
    super.key,
    required this.linea,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? linea.color : linea.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: linea.color, width: 1.5),
        ),
        child: Text(
          linea.nombre,
          style: TextStyle(
            color: selected ? Colors.white : linea.color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
