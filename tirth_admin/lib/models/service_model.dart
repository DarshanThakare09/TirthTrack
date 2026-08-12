import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_colors.dart';

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
        return 'Medical / First Aid';
      case ServiceTypeEnum.food:
        return 'Food / Annadan';
      case ServiceTypeEnum.water:
        return 'Drinking Water';
      case ServiceTypeEnum.toilet:
        return 'Restroom / Toilet';
      case ServiceTypeEnum.parking:
        return 'Parking';
      case ServiceTypeEnum.fuel:
        return 'Fuel Station';
      case ServiceTypeEnum.police:
        return 'Police Post';
      case ServiceTypeEnum.helpdesk:
        return 'Helpdesk / Info';
      case ServiceTypeEnum.atm:
        return 'ATM';
      case ServiceTypeEnum.pharmacy:
        return 'Pharmacy';
      case ServiceTypeEnum.temple:
        return 'Temple / Ghat';
      case ServiceTypeEnum.busStop:
        return 'Bus Stand';
      case ServiceTypeEnum.railwayStation:
        return 'Railway Station';
      case ServiceTypeEnum.other:
        return 'Other Facility';
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
        return Icons.atm_rounded;
      case ServiceTypeEnum.pharmacy:
        return Icons.medication_rounded;
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

  static ServiceTypeEnum fromDb(String val) {
    switch (val.toLowerCase()) {
      case 'bus_stop':
        return ServiceTypeEnum.busStop;
      case 'railway_station':
        return ServiceTypeEnum.railwayStation;
      default:
        return ServiceTypeEnum.values.firstWhere(
          (e) => e.name == val.toLowerCase(),
          orElse: () => ServiceTypeEnum.other,
        );
    }
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
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
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

  LatLng get latLng => LatLng(latitude, longitude);

  String get formattedHours =>
      is24Hours ? 'Open 24 Hours' : (operatingHours ?? 'Hours Not Specified');

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      serviceName: json['service_name'] as String,
      serviceType: ServiceTypeEnumX.fromDb(json['service_type'] as String),
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
    );
  }

  Map<String, dynamic> toUpsertJson() {
    final map = <String, dynamic>{
      'service_name': serviceName,
      'service_type': serviceType.dbValue,
      'latitude': latitude,
      'longitude': longitude,
      'is_24_hours': is24Hours,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (description != null) map['description'] = description;
    if (contactPerson != null) map['contact_person'] = contactPerson;
    if (contactNumber != null) map['contact_number'] = contactNumber;
    if (operatingHours != null) map['operating_hours'] = operatingHours;
    return map;
  }

  @override
  List<Object?> get props => [
        id,
        serviceName,
        serviceType,
        latitude,
        longitude,
        is24Hours,
        isActive,
      ];
}
