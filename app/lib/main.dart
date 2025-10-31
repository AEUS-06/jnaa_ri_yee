import 'package:flutter/material.dart';
import 'routers/app_routers.dart';

void main() {
  runApp(const SignTranslateApp());
}

class SignTranslateApp extends StatelessWidget {
  const SignTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traductor de Señas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: AppRoutes.initialRoute,
      routes: AppRoutes.getRoutes(),
    );
  }
}
