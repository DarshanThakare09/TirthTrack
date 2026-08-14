import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';
import '../../models/service_model.dart';

class CustomMapMarkerHelper {
  CustomMapMarkerHelper._();

  static final Map<String, BitmapDescriptor> _cache = {};

  /// Custom sleek circular badge marker for public services
  static Future<BitmapDescriptor> getServiceMarker({
    required ServiceTypeEnum type,
    bool isSelected = false,
  }) async {
    final key = 'service_${type.name}_${isSelected ? "sel" : "nor"}_v2';
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final bytes = await _renderIconBadgeBytes(
      icon: type.icon,
      color: type.color,
      isSelected: isSelected,
    );

    final descriptor = BitmapDescriptor.bytes(bytes);
    _cache[key] = descriptor;
    return descriptor;
  }

  /// Custom sleek police shield marker
  static Future<BitmapDescriptor> getPoliceMarker({
    bool isSelected = false,
  }) async {
    final key = 'police_base_${isSelected ? "sel" : "nor"}_v2';
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final bytes = await _renderIconBadgeBytes(
      icon: Icons.local_police_rounded,
      color: const Color(0xFF1E40AF), // Police Deep Blue
      isSelected: isSelected,
    );

    final descriptor = BitmapDescriptor.bytes(bytes);
    _cache[key] = descriptor;
    return descriptor;
  }

  /// Custom numbered node marker for sector polygon drawing
  static Future<BitmapDescriptor> getNodeMarker({
    required int order,
    required bool isFirst,
    required bool isLast,
    Color? customColor,
  }) async {
    final key =
        'node_${order}_${isFirst ? "1" : (isLast ? "L" : "M")}_${customColor?.toARGB32() ?? 0}';
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final Color badgeColor = customColor ??
        (isFirst
            ? AppColors.primary
            : (isLast ? AppColors.primaryDark : AppColors.onBackground));

    final bytes = await _renderNumberedNodeBytes(
      order: order,
      badgeColor: badgeColor,
    );

    final descriptor = BitmapDescriptor.bytes(bytes);
    _cache[key] = descriptor;
    return descriptor;
  }

  /// Helper to render an icon inside a compact, modern circular badge
  static Future<Uint8List> _renderIconBadgeBytes({
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final size = isSelected ? 66.0 : 52.0;
    final center = Offset(size / 2, size / 2);
    final outerRadius = (size / 2) - 4.0;

    // 1. Ambient drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(0, 2), outerRadius, shadowPaint);

    // 2. Outer border ring
    final ringPaint = Paint()
      ..color = isSelected ? AppColors.primary : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, ringPaint);

    if (isSelected) {
      final highlightPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, outerRadius - 1.5, highlightPaint);
    }

    // 3. Inner colored circle
    final innerRadius = outerRadius - (isSelected ? 3.5 : 2.5);
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, fillPaint);

    // 4. Vector Icon in center
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: isSelected ? 26.0 : 21.0,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Helper to render compact numbered node markers
  static Future<Uint8List> _renderNumberedNodeBytes({
    required int order,
    required Color badgeColor,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    const size = 52.0;
    const center = Offset(size / 2, size / 2);
    const outerRadius = (size / 2) - 4.0;

    // 1. Ambient drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(0, 2), outerRadius, shadowPaint);

    // 2. Outer border ring
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, ringPaint);

    // 3. Inner colored circle
    const innerRadius = outerRadius - 2.5;
    final fillPaint = Paint()
      ..color = badgeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, fillPaint);

    // 4. Number
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      text: '$order',
      style: const TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        fontFamily: 'Roboto',
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
