import 'dart:ui';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final List<Widget> _screens = const [
    SizedBox.shrink(),
    CameraScreen(),
    InfoScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _onNavItemSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showMeaningDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: anim1,
              curve: Curves.easeOutBack,
            ),
            child: Dialog(
              backgroundColor: Colors.black.withOpacity(0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.cyanAccent, Colors.purpleAccent],
                      ).createShader(bounds),
                      child: const Text(
                        'Significado de jñ\'a ri y\'ë\'ë',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '• jñ\'a: hablar\n• ri: tiempo presente\n• y\'ë\'ë: mano\n\nInterpretación: “La mano que habla”',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.cyanAccent,
                        side: const BorderSide(color: Colors.cyanAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) =>
          FadeTransition(opacity: anim1, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeContent = Center(
      child: GestureDetector(
        onTap: _showMeaningDialog,
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, _) => Opacity(
            opacity: _glowAnimation.value,
            child: Text(
              "jñ'a ri y'ë'ë",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent.withOpacity(0.9),
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    blurRadius: 25 * _glowAnimation.value,
                    color: Colors.cyanAccent,
                  ),
                  const Shadow(
                    blurRadius: 15,
                    color: Colors.purpleAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: IndexedStack(
              key: ValueKey(_selectedIndex),
              index: _selectedIndex,
              children: [
                homeContent,
                ..._screens.sublist(1),
              ],
            ),
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
