import 'package:flutter/material.dart';

class AppTheme {
  // ── Paleta exacta ─────────────────────────────────────────────────────────────
  static const Color catawba       = Color(0xFF7B354B);
  static const Color deepPuce      = Color(0xFFAE6172);
  static const Color parrotPink    = Color(0xFFCC93A3);
  static const Color paleChestnut  = Color(0xFFD6ACAD);
  static const Color lavenderBlush = Color(0xFFFCEAF0);
  static const Color antiFlash     = Color(0xFFF4F3F0);

  // ── Alias semánticos ──────────────────────────────────────────────────────────
  static const Color primary       = catawba;
  static const Color secondary     = deepPuce;
  static const Color accent        = parrotPink;
  static const Color soft          = paleChestnut;
  static const Color paleRose      = paleChestnut; // alias backward-compat
  static const Color background    = antiFlash;
  static const Color surface       = lavenderBlush;
  static const Color cardBg        = Color(0xFFFFFFFF);

  // ── Texto ─────────────────────────────────────────────────────────────────────
  static const Color textOnDark    = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF2D1B22);
  static const Color textSecondary = Color(0xFF8B5C6A);

  // ── Funcionales ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color danger  = Color(0xFFC62828);

  // ── Gradientes ────────────────────────────────────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [catawba, deepPuce],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3D1525), catawba, deepPuce],
    stops: [0.0, 0.45, 1.0],
  );

  // ── Mapa: CartoDB Voyager (calles con color, gratis) ─────────────────────────
  static const String mapTileUrl =
      'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  static const String mapTileUserAgent = 'com.example.buses_sig';

  // ── Botones reutilizables ─────────────────────────────────────────────────────
  static ButtonStyle get btnPrimary => ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: textOnDark,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 3,
    shadowColor: primary.withOpacity(0.4),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
  );

  static ButtonStyle get btnSecondary => ElevatedButton.styleFrom(
    backgroundColor: secondary,
    foregroundColor: textOnDark,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 2,
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
  );

  static ButtonStyle get btnOutline => OutlinedButton.styleFrom(
    foregroundColor: primary,
    side: const BorderSide(color: primary, width: 1.5),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
  );

  // ── ThemeData ─────────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: catawba,
      brightness: Brightness.light,
      primary: catawba,
      secondary: deepPuce,
    ),
    scaffoldBackgroundColor: background,

    appBarTheme: const AppBarTheme(
      backgroundColor: catawba,
      foregroundColor: textOnDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textOnDark,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: textOnDark),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textOnDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        elevation: 2,
        shadowColor: primary.withOpacity(0.35),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lavenderBlush,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: paleChestnut, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: danger, width: 1),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: paleChestnut),
      prefixIconColor: secondary,
    ),

    chipTheme: const ChipThemeData(
      backgroundColor: lavenderBlush,
      labelStyle: TextStyle(color: textPrimary, fontSize: 12),
      side: BorderSide(color: paleChestnut),
      shape: StadiumBorder(),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: secondary,
      thumbColor: primary,
      inactiveTrackColor: paleChestnut,
      overlayColor: primary.withOpacity(0.15),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected) ? primary : Colors.grey.shade400),
      trackColor: MaterialStateProperty.resolveWith((s) =>
          s.contains(MaterialState.selected) ? primary.withOpacity(0.35) : Colors.grey.withOpacity(0.2)),
    ),

    dividerTheme: const DividerThemeData(color: lavenderBlush, thickness: 1),

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
