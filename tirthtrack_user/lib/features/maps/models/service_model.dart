// ============================================================
// features/maps/models/service_model.dart
// ============================================================

import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum ServiceTypeEnum {
  hospital,
  medical,
  food,
  water,
  toilet,
  parking,
  fuel,
  police,
  helpdesk,
  atm,
  pharmacy,
  temple,
  busStop,
  railwayStation,
  other,
}

extension ServiceTypeEnumX on ServiceTypeEnum {
  String get dbValue {
    switch (this) {
      case ServiceTypeEnum.busStop:
        return 'bus_stop';
      case ServiceTypeEnum.railwayStation:
        return 'railway_station';
      default:
        return name;
    }
  }

  String get displayLabel {
    switch (this) {
      case ServiceTypeEnum.hospital:
        return 'Hospital';
      case ServiceTypeEnum.medical:
        return 'Medical';
      case ServiceTypeEnum.food:
        return 'Food';
      case ServiceTypeEnum.water:
        return 'Water';
      case ServiceTypeEnum.toilet:
        return 'Toilet';
      case ServiceTypeEnum.parking:
        return 'Parking';
      case ServiceTypeEnum.fuel:
        return 'Fuel';
      case ServiceTypeEnum.police:
        return 'Police';
      case ServiceTypeEnum.helpdesk:
        return 'Help Desk';
      case ServiceTypeEnum.atm:
        return 'ATM';
      case ServiceTypeEnum.pharmacy:
        return 'Pharmacy';
      case ServiceTypeEnum.temple:
        return 'Temple';
      case ServiceTypeEnum.busStop:
        return 'Bus Stop';
      case ServiceTypeEnum.railwayStation:
        return 'Railway Station';
      case ServiceTypeEnum.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceTypeEnum.hospital:
        return Icons.local_hospital_rounded;
      case ServiceTypeEnum.medical:
        return Icons.medical_services_rounded;
      case ServiceTypeEnum.food:
        return Icons.restaurant_rounded;
      case ServiceTypeEnum.water:
        return Icons.water_drop_rounded;
      case ServiceTypeEnum.toilet:
        return Icons.wc_rounded;
      case ServiceTypeEnum.parking:
        return Icons.local_parking_rounded;
      case ServiceTypeEnum.fuel:
        return Icons.local_gas_station_rounded;
      case ServiceTypeEnum.police:
        return Icons.local_police_rounded;
      case ServiceTypeEnum.helpdesk:
        return Icons.help_outline_rounded;
      case ServiceTypeEnum.atm:
        return Icons.local_atm_rounded;
      case ServiceTypeEnum.pharmacy:
        return Icons.local_pharmacy_rounded;
      case ServiceTypeEnum.temple:
        return Icons.temple_hindu_rounded;
      case ServiceTypeEnum.busStop:
        return Icons.directions_bus_rounded;
      case ServiceTypeEnum.railwayStation:
        return Icons.train_rounded;
      case ServiceTypeEnum.other:
        return Icons.place_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ServiceTypeEnum.hospital:
        return AppColors.serviceHospital;
      case ServiceTypeEnum.medical:
        return AppColors.serviceMedical;
      case ServiceTypeEnum.food:
        return AppColors.serviceFood;
      case ServiceTypeEnum.water:
        return AppColors.serviceWater;
      case ServiceTypeEnum.toilet:
        return AppColors.serviceToilet;
      case ServiceTypeEnum.parking:
        return AppColors.serviceParking;
      case ServiceTypeEnum.fuel:
        return AppColors.serviceFuel;
      case ServiceTypeEnum.police:
        return AppColors.servicePolice;
      case ServiceTypeEnum.helpdesk:
        return AppColors.serviceHelpdesk;
      case ServiceTypeEnum.atm:
        return AppColors.serviceAtm;
      case ServiceTypeEnum.pharmacy:
        return AppColors.servicePharmacy;
      case ServiceTypeEnum.temple:
        return AppColors.serviceTemple;
      case ServiceTypeEnum.busStop:
        return AppColors.serviceBusStop;
      case ServiceTypeEnum.railwayStation:
        return AppColors.serviceRailway;
      case ServiceTypeEnum.other:
        return AppColors.serviceOther;
    }
  }
}

ServiceTypeEnum serviceTypeFromDb(String? value) {
  if (value == null) return ServiceTypeEnum.other;
  switch (value) {
    case 'hospital':
      return ServiceTypeEnum.hospital;
    case 'medical':
      return ServiceTypeEnum.medical;
    case 'food':
      return ServiceTypeEnum.food;
    case 'water':
      return ServiceTypeEnum.water;
    case 'toilet':
      return ServiceTypeEnum.toilet;
    case 'parking':
      return ServiceTypeEnum.parking;
    case 'fuel':
      return ServiceTypeEnum.fuel;
    case 'police':
      return ServiceTypeEnum.police;
    case 'helpdesk':
      return ServiceTypeEnum.helpdesk;
    case 'atm':
      return ServiceTypeEnum.atm;
    case 'pharmacy':
      return ServiceTypeEnum.pharmacy;
    case 'temple':
      return ServiceTypeEnum.temple;
    case 'bus_stop':
      return ServiceTypeEnum.busStop;
    case 'railway_station':
      return ServiceTypeEnum.railwayStation;
    default:
      return ServiceTypeEnum.other;
  }
}

class ServiceModel extends Equatable {
  const ServiceModel({
    required this.id,
    required this.serviceName,
    required this.serviceType,
    this.description,
    required this.latitude,
    required this.longitude,
    this.contactPerson,
    this.contactNumber,
    this.operatingHours,
    this.is24Hours = false,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.distanceKm,
  });

  final String id;
  final String serviceName;
  final ServiceTypeEnum serviceType;
  final String? description;
  final double latitude;
  final double longitude;
  final String? contactPerson;
  final String? contactNumber;
  final String? operatingHours;
  final bool is24Hours;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Computed client-side distance (not in DB).
  final double? distanceKm;

  LatLng get latLng => LatLng(latitude, longitude);
  gmaps.LatLng get googleLatLng => gmaps.LatLng(latitude, longitude);

  factory ServiceModel.fromJson(Map<String, dynamic> json,
      {double? distanceKm}) {
    return ServiceModel(
      id: json['id'] as String,
      serviceName: json['service_name'] as String,
      serviceType: serviceTypeFromDb(json['service_type'] as String?),
      description: json['description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      contactPerson: json['contact_person'] as String?,
      contactNumber: json['contact_number'] as String?,
      operatingHours: json['operating_hours'] as String?,
      is24Hours: (json['is_24_hours'] as bool?) ?? false,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      distanceKm: distanceKm,
    );
  }

  ServiceModel withDistance(double km) =>
      ServiceModel(
        id: id,
        serviceName: serviceName,
        serviceType: serviceType,
        description: description,
        latitude: latitude,
        longitude: longitude,
        contactPerson: contactPerson,
        contactNumber: contactNumber,
        operatingHours: operatingHours,
        is24Hours: is24Hours,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
        distanceKm: km,
      );

  @override
  List<Object?> get props => [id, serviceName, serviceType, latitude, longitude];
}
