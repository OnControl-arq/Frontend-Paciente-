import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/patient_profile.dart';
import '../../domain/repositories/patient_repository.dart';
import '../datasources/patient_remote_datasource.dart';

class PatientRepositoryImpl implements PatientRepository {
  final PatientRemoteDataSource remote;
  final FlutterSecureStorage secureStorage;

  // Inyectamos secureStorage para no depender de "dummies"
  PatientRepositoryImpl({
    required this.remote, 
    this.secureStorage = const FlutterSecureStorage()
  });

  @override
  Future<void> createProfile(PatientProfile profile) async {
    // VALIDACIÓN REAL: Obtenemos el token del almacenamiento seguro
    final token = await secureStorage.read(key: 'token');
    
    if (token == null) {
      throw Exception('No authentication token found. Please login again.');
    }

    final data = {
      "userId": profile.userId,
      "firstName": profile.firstName,
      "lastName": profile.lastName,
      "email": profile.email,
      "phoneNumber": profile.phoneNumber,
      "birthDate": profile.birthDate,
      "gender": profile.gender,
      "photoUrl": profile.photoUrl 
    };

    // Pasamos el token real al datasource
    await remote.createProfile(data, token);
  }

  // Método nuevo para subir foto
  // NOTA: Asegúrate de agregar este método a tu interfaz abstracta PatientRepository
  // en domain/repositories/patient_repository.dart
  Future<String> uploadProfilePhoto(File file, int userId, String token) async {
    // Aquí usamos el token que nos pasan (o podríamos leerlo de secureStorage también)
    if (token.isEmpty) {
       throw Exception('Token invalido para subida de imagen');
    }
    return await remote.uploadPhoto(file, userId, token);
  }
}