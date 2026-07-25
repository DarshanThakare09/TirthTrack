import 'package:flutter/material.dart';
import 'App_Routes.dart';
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TirthTrack",
      debugShowCheckedModeBanner: false,
      routes: AppRoutes().routes,
      initialRoute: AppRoutes().splashScreen,
    );
  }
}
