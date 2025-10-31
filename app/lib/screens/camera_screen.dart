import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import '../widgets/animated_background.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _cameraVisible = false;
  String predictionText = "";

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Inicializa la cámara
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
    setState(() => _cameraVisible = true);

    // Inicia el loop de predicción
    startPredictionLoop();
  }

  // Loop para capturar frames y enviar al backend
  void startPredictionLoop() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    while (_cameraVisible) {
      try {
        final picture = await _controller!.takePicture();
        await sendFrame(File(picture.path));
        await Future.delayed(const Duration(milliseconds: 500)); // Ajusta velocidad
      } catch (e) {
        print("Error capturando frame: $e");
      }
    }
  }

  // Envía un frame al backend FastAPI
  Future<void> sendFrame(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/predict/'), // Cambiar según red/emulador
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      var jsonResp = json.decode(respStr);

      if (mounted) {
        setState(() {
          predictionText = "Predicción: ${jsonResp['prediction']}";
        });
      }
    } catch (e) {
      print("Error enviando frame: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AnimatedBackground(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Traducción de Lenguaje de Señas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Presiona el botón para activar la cámara y comenzar la detección en tiempo real.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Botón para abrir cámara
                if (!_cameraVisible)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 8,
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 26),
                    label: const Text(
                      'Abrir Cámara',
                      style: TextStyle(fontSize: 18),
                    ),
                    onPressed: _initCamera,
                  ),

                // Vista previa de la cámara con predicción
                if (_cameraVisible) ...[
                  const SizedBox(height: 25),
                  FutureBuilder(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: CameraPreview(_controller!),
                              ),
                            ),
                            Positioned(
                              bottom: 15,
                              left: 15,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  predictionText,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 22),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'La cámara está activa.\nApunta las manos dentro del marco para detectar las señas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
