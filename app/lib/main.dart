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
      title: 'Jñaa Ri Yee - Traductor de Señas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      initialRoute: AppRoutes.initialRoute,
      routes: AppRoutes.getRoutes(),
    );
  }
}