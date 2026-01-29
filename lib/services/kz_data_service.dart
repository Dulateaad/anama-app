import 'dart:convert';
import 'package:http/http.dart' as http;

/// Сервис для хранения персональных данных на сервере в РК
/// Согласно статье 12 Закона РК «О персональных данных и их защите»
class KzDataService {
  // URL сервера в Казахстане (заменить на реальный)
  static const String _baseUrl = 'https://api.anama.kz'; // Сервер в РК
  
  // Для разработки можно использовать локальный сервер
  static const bool _isDev = true;
  static const String _devUrl = 'http://localhost:3001';
  
  String get baseUrl => _isDev ? _devUrl : _baseUrl;

  /// Сохранить персональные данные на сервер в РК
  Future<bool> savePersonalData({
    required String visitorId, // Связь с Firebase через анонимный ID
    String? fullName,
    String? email,
    String? phone,
    DateTime? birthDate,
    String? parentFullName,
    String? parentPhone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/personal-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'visitorId': visitorId,
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'birthDate': birthDate?.toIso8601String(),
          'parentFullName': parentFullName,
          'parentPhone': parentPhone,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error saving personal data to KZ server: $e');
      return false;
    }
  }

  /// Получить персональные данные
  Future<Map<String, dynamic>?> getPersonalData(String visitorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/personal-data/$visitorId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting personal data from KZ server: $e');
      return null;
    }
  }

  /// Удалить персональные данные (GDPR право на удаление)
  Future<bool> deletePersonalData(String visitorId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/personal-data/$visitorId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting personal data from KZ server: $e');
      return false;
    }
  }

  /// Анонимизировать данные
  Future<bool> anonymizePersonalData(String visitorId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/personal-data/$visitorId/anonymize'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error anonymizing personal data: $e');
      return false;
    }
  }

  /// Экспорт данных (GDPR право на переносимость)
  Future<Map<String, dynamic>?> exportUserData(String visitorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/personal-data/$visitorId/export'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error exporting user data: $e');
      return null;
    }
  }
}

