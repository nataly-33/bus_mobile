import 'package:flutter/material.dart';

class AppTheme {
  // Paleta rosa/marrón
  static const Color primary       = Color(0xFF703642);  // Catawba — headers, acciones
  static const Color secondary     = Color(0xFFA0527A);  // Deep Puce — acciones secundarias
  static const Color accent        = Color(0xFFF4ABBA);  // Parrot Pink — chips, highlights
  static const Color paleRose      = Color(0xFFDDADAD);  // Pale Chestnut — fondos suaves
  static const Color background    = Color(0xFFF2F2F2);  // Anti-Flash White — fondo general
  static const Color cardBg        = Color(0xFFFFFFFF);  // blanco — tarjetas
  static const Color textPrimary   = Color(0xFF000000);  // negro — texto principal
  static const Color textSecondary = Color(0xFF8D6E63);  // marrón claro — texto secundario
  static const Color success       = Color(0xFF2E7D32);  // verde — estados positivos
  static const Color danger        = Color(0xFFC62828);  // rojo — errores

  // Gradiente de cabecera (Catawba → Deep Puce)
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF703642), Color(0xFF9F4576)],
  );

  // URL de tiles CartoDB Light (OSM, sin API key)
  static const String mapTileUrl =
      'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
  // Requerido por CartoDB en Android — sin esto retorna 403
  static const String mapTileUserAgent = 'com.example.buses_sig';

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          labelStyle: const TextStyle(color: textSecondary),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          color: cardBg,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: accent.withOpacity(0.3),
          labelStyle: const TextStyle(
              color: primary, fontWeight: FontWeight.bold, fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
      );
}
