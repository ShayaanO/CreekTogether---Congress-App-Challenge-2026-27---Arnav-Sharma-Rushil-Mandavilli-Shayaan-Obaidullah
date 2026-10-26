import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../settings/app_settings.dart';


class _Palette {
  const _Palette({
    required this.brightness,
    required this.background, // page background
    required this.surface, // cards
    required this.border, // outlines and dividers
    required this.accent, // links, buttons, selected tab
    required this.onAccent, // text/icons on top of the accent color
    required this.text, // main text
    required this.muted, // softer secondary text
    required this.navBar, // bottom toolbar background
    required this.selectedBg, // highlight behind the selected side bar item
  });

  final Brightness brightness;
  final Color background, surface, border, accent, onAccent, text, muted, navBar, selectedBg;
}

// Dark navy (the default look)
const _darkNormal = _Palette(
  brightness: Brightness.dark,
  background: Color(0xFF0B1226),
  surface: Color(0xFF141E38),
  border: Color(0xFF2B3757),
  accent: Color(0xFF7FA6FF),
  onAccent: Color(0xFF0B1226),
  text: Colors.white,
  muted: Color(0xFFB8C2DD),
  navBar: Color(0xFF0F1830),
  selectedBg: Color(0xFF1F2D52),
);

// Dark, high contrast: pure black, white outlines, bright yellow highlights
const _darkHigh = _Palette(
  brightness: Brightness.dark,
  background: Color(0xFF000000),
  surface: Color(0xFF0A0A0A),
  border: Color(0xFFFFFFFF),
  accent: Color(0xFFFFE600),
  onAccent: Color(0xFF000000),
  text: Colors.white,
  muted: Colors.white,
  navBar: Color(0xFF000000),
  selectedBg: Color(0xFF262626),
);

// Light
const _lightNormal = _Palette(
  brightness: Brightness.light,
  background: Color(0xFFF5F7FC),
  surface: Color(0xFFFFFFFF),
  border: Color(0xFFD3DAEA),
  accent: Color(0xFF2457D6),
  onAccent: Colors.white,
  text: Color(0xFF111827),
  muted: Color(0xFF4B5675),
  navBar: Color(0xFFFFFFFF),
  selectedBg: Color(0xFFE1E8FB),
);

// Light, high contrast: white, black outlines, strong blue highlights
const _lightHigh = _Palette(
  brightness: Brightness.light,
  background: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFFFF),
  border: Color(0xFF000000),
  accent: Color(0xFF0033CC),
  onAccent: Colors.white,
  text: Color(0xFF000000),
  muted: Color(0xFF000000),
  navBar: Color(0xFFFFFFFF),
  selectedBg: Color(0xFFDDE6FF),
);

/// Builds the app's look from the current settings.
ThemeData buildTheme(AppSettings settings) {
  final p = settings.lightMode
      ? (settings.highContrast ? _lightHigh : _lightNormal)
      : (settings.highContrast ? _darkHigh : _darkNormal);
  final fontName = settings.fontName;
  final borderWidth = settings.highContrast ? 2.0 : 1.0;

  final scheme = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: p.brightness,
  ).copyWith(
    surface: p.background,
    onSurface: p.text,
    onSurfaceVariant: p.muted,
    primary: p.accent,
    onPrimary: p.onAccent,
    primaryContainer: p.surface,
    onPrimaryContainer: p.text,
    secondaryContainer: p.selectedBg,
    onSecondaryContainer: p.text,
    outline: p.border,
    outlineVariant: p.border,
  );

  final textTheme = ThemeData(brightness: p.brightness, fontFamily: fontName)
      .textTheme
      .apply(bodyColor: p.text, displayColor: p.text);

  return ThemeData(
    useMaterial3: true,
    fontFamily: fontName,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: p.background,

    // Top bar: same color as the page, bold title on the left, thin line under it
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.text,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: p.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      shape: Border(bottom: BorderSide(color: p.border, width: borderWidth)),
      titleTextStyle: TextStyle(
        fontFamily: fontName,
        color: p.text,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Bottom toolbar: selected tab turns the accent color
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.navBar,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.accent.withValues(alpha: settings.highContrast ? 0.35 : 0.18),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? p.accent : p.muted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: fontName,
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? p.accent : p.muted,
        );
      }),
    ),

    // Cards: rounded, slightly lighter than the page, thin outline
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border, width: borderWidth),
      ),
    ),

    dividerTheme: DividerThemeData(color: p.border, space: 1, thickness: borderWidth),

    // Buttons (like the Call button)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
