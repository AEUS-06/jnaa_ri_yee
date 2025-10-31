import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/animated_background.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  // Método para abrir enlaces externos
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AnimatedBackground(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Jñaa Ri Yee',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: Colors.blueAccent, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Una aplicación que busca traducir el lenguaje de señas mediante visión por computadora para mejorar la comunicación entre personas sordas y oyentes.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Integrantes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildMemberCard(
                        context,
                        name: 'Anahi Figueroa Gonzalez',
                        linkedIn: 'https://www.linkedin.com/in/anahi-figueroa-gonzalez-2a4a3438b?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app',
                        github: 'https://github.com/Ann8ix',
                        onLaunch: _launchUrl,
                      ),
                      _buildMemberCard(
                        context,
                        name: 'Lilybet Pedral Hernández',
                        linkedIn: 'proximamente',
                        github: 'proximamente',
                        onLaunch: _launchUrl,
                      ),
                      _buildMemberCard(
                        context,
                        name: 'Axel Eduardo Urbina Secundino',
                        linkedIn: 'https://www.linkedin.com/in/axel-eduardo-u-8124a837b?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app',
                        github: 'https://github.com/AEUS-06?tab=overview&from=2025-10-01&to=2025-10-22',
                        onLaunch: _launchUrl,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildMemberCard(
    BuildContext context, {
    required String name,
    required String linkedIn,
    required String github,
    required Function(String) onLaunch,
  }) {
    final bool hasLinks = linkedIn != 'proximamente' && github != 'proximamente';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Card(
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: ListTile(
          leading: const Icon(Icons.person, color: Colors.white, size: 36),
          title: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: hasLinks
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => onLaunch(linkedIn),
                      child: const Text(
                        'LinkedIn',
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onLaunch(github),
                      child: const Text(
                        'GitHub',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Enlaces próximamente disponibles',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
        ),
      ),
    );
  }
}
