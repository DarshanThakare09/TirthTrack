import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';
import '../../features/maps/models/service_model.dart';

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

  /// Custom sleek route waypoint node marker
  static Future<BitmapDescriptor> getRouteNodeMarker({
    required int order,
    required bool isStart,
    required bool isEnd,
    bool isSelected = false,
  }) async {
    final key =
        'route_node_${order}_${isStart ? "start" : (isEnd ? "end" : "way")}_${isSelected ? "sel" : "nor"}_v2';
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final bytes = await _renderRouteNodeBytes(
      order: order,
      isStart: isStart,
      isEnd: isEnd,
      isSelected: isSelected,
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

    // Compact proportional dimensions for Google Maps
    final size = isSelected ? 66.0 : 52.0;
    final center = Offset(size / 2, size / 2);
    final outerRadius = (size / 2) - 4.0;

    // 1. Soft ambient shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(0, 2), outerRadius, shadowPaint);

    // 2. Crisp outer border ring (Saffron when selected, Pure White normally)
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

  /// Helper to render compact numbered route waypoints
  static Future<Uint8List> _renderRouteNodeBytes({
    required int order,
    required bool isStart,
    required bool isEnd,
    required bool isSelected,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final size = isSelected ? 66.0 : 52.0;
    final center = Offset(size / 2, size / 2);
    final outerRadius = (size / 2) - 4.0;

    final Color badgeColor = isStart
        ? AppColors.success
        : (isEnd ? AppColors.error : AppColors.primary);

    // 1. Soft ambient shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(0, 2), outerRadius, shadowPaint);

    // 2. Outer border ring
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, ringPaint);

    if (isSelected) {
      final borderStroke = Paint()
        ..color = AppColors.primaryDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, outerRadius, borderStroke);
    }

    // 3. Inner colored circle
    final innerRadius = outerRadius - (isSelected ? 3.5 : 2.5);
    final fillPaint = Paint()
      ..color = badgeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, fillPaint);

    // 4. Number / label
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      text: '$order',
      style: TextStyle(
        fontSize: isSelected ? 24.0 : 19.0,
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
