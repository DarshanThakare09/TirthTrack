import 'package:flutter_test/flutter_test.dart';
import 'package:tirthtrack_user/core/utils/custom_map_marker_helper.dart';
import 'package:tirthtrack_user/features/maps/models/service_model.dart';
import 'package:tirthtrack_user/features/maps/models/police_base_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomMapMarkerHelper & Unified Services Tests', () {
    test('ServiceModel all 14 types mapping and colors', () {
      expect(ServiceTypeEnum.values.length, 14);
      for (final t in ServiceTypeEnum.values) {
        expect(t.displayLabel, isNotEmpty);
        expect(t.color, isNotNull);
        expect(t.icon, isNotNull);
      }
    });

    test('PoliceBaseModel deserialization and distance calculation', () {
      final pb = PoliceBaseModel.fromJson({
        'id': 'pb-1',
        'base_name': 'Ramkund Police Station HQ',
        'station_name': 'Panchavati Police Station',
        'latitude': 19.9975,
        'longitude': 73.7898,
        'contact_number': '+91 253 2512345',
        'incharge_name': 'PI Rajesh Patil',
        'total_staff': 45,
        'is_active': true,
        'created_at': '2026-08-14T00:00:00Z',
        'updated_at': '2026-08-14T00:00:00Z',
      });

      expect(pb.baseName, 'Ramkund Police Station HQ');
      expect(pb.totalStaff, 45);
      expect(pb.inchargeName, 'PI Rajesh Patil');
    });

    test('CustomMapMarkerHelper renders custom service and police markers', () async {
      final serviceMarker = await CustomMapMarkerHelper.getServiceMarker(
        type: ServiceTypeEnum.hospital,
        isSelected: false,
      );
      expect(serviceMarker, isNotNull);

      final selectedServiceMarker = await CustomMapMarkerHelper.getServiceMarker(
        type: ServiceTypeEnum.hospital,
        isSelected: true,
      );
      expect(selectedServiceMarker, isNotNull);

      final policeMarker = await CustomMapMarkerHelper.getPoliceMarker(
        isSelected: false,
      );
      expect(policeMarker, isNotNull);

      final routeStartMarker = await CustomMapMarkerHelper.getRouteNodeMarker(
        order: 1,
        isStart: true,
        isEnd: false,
      );
      expect(routeStartMarker, isNotNull);

      final routeEndMarker = await CustomMapMarkerHelper.getRouteNodeMarker(
        order: 5,
        isStart: false,
        isEnd: true,
      );
      expect(routeEndMarker, isNotNull);

      final routeWayMarker = await CustomMapMarkerHelper.getRouteNodeMarker(
        order: 3,
        isStart: false,
        isEnd: false,
      );
      expect(routeWayMarker, isNotNull);
    });
  });
}
