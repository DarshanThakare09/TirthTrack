import 'package:flutter_test/flutter_test.dart';
import 'package:tirth_admin/models/admin_profile_model.dart';
import 'package:tirth_admin/models/alert_model.dart';
import 'package:tirth_admin/models/police_base_model.dart';
import 'package:tirth_admin/models/police_login_code_model.dart';
import 'package:tirth_admin/models/police_officer_model.dart';
import 'package:tirth_admin/models/route_model.dart';
import 'package:tirth_admin/models/sector_model.dart';
import 'package:tirth_admin/models/service_model.dart';

void main() {
  group('TirthTrack Admin Models Sanity Tests', () {
    test('AdminProfileModel deserialization', () {
      final model = AdminProfileModel.fromSupabase(
        profileJson: {
          'id': '00000000-0000-0000-0000-000000000001',
          'full_name': 'Chief Admin',
          'email': 'admin@tirthtrack.gov.in',
          'mobile': '9876543210',
          'is_active': true,
          'created_at': '2026-08-12T10:00:00Z',
          'updated_at': '2026-08-12T10:00:00Z',
        },
        adminDetailsJson: {
          'id': '11111111-1111-1111-1111-111111111111',
          'profile_id': '00000000-0000-0000-0000-000000000001',
          'employee_code': 'ADM-001',
          'designation': 'Superintendent of Police (Admin)',
          'permissions': {'all': true},
          'created_at': '2026-08-12T10:00:00Z',
          'updated_at': '2026-08-12T10:00:00Z',
        },
      );

      expect(model.adminId, '11111111-1111-1111-1111-111111111111');
      expect(model.profileId, '00000000-0000-0000-0000-000000000001');
      expect(model.fullName, 'Chief Admin');
      expect(model.role, UserRoleEnum.admin);
      expect(model.isActive, true);
    });

    test('RouteModel and RouteNodeModel deserialization', () {
      final route = RouteModel.fromJson({
        'id': 'route-1',
        'route_name': 'Ram Kund to Tapovan Parikrama',
        'route_code': 'RT-01',
        'total_distance_km': 4.5,
        'estimated_time_minutes': 60,
        'is_active': true,
        'created_at': '2026-08-12T10:00:00Z',
        'updated_at': '2026-08-12T10:00:00Z',
      });

      expect(route.routeName, 'Ram Kund to Tapovan Parikrama');
      expect(route.formattedDistance, '4.5 km');
      expect(route.formattedTime, '1h');

      final node = RouteNodeModel.fromJson({
        'id': 'node-1',
        'route_id': 'route-1',
        'node_order': 1,
        'node_name': 'Ram Kund Ghat Entry',
        'latitude': 19.9975,
        'longitude': 73.7898,
        'created_at': '2026-08-12T10:00:00Z',
      });

      expect(node.nodeOrder, 1);
      expect(node.latitude, 19.9975);
    });

    test('ServiceModel all 14 types enum mapping', () {
      expect(ServiceTypeEnum.values.length, 14);
      for (final type in ServiceTypeEnum.values) {
        expect(type.dbValue, isNotEmpty);
        expect(type.displayLabel, isNotEmpty);
      }
    });

    test('PoliceOfficerModel verification logic', () {
      final officer = PoliceOfficerModel.fromJson({
        'id': 'police-1',
        'profile_id': 'profile-1',
        'badge_number': 'MH-NSK-1042',
        'police_station': 'Panchavati Police Station',
        'district': 'Nashik',
        'state': 'Maharashtra',
        'verification_status': 'verified',
        'created_at': '2026-08-12T10:00:00Z',
        'updated_at': '2026-08-12T10:00:00Z',
        'profiles': {
          'full_name': 'Inspector Rajesh Patil',
          'mobile': '9822012345',
          'email': 'rajesh.patil@mahapolice.gov.in',
        },
      });

      expect(officer.badgeNumber, 'MH-NSK-1042');
      expect(officer.officerDisplayName, 'Inspector Rajesh Patil');
      expect(officer.isVerified, true);
      expect(officer.isPending, false);
    });

    test('AlertModel priority and type mapping', () {
      final alert = AlertModel.fromJson({
        'id': 'alert-1',
        'title': 'High Flow Warning Godavari',
        'message': 'Pilgrims are advised to exercise caution near Ram Kund.',
        'alert_type': 'weather',
        'priority': 'critical',
        'is_active': true,
        'created_at': '2026-08-12T10:00:00Z',
        'updated_at': '2026-08-12T10:00:00Z',
      });

      expect(alert.alertType, AlertTypeEnum.weather);
      expect(alert.priority, AlertPriorityEnum.critical);
      expect(alert.isActive, true);
    });

    test('SectorModel color resolution', () {
      final sector = SectorModel.fromJson({
        'id': 'sec-1',
        'sector_name': 'Sector 1 - Ram Kund',
        'sector_code': 'SEC-01',
        'color_hex': '#FF7722',
        'created_at': '2026-08-12T10:00:00Z',
        'updated_at': '2026-08-12T10:00:00Z',
      });

      expect(sector.sectorName, 'Sector 1 - Ram Kund');
      expect(sector.colorHex, '#FF7722');
    });

    test('PoliceBaseModel staff mapping', () {
      final base = PoliceBaseModel.fromJson({
        'id': 'base-1',
        'base_name': 'Ram Kund Security HQ',
        'latitude': 19.9975,
        'longitude': 73.7898,
        'total_staff': 32,
        'is_active': true,
        'created_at': '2026-08-12T10:00:00Z',
        'updated_at': '2026-08-12T10:00:00Z',
      });

      expect(base.totalStaff, 32);
      expect(base.isActive, true);
    });

    test('PoliceLoginCodeModel status check', () {
      final code = PoliceLoginCodeModel.fromJson({
        'id': 'code-1',
        'police_id': 'police-1',
        'login_code': '849201',
        'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'status': 'active',
        'created_at': '2026-08-12T10:00:00Z',
      });

      expect(code.loginCode, '849201');
      expect(code.isEffectiveActive, true);
    });
  });
}
