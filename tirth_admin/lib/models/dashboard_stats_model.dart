import 'package:equatable/equatable.dart';

class DashboardStatsModel extends Equatable {
  const DashboardStatsModel({
    required this.totalPolice,
    required this.pendingPolice,
    required this.verifiedPolice,
    required this.totalRoutes,
    required this.activeRoutes,
    required this.totalServices,
    required this.activeServices,
    required this.totalPoliceBases,
    required this.totalSectors,
    required this.activeAlerts,
    required this.totalAlerts,
  });

  final int totalPolice;
  final int pendingPolice;
  final int verifiedPolice;
  final int totalRoutes;
  final int activeRoutes;
  final int totalServices;
  final int activeServices;
  final int totalPoliceBases;
  final int totalSectors;
  final int activeAlerts;
  final int totalAlerts;

  factory DashboardStatsModel.empty() {
    return const DashboardStatsModel(
      totalPolice: 0,
      pendingPolice: 0,
      verifiedPolice: 0,
      totalRoutes: 0,
      activeRoutes: 0,
      totalServices: 0,
      activeServices: 0,
      totalPoliceBases: 0,
      totalSectors: 0,
      activeAlerts: 0,
      totalAlerts: 0,
    );
  }

  @override
  List<Object?> get props => [
        totalPolice,
        pendingPolice,
        verifiedPolice,
        totalRoutes,
        activeRoutes,
        totalServices,
        activeServices,
        totalPoliceBases,
        totalSectors,
        activeAlerts,
        totalAlerts,
      ];
}
