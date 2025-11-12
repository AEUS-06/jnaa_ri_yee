import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ApiService {
  static const String _baseUrl = 'http://10.26.177.89'; // Cambia según tu red

  /// Envía una imagen al backend y obtiene la predicción
  static Future<String?> sendImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/predict/'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        return data['prediction'];
      } else {
        print('Error: ${response.statusCode}');
        print('Respuesta: $responseBody');
        return null;
      }
    } catch (e) {
      print('Error al enviar la imagen: $e');
      return null;
    }
  }

  /// Guarda una imagen temporal (por ejemplo, desde la cámara)
  static Future<File> saveTempImage(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/frame.jpg');
    await file.writeAsBytes(bytes);
    return file;
  }
}
