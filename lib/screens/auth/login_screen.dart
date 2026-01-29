import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/accessible_text.dart';
import '../settings/language_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Формы
  final _teenFormKey = GlobalKey<FormState>();
  final _parentFormKey = GlobalKey<FormState>();
  final _psychologistFormKey = GlobalKey<FormState>();
  
  // Подросток
  final _nicknameController = TextEditingController();
  final _teenPasswordController = TextEditingController();
  
  // Родитель
  final _emailController = TextEditingController();
  final _parentPasswordController = TextEditingController();
  
  // Психолог
  final _psychologistEmailController = TextEditingController();
  final _psychologistPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _emailController.dispose();
    _parentPasswordController.dispose();
    _psychologistEmailController.dispose();
    _psychologistPasswordController.dispose();
    super.dispose();
  }

  /// Вход подростка по никнейму
  Future<void> _loginTeen() async {
    if (!_teenFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final user = await authService.signInTeen(
        nickname: _nicknameController.text.trim(),
        password: _teenPasswordController.text,
      );

      if (mounted) {
        context.go('/teen');
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

  /// Вход родителя по email
  Future<void> _loginParent() async {
    if (!_parentFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final user = await authService.signIn(
        email: _emailController.text.trim(),
        password: _parentPasswordController.text,
      );

      if (mounted) {
        // Проверяем роль пользователя
        if (user.role == UserRole.psychologist) {
          context.go('/psychologist'); // Интерфейс психолога
        } else if (user.linkedUserId == null) {
          context.go('/parent/link');
        } else {
          context.go('/parent');
        }
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

  /// Вход психолога по email
  Future<void> _loginPsychologist() async {
    if (!_psychologistFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final user = await authService.signIn(
        email: _psychologistEmailController.text.trim(),
        password: _psychologistPasswordController.text,
      );

      if (mounted) {
        // Проверяем, что это действительно психолог
        if (user.role != UserRole.psychologist) {
          setState(() {
            _errorMessage = AppLocalizations.of(context).get('notPsychologistAccount');
          });
          return;
        }
        
        // Редиректим на интерфейс психолога
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
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: Semantics(
        label: 'Экран входа. ${l10n.get('login')}',
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Селектор языка справа
              Align(
                alignment: Alignment.topRight,
                child: const LanguageSelector(),
              ),
              
              const SizedBox(height: 16),
              
              // Логотип
              Semantics(
                image: true,
                label: 'Логотип Anama',
                child: Image.asset(
                  'assets/images/logo.jpg',
                  height: 100,
                  width: 100,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Semantics(
                header: true,
                child: AccessibleText(
                  'Anama',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 32,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              AccessibleText(
                _getSubtitle(l10n),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 32),
              
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
                  tabs: [
                    Tab(text: '👦 ${l10n.get('iAmTeen')}'),
                    Tab(text: '👩 ${l10n.get('iAmParent')}'),
                    Tab(text: '🧠 ${l10n.get('psychologist')}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Сообщение об ошибке
              if (_errorMessage != null)
                Semantics(
                  liveRegion: true,
                  label: 'Ошибка: $_errorMessage',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!, width: 2),
                    ),
                    child: Row(
                      children: [
                        Semantics(
                          label: 'Иконка ошибки',
                          excludeSemantics: true,
                          child: Icon(Icons.error_outline, color: Colors.red[700]),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AccessibleText(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Контент табов
              SizedBox(
                height: 300,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Вкладка подростка
                    _buildTeenForm(),
                    // Вкладка родителя
                    _buildParentForm(),
                    // Вкладка психолога
                    _buildPsychologistForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
          ),
        ),
    );
  }

  Widget _buildTeenForm() {
    final l10n = AppLocalizations.of(context);
    
    return Form(
      key: _teenFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            textField: true,
            label: l10n.get('nickname'),
            hint: l10n.get('enterNickname'),
            child: TextFormField(
              controller: _nicknameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.get('nickname'),
                hintText: l10n.get('yourNickname'),
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.get('enterNickname');
                }
                if (value.length < 3) {
                  return l10n.get('minChars');
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          Semantics(
            textField: true,
            label: l10n.get('password'),
            hint: l10n.get('enterPassword'),
            child: TextFormField(
              controller: _teenPasswordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _loginTeen(),
              decoration: InputDecoration(
                labelText: l10n.get('password'),
                hintText: l10n.get('yourPassword'),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: Semantics(
                  button: true,
                  label: _obscurePassword ? l10n.get('showPassword') : l10n.get('hidePassword'),
                  child: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.get('enterPassword');
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          Semantics(
            button: true,
            label: l10n.get('login'),
            enabled: !_isLoading,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _loginTeen,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(0, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      l10n.login,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          TextButton(
            onPressed: () => context.go('/teen-forgot-password'),
            child: Text(l10n.get('forgotPassword')),
          ),
          
          TextButton(
            onPressed: () => context.go('/register'),
            child: Text(l10n.get('noAccount')),
          ),
        ],
      ),
    );
  }
  
  String _getSubtitle(AppLocalizations l10n) {
    // Разные подписи для разных языков
    final locale = l10n.locale.languageCode;
    switch (locale) {
      case 'kk':
        return 'Эмоциялық қауіпсіздік';
      case 'en':
        return 'Emotional safety';
      default:
        return 'Эмоциональная безопасность';
    }
  }

  Widget _buildParentForm() {
    final l10n = AppLocalizations.of(context);
    
    return Form(
      key: _parentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: l10n.get('email'),
              hintText: 'example@mail.com',
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.get('enterNickname').replaceAll('nickname', 'email');
              }
              if (!value.contains('@')) {
                return l10n.get('invalidEmailFormat');
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _parentPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: l10n.get('password'),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.get('enterPassword');
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _isLoading ? null : _loginParent,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.login),
          ),
          
          const SizedBox(height: 8),
          
          TextButton(
            onPressed: () => context.go('/forgot-password'),
            child: Text(l10n.get('forgotPassword')),
          ),
          
          TextButton(
            onPressed: () => context.go('/register'),
            child: Text(l10n.get('noAccount')),
          ),
        ],
      ),
    );
  }

  Widget _buildPsychologistForm() {
    final l10n = AppLocalizations.of(context);
    
    return Form(
      key: _psychologistFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            textField: true,
            label: l10n.get('email'),
            child: TextFormField(
              controller: _psychologistEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.get('email'),
                hintText: 'example@mail.com',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.get('enterPassword').replaceAll('password', 'email');
                }
                if (!value.contains('@')) {
                  return l10n.get('invalidEmailFormat');
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          Semantics(
            textField: true,
            label: l10n.get('password'),
            child: TextFormField(
              controller: _psychologistPasswordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _loginPsychologist(),
              decoration: InputDecoration(
                labelText: l10n.get('password'),
                hintText: l10n.get('yourPassword'),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: Semantics(
                  button: true,
                  label: _obscurePassword ? l10n.get('showPassword') : l10n.get('hidePassword'),
                  child: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.get('enterPassword');
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          Semantics(
            button: true,
            label: l10n.get('login'),
            enabled: !_isLoading,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _loginPsychologist,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(0, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      l10n.login,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          TextButton(
            onPressed: () => context.go('/forgot-password'),
            child: Text(l10n.get('forgotPassword')),
          ),
          
          TextButton(
            onPressed: () => context.go('/register-psychologist'),
            child: Text(l10n.get('noAccount')),
          ),
        ],
      ),
    );
  }
}
