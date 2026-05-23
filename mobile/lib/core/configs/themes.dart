import 'package:flutter/material.dart';

// =============================================================================
// Warm Studygram design tokens
//
// Source of truth: ../../../../DESIGN.md (and ADR-0011 for the curated subject
// palette). Touch only with explicit user approval — DESIGN.md anti-slop hard
// rules apply (no #FFFFFF, no #000000, no Inter/Roboto/Space Grotesk).
// =============================================================================

// --- Chrome (light mode) -----------------------------------------------------

const Color kPulp = Color(0xFFF4ECD8); // page surface — NEVER #FFFFFF
const Color kCocoaInk = Color(0xFF2B221C); // ink — NEVER #000000

// Tile composition: page (Pulp) → card (Tile) → chip-inside-card (Inset).
// The home tile in DESIGN.md stacks three cream tones so cards visually
// separate from the page without losing the paper-warm feel.
const Color kPulpTile = Color(0xFFEAE0C5); // card / tile surface
const Color kPulpInset = Color(0xFFDDD2B5); // chip / inset inside a tile

// --- Brand subject palette (ADR-0011) ---------------------------------------
// Subjects pick exclusively from these six. Free-form hex is rejected.

const Color kRisoFig = Color(0xFFA23B5C);
const Color kMatchaStain = Color(0xFF7A8C3E);
const Color kHoneyed = Color(0xFFE8A33D);
const Color kLibraryBlue = Color(0xFF3E5C7A);
const Color kPlumWine = Color(0xFF6E4F7A);
const Color kClay = Color(0xFFC56D5C);

// Error deepened for contrast on Pulp.
const Color kClayDeep = Color(0xFFA85643);

// --- Dark mode — "Reading Lamp" ---------------------------------------------

const Color kPulpNight = Color(0xFF1E1814);
const Color kPulpTileNight = Color(0xFF2A2320);
const Color kPulpInsetNight = Color(0xFF3A3128);
const Color kInkNight = kPulp; // ink inverts to Pulp on dark surface

const Color kRisoFigNight = Color(0xFFC95778);
const Color kMatchaStainNight = Color(0xFF9DAE5C);
const Color kHoneyedNight = Color(0xFFF0B658);
const Color kLibraryBlueNight = Color(0xFF6889A8);
const Color kPlumWineNight = Color(0xFF8E6D9A);
const Color kClayNight = Color(0xFFD88472);

// --- Opacity scale on ink (never invent grays) ------------------------------

class InkOpacity {
  static const double full = 1.0; // primary text
  static const double soft = 0.70; // secondary text
  static const double faint = 0.45; // tertiary text, captions
  static const double hint = 0.25; // dividers, placeholders, outlines
}

// --- Spacing — base 4px -----------------------------------------------------

class Spacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

// --- Border radii -----------------------------------------------------------

class Radii {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double full = 9999;
}

// --- Motion -----------------------------------------------------------------

class Motion {
  static const Duration micro = Duration(milliseconds: 80);
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 500);
  // Single use: PR celebration paper-fold. No confetti, no number-roll-up.
  static const Duration paperFold = Duration(milliseconds: 700);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve move = Curves.easeInOutCubic;
}

// --- Curated subject palette enum (ADR-0011) --------------------------------
// The single source of truth for "what colors can a subject have?".

enum SubjectColor {
  risoFig('Riso Fig', kRisoFig, kRisoFigNight, '#A23B5C'),
  matchaStain('Matcha Stain', kMatchaStain, kMatchaStainNight, '#7A8C3E'),
  honeyed('Honeyed', kHoneyed, kHoneyedNight, '#E8A33D'),
  libraryBlue('Library Blue', kLibraryBlue, kLibraryBlueNight, '#3E5C7A'),
  plumWine('Plum Wine', kPlumWine, kPlumWineNight, '#6E4F7A'),
  clay('Clay', kClay, kClayNight, '#C56D5C');

  const SubjectColor(this.label, this.light, this.dark, this.hex);

  final String label;
  final Color light;
  final Color dark;
  final String hex;

