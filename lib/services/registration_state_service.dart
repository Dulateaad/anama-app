import 'package:flutter/foundation.dart';
import '../models/teen_registration_data.dart';

/// Сервис для хранения данных регистрации между экранами
/// Решает проблему потери state.extra в go_router на web
class RegistrationStateService extends ChangeNotifier {
  TeenRegistrationData? _teenRegistrationData;

  TeenRegistrationData? get teenRegistrationData => _teenRegistrationData;

  /// Сохранить данные регистрации подростка
  void setTeenRegistrationData(TeenRegistrationData data) {
    _teenRegistrationData = data;
    notifyListeners();
  }

  /// Обновить возраст в данных регистрации
  void updateAge(int age) {
    if (_teenRegistrationData != null) {
      _teenRegistrationData = _teenRegistrationData!.copyWithAge(age);
      notifyListeners();
    }
  }

  /// Очистить данные после завершения регистрации
  void clear() {
    _teenRegistrationData = null;
    notifyListeners();
  }
}

