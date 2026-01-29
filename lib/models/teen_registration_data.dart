import '../models/user_model.dart';

/// Данные регистрации подростка
/// Передаются между экранами: Register → AgeGate → ParentalConsent
class TeenRegistrationData {
  final String nickname;
  final String password;
  final int? age;
  final Gender? gender;

  TeenRegistrationData({
    required this.nickname,
    required this.password,
    this.age,
    this.gender,
  });

  /// Создает копию с обновленным возрастом
  TeenRegistrationData copyWithAge(int age) {
    return TeenRegistrationData(
      nickname: nickname,
      password: password,
      age: age,
      gender: gender,
    );
  }
}

