import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; 
import '../widgets/animated_background.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _cameraVisible = false;
  bool _isSending = false;
  bool _loopActive = false;
  String predictionText = "Esperando detección...";

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation =
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _loopActive = false;
    _controller?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      setState(() => _cameraVisible = true);
      _loopActive = true;
      startPredictionLoop();
    } catch (e) {
      print("Error inicializando cámara: $e");
    }
  }

  //Bucle de predicción controlado para evitar saturación
  void startPredictionLoop() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    while (_loopActive && mounted) {
      if (_isSending) {
        await Future.delayed(const Duration(milliseconds: 300));
        continue;
      }

      try {
        _isSending = true;

        //Captura imagen
        final picture = await _controller!.takePicture();

        //Espera ligera para asegurar que el archivo se escriba completamente
        await Future.delayed(const Duration(milliseconds: 200));

        //Envía al backend
        await sendFrame(File(picture.path));

        //Intervalo entre capturas
        await Future.delayed(const Duration(milliseconds: 1500));
      } catch (e) {
        print("Error capturando frame: $e");
        await Future.delayed(const Duration(seconds: 1));
      } finally {
        _isSending = false;
      }
    }
  }

  //Envía una imagen al servidor
  Future<void> sendFrame(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.26.177.89:8000/predict/'), //tu backend
      );

      // ⚡️ Indicamos explícitamente que es una imagen JPEG
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      var response = await request.send();
      var respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResp = json.decode(respStr);
        if (mounted) {
          setState(() {
            predictionText =
                "Seña detectada: ${jsonResp['prediction']} (${(jsonResp['confidence'] * 100).toStringAsFixed(1)}%)";
          });
        }
      } else {
        print("Error del servidor: ${response.statusCode}");
        if (mounted) {
          setState(() {
            predictionText = "Error del servidor (${response.statusCode})";
          });
        }
      }
    } catch (e) {
      print("Error enviando frame: $e");
      if (mounted) {
        setState(() {
          predictionText = "Error de conexión con el servidor";
        });
      }
    } finally {
      // 🧹 Limpia archivos temporales
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Traducción en Tiempo Real',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.cyanAccent, blurRadius: 10)
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Activa la cámara y muestra las señas para obtener la traducción instantánea.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!_cameraVisible)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + _pulseAnimation.value * 0.1,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: const BorderSide(
                                  color: Colors.cyanAccent,
                                  width: 2,
                                ),
                              ),
                              elevation: 8,
                              shadowColor:
                                  Colors.cyanAccent.withOpacity(0.5),
                            ),
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.white),
                            label: const Text(
                              'Activar Cámara',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18),
                            ),
                            onPressed: _initCamera,
                          ),
                        );
                      },
                    )
                  else
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: CameraPreview(_controller!),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.cyanAccent,
                                width: 1.5,
                              ),
                            ),
                            child: AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                predictionText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            '💡 Enfoca tus manos en el centro para una mejor detección.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white70, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
