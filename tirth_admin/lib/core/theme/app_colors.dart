import 'package:flutter/material.dart';

/// TirthTrack colour palette — Saffron & White modern luxury design system.
class AppColors {
  AppColors._();

  // ── Brand Saffron ─────────────────────────────────────────
  static const Color primary          = Color(0xFFFF7722);  // Main Brand Saffron #FF7722
  static const Color primaryLight     = Color(0xFFFF9800);  // Warm Accent Saffron
  static const Color primaryDark      = Color(0xFFE65100);  // Deep Saffron Orange
  static const Color primaryContainer = Color(0xFFFFF3E0);  // Light Saffron Container

  // ── Accent ───────────────────────────────────────────────
  static const Color accent           = Color(0xFFFFB74D);
  static const Color accentDark       = Color(0xFFE65100);

  // ── Backgrounds & Surfaces ────────────────────────────────
  static const Color background       = Color(0xFFF9FAFB);  // Crisp off-white / light slate
  static const Color surface          = Color(0xFFFFFFFF);  // Pure White card surface
  static const Color surfaceVariant   = Color(0xFFF3F4F6);  // Secondary surface / input fill
  static const Color surfaceHigh      = Color(0xFFE5E7EB);  // Higher contrast surface
  static const Color shadowLight      = Color(0x0A000000);  // Soft ambient card shadow

  // ── Text & Content ────────────────────────────────────────
  static const Color onBackground     = Color(0xFF111827);  // High-contrast charcoal text
  static const Color onSurface        = Color(0xFF1F2937);  // Standard card body text
  static const Color onSurfaceMuted   = Color(0xFF6B7280);  // Secondary / hint text
  static const Color onSurfaceDisabled = Color(0xFF9CA3AF); // Disabled text
  static const Color iconDark         = Color(0xFF374151);  // Dark neutral icons

  // ── Semantic Feedback ─────────────────────────────────────
  static const Color success          = Color(0xFF10B981);  // Emerald Green
  static const Color successContainer = Color(0xFFECFDF5);
  static const Color warning          = Color(0xFFF59E0B);  // Amber
  static const Color warningContainer = Color(0xFFFFFBEB);
  static const Color error            = Color(0xFFEF4444);  // Crimson Red
  static const Color errorContainer   = Color(0xFFFEF2F2);
  static const Color info             = Color(0xFF3B82F6);  // Deep Sky Blue
  static const Color infoContainer    = Color(0xFFEFF6FF);

  // ── Dividers & Borders ───────────────────────────────────
  static const Color divider          = Color(0xFFF3F4F6);
  static const Color border           = Color(0xFFE5E7EB);
  static const Color borderFocused    = Color(0xFFFF7722);

  // ── Status Colors ─────────────────────────────────────────
  static const Color statusPending    = Color(0xFFF59E0B);
  static const Color statusVerified   = Color(0xFF10B981);
  static const Color statusRejected   = Color(0xFFEF4444);
  static const Color statusRevoked    = Color(0xFF6B7280);
  static const Color statusActive     = Color(0xFF10B981);
  static const Color statusUsed       = Color(0xFF3B82F6);
  static const Color statusExpired    = Color(0xFF9CA3AF);

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