  Color resolve(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  // Nearest-snap on server-side hex strings that don't match exactly.
  // Pre-launch, the backend still accepts free-form hex per the current Zod
  // schema — this lets the client tolerate legacy values without crashing.
  static SubjectColor fromHex(String? hex) {
    if (hex == null || hex.isEmpty) return SubjectColor.risoFig;
    final normalized = hex.toUpperCase();
    for (final c in SubjectColor.values) {
      if (c.hex.toUpperCase() == normalized) return c;
    }
    return _nearestByRgb(hex);
  }

  static SubjectColor _nearestByRgb(String hex) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    if (value == null) return SubjectColor.risoFig;
    final r = (value >> 16) & 0xFF;
    final g = (value >> 8) & 0xFF;
    final b = value & 0xFF;
    SubjectColor best = SubjectColor.risoFig;
    double bestDist = double.infinity;
    for (final c in SubjectColor.values) {
      final cr = (c.light.r * 255).round();
      final cg = (c.light.g * 255).round();
      final cb = (c.light.b * 255).round();
      final d = ((r - cr) * (r - cr) +
              (g - cg) * (g - cg) +
              (b - cb) * (b - cb))
          .toDouble();
      if (d < bestDist) {
        bestDist = d;
        best = c;
      }
    }
    return best;
  }
}

// =============================================================================
// Typography
//
// Fraunces (italic) for display, Geist for body/UI, Geist Mono for fine print
// and dates, Caveat for "personal best" margin notes (single role only — never
// UI chrome). Modular scale from DESIGN.md.
// =============================================================================

const String kFontFraunces = 'Fraunces';
const String kFontGeist = 'Geist';
const String kFontGeistMono = 'GeistMono';
const String kFontCaveat = 'Caveat';

TextTheme _buildTextTheme(Color ink) {
  return TextTheme(
    displayLarge: TextStyle(
      fontFamily: kFontFraunces,
      fontStyle: FontStyle.italic,
      fontSize: 56,
      height: 1.05,
      letterSpacing: -0.5,
      color: ink,
    ),
    displayMedium: TextStyle(
      fontFamily: kFontFraunces,
      fontStyle: FontStyle.italic,
      fontSize: 36,
      height: 1.1,
      letterSpacing: -0.25,
      color: ink,
    ),
    displaySmall: TextStyle(
      fontFamily: kFontFraunces,
      fontStyle: FontStyle.italic,
      fontSize: 28,
      height: 1.15,
      color: ink,
    ),
    headlineLarge: TextStyle(
      fontFamily: kFontFraunces,
      fontStyle: FontStyle.italic,
      fontSize: 22,
      height: 1.2,
      color: ink,
    ),
    headlineMedium: TextStyle(
      fontFamily: kFontFraunces,
      fontStyle: FontStyle.italic,
      fontSize: 22,
      color: ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: kFontGeist,
      fontWeight: FontWeight.w600,
      fontSize: 18,
      height: 1.3,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontFamily: kFontGeist,
      fontWeight: FontWeight.w600,
      fontSize: 18,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontFamily: kFontGeist,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: ink,
    ),
    titleSmall: TextStyle(
      fontFamily: kFontGeist,
      fontWeight: FontWeight.w500,
      fontSize: 14,
      color: ink,
    ),
    bodyLarge: TextStyle(
      fontFamily: kFontGeist,
      fontSize: 18,
      height: 1.4,
      color: ink,
    ),
    bodyMedium: TextStyle(
      fontFamily: kFontGeist,
      fontSize: 16,
      height: 1.4,
      color: ink,
    ),
    bodySmall: TextStyle(
      fontFamily: kFontGeist,
      fontSize: 14,
      height: 1.4,
      color: ink.withValues(alpha: InkOpacity.soft),
    ),
    labelLarge: TextStyle(
      fontFamily: kFontGeist,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: ink,
    ),
    labelMedium: TextStyle(
      fontFamily: kFontGeist,
      fontWeight: FontWeight.w500,
      fontSize: 14,
      color: ink,
    ),
    labelSmall: TextStyle(
      fontFamily: kFontGeistMono,
      fontSize: 12,
      letterSpacing: 0.2,
      color: ink.withValues(alpha: InkOpacity.soft),
    ),
  );
}

