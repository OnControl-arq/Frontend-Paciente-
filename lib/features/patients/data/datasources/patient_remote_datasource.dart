import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/config.dart';

abstract class PatientRemoteDataSource {
  Future<void> createProfile(Map<String, dynamic> profileData, String token);
  // Agregamos el método para subir foto
  Future<String> uploadPhoto(File imageFile, int userId, String token);
}

class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final http.Client client;

  PatientRemoteDataSourceImpl(this.client);

  @override
  Future<void> createProfile(Map<String, dynamic> profileData, String token) async {
    final uri = Uri.parse('${Config.BASE_URL}${Config.CREATE_PROFILE_URL}');
    
    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Token real
      },
      body: jsonEncode(profileData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error creating profile (${response.statusCode}): ${response.body}');
    }
  }

  @override
  Future<String> uploadPhoto(File imageFile, int userId, String token) async {
    // 1. Preparar la solicitud de URL firmada
    final fileName = 'patient_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final contentType = 'image/jpeg';
    
    final presignUri = Uri.parse('${Config.BASE_URL}${Config.PRESIGN_UPLOAD_URL}');
    
    // Solicitamos la URL firmada al Backend
    final presignResponse = await client.post(
      presignUri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Token validado
      },
      body: jsonEncode({
        "category": "profile",
        "filename": fileName,
        "contentType": contentType,
        "userId": userId
      }),
    );

    if (presignResponse.statusCode != 200) {
      throw Exception('Error obteniendo URL firmada: ${presignResponse.body}');
    }

    // 2. Extraer URLs de la respuesta
    final data = jsonDecode(presignResponse.body);
    final String uploadUrl = data['uploadUrl']; // URL segura de AWS para subir
    final String accessUrl = data['accessUrl']; // URL pública para visualizar

    // 3. Subir la imagen a AWS S3 usando la uploadUrl
    final imageBytes = await imageFile.readAsBytes();
    
    final uploadResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': contentType,
        // En S3 firmado no se suele enviar Bearer token en el PUT directo al bucket, 
        // la seguridad está en la propia URL.
      },
      body: imageBytes,
    );

    if (uploadResponse.statusCode != 200) {
      throw Exception('Error subiendo imagen a S3 (${uploadResponse.statusCode})');
    }

    // 4. Retornar la URL pública
    return accessUrl;
  }
}