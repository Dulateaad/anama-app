# 📊 Использование Firebase Analytics в Anama

## ✅ Модель Gemini обновлена
- Все модели обновлены на `gemini-3-flash-preview`
- Основная модель
- Модель кризисного анализа
- Модель для блока 0-5 лет

## 📖 Как использовать Firebase Analytics

### 1. Импорт сервиса

```dart
import 'package:anama/services/analytics_service.dart';

final analytics = AnalyticsService();
```

### 2. Примеры использования в ключевых местах

#### А) При получении задания Serve & Return (parent_home_screen.dart)

```dart
Future<void> _getServeAndReturnTask({bool showModal = true}) async {
  // ... существующий код ...
  
  try {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    
    final task = await _geminiService.generateServeAndReturnTask(
      childAgeMonths: _childAgeMonths,
      languageCode: languageCode,
    );
    
    // ✅ ДОБАВИТЬ: Логирование события аналитики
    await analytics.logServeAndReturnTask(
      childAgeMonths: _childAgeMonths,
      languageCode: languageCode,
    );
    
    // ... остальной код ...
  } catch (e) {
    // ... обработка ошибок ...
  }
}
```

#### Б) При регистрации подростка (register_screen.dart)

```dart
Future<void> _registerTeen() async {
  // ... существующий код регистрации ...
  
  try {
    final user = await authService.signUpTeen(
      nickname: _nicknameController.text.trim(),
      password: _passwordController.text,
      age: _selectedAge,
      gender: _selectedGender,
    );
    
    if (user != null) {
      // ✅ ДОБАВИТЬ: Логирование регистрации
      await AnalyticsService().logSignUp(
        method: 'email',
        userId: user.uid,
      );
      
      // ... переход на следующий экран ...
    }
  } catch (e) {
    // ... обработка ошибок ...
  }
}
```

#### В) При входе (login_screen.dart)

```dart
Future<void> _login() async {
  // ... существующий код входа ...
  
  try {
    final user = await authService.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    if (user != null) {
      // ✅ ДОБАВИТЬ: Логирование входа
      await AnalyticsService().logLogin(
        method: 'email',
        userId: user.uid,
      );
      
      // Установить ID пользователя для аналитики
      await AnalyticsService().setUserId(user.uid);
      
      // ... переход на главный экран ...
    }
  } catch (e) {
    // ... обработка ошибок ...
  }
}
```

#### Г) При начале теста (phq9_test_screen.dart, gad7_test_screen.dart, traffic_light_test_screen.dart)

```dart
@override
void initState() {
  super.initState();
  
  // ✅ ДОБАВИТЬ: Логирование начала теста
  _logTestStart();
  
  // ... остальной код инициализации ...
}

Future<void> _logTestStart() async {
  final authService = context.read<AuthService>();
  final user = await authService.getCurrentAnamaUser();
  
  await AnalyticsService().logTestStart(
    testName: 'phq9', // или 'gad7', 'traffic_light'
    userId: user?.uid,
  );
}
```

#### Д) При завершении теста (clinical_test_service.dart)

```dart
Future<void> submitPhq9Answers({
  required String userId,
  required Map<String, Phq9Response> answers,
}) async {
  // ... существующий код вычисления результатов ...
  
  final result = Phq9Result(
    userId: userId,
    answers: answers,
    totalScore: totalScore,
    severity: severity,
    completedAt: DateTime.now(),
  );
  
  // Сохранить результат
  await _saveResult(result);
  
  // ✅ ДОБАВИТЬ: Логирование завершения теста
  await AnalyticsService().logTestComplete(
    testName: 'phq9',
    score: result.totalScore,
    riskLevel: result.severity.name, // minimal, mild, moderate, severe
    userId: userId,
  );
  
  // ... отправка родителю и т.д. ...
}
```

#### Е) При просмотре экранов (в initState каждого экрана)

```dart
@override
void initState() {
  super.initState();
  
  // ✅ ДОБАВИТЬ: Логирование просмотра экрана
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AnalyticsService().logScreenView(
      screenName: '/parent/home', // имя экрана
      screenClass: 'ParentHomeScreen',
    );
  });
  
  // ... остальной код ...
}
```

#### Ж) При открытии приложения (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final analytics = FirebaseAnalytics.instance;
  await analytics.setAnalyticsCollectionEnabled(true);
  
  // ✅ ДОБАВИТЬ: Логирование открытия приложения
  await AnalyticsService().logAppOpen();
  
  runApp(const AnamaApp());
}
```

### 3. Пользовательские свойства

Установка свойств пользователя для сегментации:

```dart
// После успешной регистрации
await AnalyticsService().setUserProperty(
  name: 'user_type',
  value: 'teen', // или 'parent'
);

await AnalyticsService().setUserProperty(
  name: 'gender',
  value: gender == Gender.male ? 'male' : 'female',
);

await AnalyticsService().setUserProperty(
  name: 'age_group',
  value: age <= 12 ? 'child' : 'teen',
);
```

### 4. Просмотр событий в Firebase Console

1. Откройте Firebase Console: https://console.firebase.google.com/project/anama-app/analytics
2. Перейдите в **Analytics** → **Events**
3. События появятся через несколько минут после использования

### 5. Создание отчетов

В Firebase Console можно создать кастомные отчеты:
- **Analytics** → **Reports** → **Custom Reports**
- Добавить метрики:
  - Количество регистраций
  - Количество завершенных тестов
  - Средняя оценка по тестам
  - Время на экранах

### 6. Метрики для отслеживания

#### Конверсия регистрации:
```
sign_up → app_open (последующие открытия)
```

#### Эффективность тестов:
```
test_start → test_complete (конверсия завершения)
```

#### Вовлеченность:
```
serve_and_return_task → screen_view (просмотр результатов)
```

#### Точки выхода:
```
screen_exit с параметром time_on_screen_seconds
```

### 7. Отладка (в режиме разработки)

В веб-версии события логируются в консоль браузера:
```
📊 Analytics Event: test_start
   Parameters: {test_name: phq9, user_id: xxx}
```

## 📋 Чеклист интеграции

- [ ] Добавить `logAppOpen()` в `main.dart`
- [ ] Добавить `logSignUp()` в `register_screen.dart`
- [ ] Добавить `logLogin()` в `login_screen.dart`
- [ ] Добавить `logTestStart()` в экранах тестов
- [ ] Добавить `logTestComplete()` в `clinical_test_service.dart`
- [ ] Добавить `logServeAndReturnTask()` в `parent_home_screen.dart`
- [ ] Добавить `logScreenView()` в `initState` ключевых экранов
- [ ] Установить пользовательские свойства после регистрации

## 🔗 Полезные ссылки

- Firebase Analytics Docs: https://firebase.google.com/docs/analytics
- Flutter Firebase Analytics: https://firebase.flutter.dev/docs/analytics/overview

