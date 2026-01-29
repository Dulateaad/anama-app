import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/teen_registration_data.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Формы
  final _teenFormKey = GlobalKey<FormState>();
  final _parentFormKey = GlobalKey<FormState>();
  
  // Подросток
  final _nicknameController = TextEditingController();
  final _teenPasswordController = TextEditingController();
  final _teenConfirmPasswordController = TextEditingController();
  Gender? _selectedGender;
  
  // Родитель
  final _emailController = TextEditingController();
  final _parentPasswordController = TextEditingController();
  final _parentConfirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _errorMessage = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nicknameController.dispose();
    _teenPasswordController.dispose();
    _teenConfirmPasswordController.dispose();
    _emailController.dispose();
    _parentPasswordController.dispose();
    _parentConfirmPasswordController.dispose();
    super.dispose();
  }

  /// Регистрация подростка
  Future<void> _registerTeen() async {
    if (!_teenFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Создаём данные регистрации и переходим к Age Gate
      final registrationData = TeenRegistrationData(
        nickname: _nicknameController.text.trim(),
        password: _teenPasswordController.text,
        gender: _selectedGender,
      );
      
      if (mounted) {
        context.go('/age-gate', extra: registrationData);
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

  /// Регистрация родителя
  Future<void> _registerParent() async {
    if (!_parentFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _parentPasswordController.text,
        role: UserRole.parent,
      );

      if (mounted) {
        context.go('/parent/link');
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
        title: const Text('Регистрация'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Табы
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '👦 Подросток'),
                    Tab(text: '👩 Родитель'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Сообщение об ошибке
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
              
              // Контент табов
              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTeenForm(),
                    _buildParentForm(),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Кнопка для психологов
              OutlinedButton.icon(
                onPressed: () => context.push('/register-psychologist'),
                icon: const Icon(Icons.psychology),
                label: const Text('Вы Психолог?'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.purple[300]!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeenForm() {
    return Form(
      key: _teenFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Подсказка
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Придумай никнейм — его будешь использовать для входа',
                    style: TextStyle(color: Colors.blue[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              labelText: 'Никнейм',
              hintText: 'Например: coolkid2010',
              prefixIcon: Icon(Icons.person),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введи никнейм';
              }
              if (value.length < 3) {
                return 'Минимум 3 символа';
              }
              if (value.length > 20) {
                return 'Максимум 20 символов';
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                return 'Только буквы, цифры и _';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _teenPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Пароль',
              hintText: 'Минимум 6 символов',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введи пароль';
              }
              if (value.length < 6) {
                return 'Минимум 6 символов';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _teenConfirmPasswordController,
            obscureText: _obscurePassword,
            decoration: const InputDecoration(
              labelText: 'Повтори пароль',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value != _teenPasswordController.text) {
                return 'Пароли не совпадают';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Выбор пола
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Твой пол',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('👦 Мальчик'),
                        ],
                      ),
                      selected: _selectedGender == Gender.male,
                      onSelected: (selected) {
                        setState(() {
                          _selectedGender = selected ? Gender.male : null;
                        });
                      },
                      selectedColor: Colors.blue[100],
                      labelStyle: TextStyle(
                        color: _selectedGender == Gender.male 
                            ? Colors.blue[900] 
                            : Colors.grey[700],
                        fontWeight: _selectedGender == Gender.male 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('👧 Девочка'),
                        ],
                      ),
                      selected: _selectedGender == Gender.female,
                      onSelected: (selected) {
                        setState(() {
                          _selectedGender = selected ? Gender.female : null;
                        });
                      },
                      selectedColor: const Color(0xFFF3C6CF),
                      labelStyle: TextStyle(
                        color: _selectedGender == Gender.female 
                            ? const Color(0xFFD4899A) 
                            : Colors.grey[700],
                        fontWeight: _selectedGender == Gender.female 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _isLoading ? null : _registerTeen,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Создать аккаунт'),
          ),
        ],
      ),
    );
  }

  Widget _buildParentForm() {
    return Form(
      key: _parentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'example@mail.com',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
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
            controller: _parentPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Пароль',
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
            controller: _parentConfirmPasswordController,
            obscureText: _obscurePassword,
            decoration: const InputDecoration(
              labelText: 'Повторите пароль',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value != _parentPasswordController.text) {
                return 'Пароли не совпадают';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _isLoading ? null : _registerParent,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Зарегистрироваться'),
          ),
        ],
      ),
    );
  }
}
