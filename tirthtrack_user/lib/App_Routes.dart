import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'home_screen.dart';
class AppRoutes{
   String splashScreen = '/splash_screen';
   String homeScreen = '/home_screen';

   late Map<String, Widget Function(BuildContext)> routes = {
      splashScreen: (context) => const SplashScreen(),
      homeScreen: (context) => const HomeScreen(),
   };

}