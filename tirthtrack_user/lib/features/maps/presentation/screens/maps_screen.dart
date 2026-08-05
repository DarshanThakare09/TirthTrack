// ============================================================
// features/maps/presentation/screens/maps_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tabs/police_base_tab.dart';
import '../tabs/routes_tab.dart';
import '../tabs/services_tab.dart';

class MapsScreen extends ConsumerWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Maps'),
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.route_rounded), text: 'Routes'),
              Tab(icon: Icon(Icons.place_rounded), text: 'Services'),
              Tab(icon: Icon(Icons.local_police_rounded), text: 'Police Base'),
            ],
            tabAlignment: TabAlignment.fill,
          ),
        ),
        body: const TabBarView(
          children: [
            RoutesTab(),
            ServicesTab(),
            PoliceBaseTab(),
          ],
        ),
      ),
    );
  }
}
