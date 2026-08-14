import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tirth_admin/models/admin_profile_model.dart';
import 'package:tirth_admin/models/alert_model.dart';
import 'package:tirth_admin/models/police_login_code_model.dart';
import 'package:tirth_admin/models/sector_model.dart';
import 'package:tirth_admin/models/service_model.dart';

void main() {
  group('TirthTrack Admin App — Feature Unit Tests', () {
    test('Sector Model with Polygon Nodes Calculation', () {
      final rawSectorJson = {
        'id': 'sec-101',
        'sector_name': 'Ramkund Ghat North',
        'sector_code': 'SEC-RN-01',
        'description': 'Main bathing ghat sector',
        'color_hex': '#FF7722',
        'created_at': '2026-08-14T06:00:00Z',
        'updated_at': '2026-08-14T06:00:00Z',
        'sector_nodes': [
          {
            'id': 'node-2',
            'sector_id': 'sec-101',
            'node_order': 2,
            'latitude': 19.9985,
            'longitude': 73.7915,
            'created_at': '2026-08-14T06:00:00Z',
          },
          {
            'id': 'node-1',
            'sector_id': 'sec-101',
            'node_order': 1,
            'latitude': 19.9975,
            'longitude': 73.7898,
            'created_at': '2026-08-14T06:00:00Z',
          },
          {
            'id': 'node-3',
            'sector_id': 'sec-101',
            'node_order': 3,
            'latitude': 19.9965,
            'longitude': 73.7905,
            'created_at': '2026-08-14T06:00:00Z',
          },
        ],
      };

      final sector = SectorModel.fromJson(rawSectorJson);
      expect(sector.sectorName, 'Ramkund Ghat North');
      expect(sector.nodes.length, 3);

      // Verify node ordering is correctly sorted by node_order (1, 2, 3)
      final pts = sector.polygonPoints;
      expect(pts.length, 3);
      expect(pts[0], const LatLng(19.9975, 73.7898));
      expect(pts[1], const LatLng(19.9985, 73.7915));
      expect(pts[2], const LatLng(19.9965, 73.7905));

      // Verify center point
      final center = sector.centerPoint;
      expect(center, isNotNull);
      expect(center!.latitude, closeTo(19.9975, 0.005));
    });

    test('6-Digit Police Login Code Structure and Expiration', () {
      final validFuture = DateTime.now().add(const Duration(hours: 24));
      final pastDate = DateTime.now().subtract(const Duration(minutes: 5));

      final activeCode = PoliceLoginCodeModel(
        id: 'code-1',
        policeId: 'police-10',
        loginCode: '648291',
        expiresAt: validFuture,
        status: LoginCodeStatusEnum.active,
        createdAt: DateTime.now(),
        officerName: 'Inspector Patil',
        badgeNumber: 'MH-NSK-4421',
        policeStation: 'Panchavati',
      );

      expect(activeCode.loginCode.length, 6);
      expect(RegExp(r'^\d{6}$').hasMatch(activeCode.loginCode), true);
      expect(activeCode.isEffectiveActive, true);
      expect(activeCode.effectiveStatus, LoginCodeStatusEnum.active);

      final expiredCode = PoliceLoginCodeModel(
        id: 'code-2',
        policeId: 'police-10',
        loginCode: '918234',
        expiresAt: pastDate,
        status: LoginCodeStatusEnum.active,
        createdAt: pastDate.subtract(const Duration(hours: 1)),
      );

      expect(expiredCode.isExpiredByDate, true);
      expect(expiredCode.isEffectiveActive, false);
      expect(expiredCode.effectiveStatus, LoginCodeStatusEnum.expired);
    });

    test('ServiceModel Serialization with 24 Hours & Location', () {
      final service = ServiceModel(
        id: 'srv-1',
        serviceName: 'Ramkund Emergency Medical Camp',
        serviceType: ServiceTypeEnum.hospital,
        description: '24/7 First Aid & Ambulance station',
        latitude: 19.997812,
        longitude: 73.789123,
        contactPerson: 'Dr. Suresh Sharma',
        contactNumber: '+91 98234 56789',
        operatingHours: '24 Hours',
        is24Hours: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = service.toUpsertJson();
      expect(json['service_name'], 'Ramkund Emergency Medical Camp');
      expect(json['service_type'], 'hospital');
      expect(json['is_24_hours'], true);
      expect(json['latitude'], 19.997812);
      expect(json['longitude'], 73.789123);
    });

    test('AlertModel Priority and Expiry Check', () {
      final futureExpiry = DateTime.now().add(const Duration(hours: 6));
      final alert = AlertModel(
        id: 'alt-1',
        title: 'Emergency: Ghat 2 Restricted Access',
        message: 'High flow advisory in effect. Please use Ghat 3.',
        alertType: AlertTypeEnum.emergency,
        priority: AlertPriorityEnum.critical,
        expiresAt: futureExpiry,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(alert.priority, AlertPriorityEnum.critical);
      expect(alert.alertType, AlertTypeEnum.emergency);
      expect(alert.isExpired, false);
      expect(alert.isEffectiveActive, true);
    });

    test('Admin Profile Authorization and Role Check', () {
      final admin = AdminProfileModel.fromSupabase(
        profileJson: {
          'id': 'user-uuid-1',
          'full_name': 'District Magistrate (Admin)',
          'email': 'admin@tirthtrack.gov.in',
          'role': 'admin',
          'is_active': true,
          'created_at': '2026-08-14T00:00:00Z',
          'updated_at': '2026-08-14T00:00:00Z',
        },
        adminDetailsJson: {
          'id': 'admin-detail-uuid-1',
          'profile_id': 'user-uuid-1',
          'employee_code': 'ADM-DM-01',
          'designation': 'District Magistrate',
          'permissions': {'all': true},
          'created_at': '2026-08-14T00:00:00Z',
          'updated_at': '2026-08-14T00:00:00Z',
        },
      );

      expect(admin.adminId, 'admin-detail-uuid-1');
      expect(admin.role, UserRoleEnum.admin);
      expect(admin.employeeCode, 'ADM-DM-01');
      expect(admin.isActive, true);
    });
  });
}
