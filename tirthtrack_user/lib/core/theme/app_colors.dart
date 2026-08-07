// ============================================================
// core/theme/app_colors.dart
// ============================================================

import 'package:flutter/material.dart';

/// TirthTrack colour palette — White & Saffron design system.
class AppColors {
  AppColors._();

  // ── Brand (Splash Warm Bhagwa Color 0xFFFF7722) ───────────
  static const Color primary          = Color(0xFFFF7722);  // Main Brand Color #FF7722
  static const Color primaryLight     = Color(0xFFFF9800);  // Warm Accent Saffron
  static const Color primaryDark      = Color(0xFFE65100);  // Rich Dark Orange
  static const Color primaryContainer = Color(0xFFFFF3E0);  // Soft Light Container

  // ── Accent ───────────────────────────────────────────────
  static const Color accent           = Color(0xFFFFB74D);  // Soft Warm Accent
  static const Color accentDark       = Color(0xFFE65100);

  // ── Backgrounds (Pure White & Bright Surfaces) ────────────
  static const Color background       = Color(0xFFFFFFFF);  // Pure White
  static const Color surface          = Color(0xFFFFFFFF);  // Pure White
  static const Color surfaceVariant   = Color(0xFFFAFAFA);  // Secondary Surface Background
  static const Color surfaceHigh      = Color(0xFFF5F5F5);  // Subtle neutral tint

  // ── Text & Icons ─────────────────────────────────────────
  static const Color onBackground     = Color(0xFF111827);  // High Contrast Text #111827
  static const Color onSurface        = Color(0xFF1F2937);  // Primary text #1F2937
  static const Color onSurfaceMuted   = Color(0xFF6B7280);  // Secondary text #6B7280
  static const Color onSurfaceDisabled = Color(0xFF9CA3AF); // Disabled text
  static const Color iconDark         = Color(0xFF374151);  // Dark Gray Icons #374151

  // ── Semantic ─────────────────────────────────────────────
  static const Color success          = Color(0xFF10B981);  // Emerald Green
  static const Color successContainer = Color(0xFFECFDF5);
  static const Color warning          = Color(0xFFF59E0B);  // Amber Warning
  static const Color warningContainer = Color(0xFFFFFBEB);
  static const Color error            = Color(0xFFEF4444);  // Rose Red Error
  static const Color errorContainer   = Color(0xFFFEF2F2);
  static const Color info             = Color(0xFF3B82F6);  // Blue Info
  static const Color infoContainer    = Color(0xFFEFF6FF);

  // ── Dividers & Borders ───────────────────────────────────
  static const Color divider          = Color(0xFFF3F4F6);  // Soft Divider #F3F4F6
  static const Color border           = Color(0xFFE5E7EB);  // Subtle Border #E5E7EB

  // ── Service Type Colors ──────────────────────────────────
  static const Color serviceHospital  = Color(0xFFEF4444);
  static const Color serviceMedical   = Color(0xFFEC4899);
  static const Color serviceFood      = Color(0xFFF97316);
  static const Color serviceWater     = Color(0xFF06B6D4);
  static const Color serviceToilet    = Color(0xFF8B5CF6);
  static const Color serviceParking   = Color(0xFF64748B);
  static const Color serviceFuel      = Color(0xFF78350F);
  static const Color servicePolice    = Color(0xFF3B82F6);
  static const Color serviceHelpdesk  = Color(0xFF14B8A6);
  static const Color serviceAtm       = Color(0xFF10B981);
  static const Color servicePharmacy  = Color(0xFF0EA5E9);
  static const Color serviceTemple    = Color(0xFFE65100);
  static const Color serviceBusStop   = Color(0xFFEAB308);
  static const Color serviceRailway   = Color(0xFF84CC16);
  static const Color serviceOther     = Color(0xFF6B7280);

  // ── Alert Priority Colors ─────────────────────────────────
  static const Color priorityLow      = Color(0xFF10B981);
  static const Color priorityMedium   = Color(0xFFF59E0B);
  static const Color priorityHigh     = Color(0xFFF97316);
  static const Color priorityCritical = Color(0xFFEF4444);
}