// Specialty styles — outside TextTheme because they're situational.

/// Big stat / timer display (Geist tabular-nums). Default size targets the
/// share-card hero number from DESIGN.md.
TextStyle timerDisplay({double size = 96, Color color = kRisoFig}) => TextStyle(
      fontFamily: kFontGeist,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w600,
      fontSize: size,
      height: 1.0,
      letterSpacing: -1,
      color: color,
    );

/// "personal best" handwritten marginalia. Caveat only — never UI chrome.
TextStyle marginNote({double size = 26, Color color = kRisoFig}) => TextStyle(
      fontFamily: kFontCaveat,
      fontWeight: FontWeight.w600,
      fontSize: size,
      color: color,
    );

// =============================================================================
// ThemeData
// =============================================================================

ThemeData get warmStudygramLight => _buildTheme(
      brightness: Brightness.light,
      surface: kPulp,
      ink: kCocoaInk,
      primary: kRisoFig,
      tile: kPulpTile,
      inset: kPulpInset,
    );

ThemeData get warmStudygramDark => _buildTheme(
      brightness: Brightness.dark,
      surface: kPulpNight,
      ink: kInkNight,
      primary: kRisoFigNight,
      tile: kPulpTileNight,
      inset: kPulpInsetNight,
    );

/// Alias kept so existing `main.dart` (`theme: defaultTheme`) doesn't need a
/// rename. New code should reference `warmStudygramLight` / `warmStudygramDark`
/// directly.
final ThemeData defaultTheme = warmStudygramLight;

ThemeData _buildTheme({
  required Brightness brightness,
  required Color surface,
  required Color ink,
  required Color primary,
  required Color tile,
  required Color inset,
}) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: surface,
    secondary: isDark ? kHoneyedNight : kHoneyed,
    onSecondary: kCocoaInk,
    tertiary: isDark ? kLibraryBlueNight : kLibraryBlue,
    onTertiary: surface,
    error: isDark ? kClayNight : kClayDeep,
    onError: surface,
    surface: surface,
    onSurface: ink,
    surfaceContainer: tile,
    surfaceContainerHigh: inset,
    surfaceContainerHighest: inset,
    outline: ink.withValues(alpha: InkOpacity.hint),
    outlineVariant: ink.withValues(alpha: 0.12),
  );

  final textTheme = _buildTextTheme(ink);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: surface,
    canvasColor: surface,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: textTheme,
    fontFamily: kFontGeist,
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      surfaceTintColor: surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: kFontFraunces,
        fontStyle: FontStyle.italic,
        fontSize: 22,
        color: ink,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      // Default ElevatedButton is the Cocoa Ink pill from the home tile —
      // Pulp label on Cocoa Ink in light mode, inverted in dark. DefaultButton
      // mirrors this; raw ElevatedButton picks it up too so new code stays on
      // pattern by default.
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? kPulp : kCocoaInk,
        foregroundColor: isDark ? kCocoaInk : kPulp,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.full),
        ),
        textStyle: textTheme.labelLarge?.copyWith(
          color: isDark ? kCocoaInk : kPulp,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: ink.withValues(alpha: InkOpacity.hint)),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.full),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        textStyle: textTheme.labelLarge?.copyWith(color: primary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tile.withValues(alpha: isDark ? 0.5 : 0.4),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: ink.withValues(alpha: InkOpacity.hint)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: ink.withValues(alpha: InkOpacity.hint)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: ink.withValues(alpha: InkOpacity.soft),
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: ink.withValues(alpha: InkOpacity.faint),
      ),
      errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
    ),
    cardTheme: CardThemeData(
      color: tile,
      surfaceTintColor: tile,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: ink.withValues(alpha: 0.10),
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ink.withValues(alpha: 0.06),
      side: BorderSide.none,
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: primary.withValues(alpha: 0.15),
      surfaceTintColor: surface,
      height: 72,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelSmall?.copyWith(
          fontFamily: kFontGeist,
          fontSize: 12,
          color: ink,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: primary);
        }
        return IconThemeData(color: ink.withValues(alpha: InkOpacity.soft));
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: surface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}
