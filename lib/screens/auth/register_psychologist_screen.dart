import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/psychologist_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Экран регистрации психолога
class RegisterPsychologistScreen extends StatefulWidget {
  const RegisterPsychologistScreen({super.key});

  @override
  State<RegisterPsychologistScreen> createState() => _RegisterPsychologistScreenState();
}

class _RegisterPsychologistScreenState extends State<RegisterPsychologistScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Основные данные
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Профессиональные данные
  final _qualificationController = TextEditingController();
  final _specializationController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _qualificationController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _registerPsychologist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      
      // Регистрация пользователя
      final user = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: UserRole.psychologist,
        displayName: _fullNameController.text.trim(),
      );

      // Создание профиля психолога
      final psychologist = Psychologist(
        uid: user.uid,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        qualification: _qualificationController.text.trim(),
        specialization: _specializationController.text.trim(),
        bio: _bioController.text.trim().isEmpty 
            ? null 
            : _bioController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()) ?? 0,
        isVerified: true, // Сразу доступен в списке (без верификации для MVP)
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохранение профиля психолога в Firestore
      await FirebaseFirestore.instance
          .collection('psychologists')
          .doc(user.uid)
          .set(psychologist.toMap());

      if (mounted) {
        // Показываем сообщение об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Регистрация успешна! Добро пожаловать.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Переход в интерфейс психолога
        context.go('/psychologist');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация психолога'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Информационное сообщение
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.purple[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Регистрация для психологов',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'После регистрации ваш профиль будет проверен администратором',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Ошибка
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Личные данные
                Text(
                  'Личные данные',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'ФИО *',
                    hintText: 'Иванов Иван Иванович',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите ФИО';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'example@mail.com',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Неверный формат email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Телефон',
                    hintText: '+7 777 123 45 67',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Пароль *',
                    hintText: 'Минимум 6 символов',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Минимум 6 символов';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                    labelText: 'Повторите пароль *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Пароли не совпадают';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Профессиональные данные
                Text(
                  'Профессиональные данные',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _qualificationController,
                  decoration: const InputDecoration(
                    labelText: 'Квалификация *',
                    hintText: 'Например: Диплом психолога, МГУ, 2015',
                    prefixIcon: Icon(Icons.school),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Укажите квалификацию';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                    labelText: 'Специализация *',
                    hintText: 'Например: Работа с подростками, семейная терапия',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Укажите специализацию';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _experienceController,
                  decoration: const InputDecoration(
                    labelText: 'Опыт работы (лет)',
                    hintText: '5',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Краткая биография',
                    hintText: 'Расскажите о себе...',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 4,
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerPsychologist,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Зарегистрироваться'),
                ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

