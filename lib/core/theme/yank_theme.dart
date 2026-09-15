import 'package:flutter/material.dart';

@immutable
class YankPalette extends ThemeExtension<YankPalette> {
  const YankPalette({
    required this.canvas,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.iris,
    required this.tint,
    required this.line,
    required this.search,
  });
  final Color canvas, surface, ink, muted, iris, tint, line, search;
  static const light = YankPalette(
    canvas: Color(0xFFF4F3F0),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF282631),
    muted: Color(0xFF726C7B),
    iris: Color(0xFF6250B5),
    tint: Color(0xFFEAE6F5),
    line: Color(0xFFE2DFE6),
    search: Color(0xFFEBE9E7),
  );
  static const dark = YankPalette(
    canvas: Color(0xFF1B1A20),
    surface: Color(0xFF24232B),
    ink: Color(0xFFF1EEF6),
    muted: Color(0xFFB0AAB9),
    iris: Color(0xFFB4A3F4),
    tint: Color(0xFF373046),
    line: Color(0xFF39353F),
    search: Color(0xFF2C2932),
  );
  @override
  YankPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? ink,
    Color? muted,
    Color? iris,
    Color? tint,
    Color? line,
    Color? search,
  }) => YankPalette(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    iris: iris ?? this.iris,
    tint: tint ?? this.tint,
    line: line ?? this.line,
    search: search ?? this.search,
  );
  @override
  YankPalette lerp(covariant YankPalette? other, double t) => other == null
      ? this
      : YankPalette(
          canvas: Color.lerp(canvas, other.canvas, t)!,
          surface: Color.lerp(surface, other.surface, t)!,
          ink: Color.lerp(ink, other.ink, t)!,
          muted: Color.lerp(muted, other.muted, t)!,
          iris: Color.lerp(iris, other.iris, t)!,
          tint: Color.lerp(tint, other.tint, t)!,
          line: Color.lerp(line, other.line, t)!,
          search: Color.lerp(search, other.search, t)!,
        );
}

extension YankThemeContext on BuildContext {
  YankPalette get colors => Theme.of(this).extension<YankPalette>()!;
}

abstract final class YankTheme {
  static ThemeData build(Brightness brightness) {
    final p = brightness == Brightness.dark
        ? YankPalette.dark
        : YankPalette.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.iris,
          brightness: brightness,
        ).copyWith(
          primary: p.iris,
          surface: p.surface,
          onSurface: p.ink,
          outline: p.line,
          onPrimary: brightness == Brightness.dark ? p.canvas : Colors.white,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.canvas,
      extensions: [p],
      splashFactory: NoSplash.splashFactory,
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
          color: p.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w600,
          letterSpacing: -.4,
          color: p.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          letterSpacing: -.15,
          color: p.ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: p.ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: p.ink),
        bodySmall: TextStyle(fontSize: 12, height: 1.4, color: p.muted),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: p.ink,
        ),
      ),
      iconTheme: IconThemeData(size: 19, color: p.ink),
      dividerColor: p.line,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.search,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: p.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.iris, width: 1.3),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.canvas,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: TextStyle(color: p.canvas, fontSize: 13),
        actionTextColor: brightness == Brightness.dark
            ? const Color(0xFF6250B5)
            : const Color(0xFFDCD2FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}
