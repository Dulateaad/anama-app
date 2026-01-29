import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/psychologist_model.dart';
import '../../l10n/app_localizations.dart';

/// Экран профиля психолога
class PsychologistProfileScreen extends StatefulWidget {
  const PsychologistProfileScreen({super.key});

  @override
  State<PsychologistProfileScreen> createState() => _PsychologistProfileScreenState();
}

class _PsychologistProfileScreenState extends State<PsychologistProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _specializationController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  Psychologist? _psychologist;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _qualificationController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    
    if (currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('psychologists')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        final psychologist = Psychologist.fromMap(
          doc.data() as Map<String, dynamic>,
          currentUserId,
        );
        
        setState(() {
          _psychologist = psychologist;
          _fullNameController.text = psychologist.fullName;
          _qualificationController.text = psychologist.qualification;
          _specializationController.text = psychologist.specialization;
          _bioController.text = psychologist.bio ?? '';
          _experienceController.text = psychologist.experienceYears.toString();
          _phoneController.text = psychologist.phone ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки профиля: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    
    if (currentUserId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('psychologists')
          .doc(currentUserId)
          .update({
        'fullName': _fullNameController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'bio': _bioController.text.trim().isEmpty 
            ? null 
            : _bioController.text.trim(),
        'experienceYears': int.tryParse(_experienceController.text.trim()) ?? 0,
        'phone': _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль успешно обновлен'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProfile(); // Перезагружаем профиль
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKazakh = l10n.locale.languageCode == 'kk';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isKazakh ? 'Профиль' : 'Профиль'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isKazakh ? 'Профиль' : 'Мой профиль'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Статус верификации
              if (_psychologist != null) ...[
                Card(
                  color: _psychologist!.isVerified 
                      ? Colors.green[50] 
                      : Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _psychologist!.isVerified 
                              ? Icons.verified 
                              : Icons.pending,
                          color: _psychologist!.isVerified 
                              ? Colors.green[700] 
                              : Colors.orange[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _psychologist!.isVerified 
                                    ? (isKazakh ? 'Верификацияланған' : 'Верифицирован')
                                    : (isKazakh ? 'Верификация күтуде' : 'Ожидает верификации'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _psychologist!.isVerified 
                                      ? Colors.green[900] 
                                      : Colors.orange[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isKazakh
                                  ? 'Профиліңіз әкімші тарапынан тексерілуде'
                                  : 'Ваш профиль проверяется администратором',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _psychologist!.isVerified 
                                      ? Colors.green[700] 
                                      : Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ФИО
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: isKazakh ? 'Аты-жөні' : 'ФИО *',
                  prefixIcon: const Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return isKazakh ? 'Аты-жөнін енгізіңіз' : 'Введите ФИО';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Квалификация
              TextFormField(
                controller: _qualificationController,
                decoration: InputDecoration(
                  labelText: isKazakh ? 'Біліктілік' : 'Квалификация *',
                  prefixIcon: const Icon(Icons.school),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return isKazakh ? 'Біліктілікті көрсетіңіз' : 'Укажите квалификацию';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Специализация
              TextFormField(
                controller: _specializationController,
                decoration: InputDecoration(
                  labelText: isKazakh ? 'Мамандық' : 'Специализация *',
                  prefixIcon: const Icon(Icons.work_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return isKazakh ? 'Мамандықты көрсетіңіз' : 'Укажите специализацию';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Опыт работы
              TextFormField(
                controller: _experienceController,
                decoration: InputDecoration(
                  labelText: isKazakh ? 'Тәжірибе (жыл)' : 'Опыт работы (лет)',
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Телефон
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: isKazakh ? 'Телефон' : 'Телефон',
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // Биография
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: isKazakh ? 'Биография' : 'Краткая биография',
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 32),

              // Кнопка сохранения
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isKazakh ? 'Сақтау' : 'Сохранить',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

