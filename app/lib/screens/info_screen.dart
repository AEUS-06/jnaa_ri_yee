import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/animated_background.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

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
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Jñaa Ri Yee',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: Colors.cyanAccent, blurRadius: 15),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Una aplicación que traduce el lenguaje de señas mediante visión por computadora, fomentando la inclusión y comunicación entre personas sordas y oyentes.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
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
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildMemberCard(
                        name: 'Anahi Figueroa González',
                        linkedIn:
                            'https://www.linkedin.com/in/anahi-figueroa-gonzalez-2a4a3438b',
                        github: 'https://github.com/Ann8ix',
                      ),
                      _buildMemberCard(
                        name: 'Lilybet Pedral Hernández',
                        linkedIn: 'proximamente',
                        github: 'proximamente',
                      ),
                      _buildMemberCard(
                        name: 'Axel Eduardo Urbina Secundino',
                        linkedIn:
                            'https://www.linkedin.com/in/axel-eduardo-u-8124a837b',
                        github:
                            'https://github.com/AEUS-06?tab=overview&from=2025-10-01&to=2025-10-22',
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

  Widget _buildMemberCard({
    required String name,
    required String linkedIn,
    required String github,
  }) {
    final hasLinks = linkedIn != 'proximamente' && github != 'proximamente';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Card(
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: ListTile(
          leading: const Icon(Icons.person_outline, color: Colors.white),
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
                      onTap: () => _launchUrl(linkedIn),
                      child: const Text(
                        'LinkedIn',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _launchUrl(github),
                      child: const Text(
                        'GitHub',
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Enlaces próximamente disponibles',
                  style: TextStyle(color: Colors.white54),
                ),
        ),
      ),
    );
  }
}
