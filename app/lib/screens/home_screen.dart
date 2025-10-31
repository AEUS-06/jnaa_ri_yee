import 'package:flutter/material.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_navbar.dart';
import 'camera_screen.dart';
import 'info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    Center(child: SizedBox.shrink()), // Home se construye dinámicamente
    CameraScreen(),
    InfoScreen(),
  ];

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showMeaningDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black54, // Fondo semi-transparente
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Significado de jñ\'a ri y\'ë\'ë',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '• jñ\'a: hablar\n• ri: tiempo presente\n• y\'ë\'ë: mano\n\n'
                'Interpretación completa: "La mano que habla"',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeContent = Center(
      child: GestureDetector(
        onTap: _showMeaningDialog,
        child: const Text(
          "jñ'a ri y'ë'ë",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          IndexedStack(
            index: _selectedIndex,
            children: [
              homeContent,
              ..._screens.sublist(1),
            ],
          ),
        ],
      ),
      bottomNavigationBar: NeonNavbar(
        currentIndex: _selectedIndex,
        onItemSelected: _onNavItemSelected,
      ),
    );
  }
}
