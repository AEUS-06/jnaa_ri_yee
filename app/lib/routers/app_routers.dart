import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/info_screen.dart';

class AppRoutes {
  static const initialRoute = '/home';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/home': (context) => const HomeScreen(),
      '/camera': (context) => const CameraScreen(),
      '/info': (context) => const InfoScreen(),
    };
  }
}
