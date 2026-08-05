// ============================================================
// core/theme/app_colors.dart
// ============================================================

import 'package:flutter/material.dart';

/// TirthTrack colour palette — White & Saffron design system.
class AppColors {
  AppColors._();

  // ── Brand (Saffron) ──────────────────────────────────────
  static const Color primary          = Color(0xFFF57C00);  // Saffron
  static const Color primaryLight     = Color(0xFFFF9800);  // Soft saffron
  static const Color primaryDark      = Color(0xFFE65100);  // Dark saffron
  static const Color primaryContainer = Color(0xFFFFF3E0);  // Light saffron container

  // ── Accent ───────────────────────────────────────────────
  static const Color accent           = Color(0xFFFF9800);  // Bright saffron accent
  static const Color accentDark       = Color(0xFFE65100);

  // ── Backgrounds (White & #FAFAFA) ─────────────────────────
  static const Color background       = Color(0xFFFFFFFF);  // Pure White
  static const Color surface          = Color(0xFFFFFFFF);  // Pure White
  static const Color surfaceVariant   = Color(0xFFFAFAFA);  // Secondary Background
  static const Color surfaceHigh      = Color(0xFFF5F5F5);  // Subtle neutral tint

  // ── Text & Icons ─────────────────────────────────────────
  static const Color onBackground     = Color(0xFF1A1A1A);  // Primary text #1A1A1A
  static const Color onSurface        = Color(0xFF1A1A1A);  // Primary text #1A1A1A
  static const Color onSurfaceMuted   = Color(0xFF757575);  // Secondary text #757575
  static const Color onSurfaceDisabled = Color(0xFF9E9E9E); // Disabled text
  static const Color iconDark         = Color(0xFF424242);  // Dark Gray Icons #424242

  // ── Semantic ─────────────────────────────────────────────
  static const Color success          = Color(0xFF2E7D32);  // Green
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color warning          = Color(0xFFF57C00);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color error            = Color(0xFFD32F2F);  // Red
  static const Color errorContainer   = Color(0xFFFFEBEE);
  static const Color info             = Color(0xFF0288D1);
  static const Color infoContainer    = Color(0xE1E1F5FE);

  // ── Dividers & Borders ───────────────────────────────────
  static const Color divider          = Color(0xFFEEEEEE);
  static const Color border           = Color(0xFFE5E5E5);  // Border #E5E5E5

  // ── Service Type Colors ──────────────────────────────────
  static const Color serviceHospital  = Color(0xFFD32F2F);
  static const Color serviceMedical   = Color(0xFFC2185B);
  static const Color serviceFood      = Color(0xFFF57C00);
  static const Color serviceWater     = Color(0xFF0288D1);
  static const Color serviceToilet    = Color(0xFF7B1FA2);
  static const Color serviceParking   = Color(0xFF455A64);
  static const Color serviceFuel      = Color(0xFF5D4037);
  static const Color servicePolice    = Color(0xFF303F9F);
  static const Color serviceHelpdesk  = Color(0xFF00796B);
  static const Color serviceAtm       = Color(0xFF388E3C);
  static const Color servicePharmacy  = Color(0xFF0097A7);
  static const Color serviceTemple    = Color(0xFFF57C00);
  static const Color serviceBusStop   = Color(0xFFFBC02D);
  static const Color serviceRailway   = Color(0xFF689F38);
  static const Color serviceOther     = Color(0xFF616161);

  // ── Alert Priority Colors ─────────────────────────────────
  static const Color priorityLow      = Color(0xFF2E7D32);
  static const Color priorityMedium   = Color(0xFFF57C00);
  static const Color priorityHigh     = Color(0xFFE65100);
  static const Color priorityCritical = Color(0xFFD32F2F);
}
