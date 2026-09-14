import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../core/auth_api.dart';
import '../../state/auth_notifier.dart';
import '../../utils/validators.dart';
import '../../widgets/entity_form_scaffold.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Регистрация доступна только для роли "покупатель" — продавца и
/// администратора публичная форма не заводит (см. armory_api/internal/auth:
/// POST /auth/register всегда создаёт role='buyer'). Поля — ровно то, что
/// нужно для получения оружия: ФИО, паспорт, лицензия — те же данные, что
/// раньше вносил только продавец через форму покупателя.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _passportSeries = TextEditingController();
  final _passportNumber = TextEditingController();
  final _licenseNumber = TextEditingController();
  final _birthDateController = TextEditingController();
  final _issuedController = TextEditingController();
  final _expiresController = TextEditingController();

  DateTime? _birthDate;
  DateTime? _licenseIssuedAt;
  DateTime? _licenseExpiresAt;
  String? _usernameServerError;
  String? _emailServerError;

  @override
  void dispose() {
    for (final c in [
      _username,
      _password,
      _fullName,
      _email,
      _phone,
      _passportSeries,
      _passportNumber,
      _licenseNumber,
      _birthDateController,
      _issuedController,
      _expiresController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required DateTime firstDate,
    required void Function(DateTime) onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submit() async {
    setState(() {
      _usernameServerError = null;
      _emailServerError = null;
    });
    final input = RegisterInput(
      username: _username.text.trim(),
      password: _password.text,
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      birthDate: _birthDate!,
      passportSeries: _passportSeries.text.trim(),
      passportNumber: _passportNumber.text.trim(),
      licenseNumber: _licenseNumber.text.trim(),
      licenseIssuedAt: _licenseIssuedAt!,
      licenseExpiresAt: _licenseExpiresAt!,
    );
    try {
      await context.read<AuthNotifier>().register(input);
    } on ValidationException catch (e) {
      if (e.errors['username'] != null) setState(() => _usernameServerError = e.errors['username']);
      if (e.errors['email'] != null) setState(() => _emailServerError = e.errors['email']);
      if (e.errors['username'] == null && e.errors['email'] == null) rethrow;
      return;
    }
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormScaffold(
      title: 'Регистрация покупателя',
      isDirty: false,
      saveLabel: 'Зарегистрироваться',
      onSave: _submit,
      fields: [
        TextFormField(
          controller: _username,
          decoration: InputDecoration(
            labelText: 'Логин',
            border: const OutlineInputBorder(),
            errorText: _usernameServerError,
          ),
          validator: Validators.combine([Validators.required(), Validators.lengthRange(3, 40)]),
          onChanged: (_) => setState(() => _usernameServerError = null),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder()),
          validator: Validators.password(),
          // Проверка по мере ввода, а не только по кнопке — задание ПР5,
          // оценка «4». autovalidateMode делает то же самое декларативно.
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
        const SizedBox(height: 24),
        const Text('Личные данные', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fullName,
          decoration: const InputDecoration(labelText: 'ФИО', border: OutlineInputBorder()),
          validator: Validators.combine([Validators.required(), Validators.maxLength(120)]),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Почта',
            border: const OutlineInputBorder(),
            errorText: _emailServerError,
          ),
          validator: Validators.combine([Validators.required(), Validators.email()]),
          onChanged: (_) => setState(() => _emailServerError = null),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Телефон', border: OutlineInputBorder()),
          validator: Validators.combine([Validators.required(), Validators.lengthRange(5, 20)]),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _birthDateController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Дата рождения',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today_outlined),
          ),
          onTap: () => _pickDate(
            initial: _birthDate,
            firstDate: DateTime(1930),
            onPicked: (d) => setState(() {
              _birthDate = d;
              _birthDateController.text = _formatDate(d);
            }),
          ),
          validator: (_) => _birthDate == null ? 'Укажите дату рождения' : null,
        ),
        const SizedBox(height: 24),
        const Text('Паспорт и лицензия', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _passportSeries,
                decoration: const InputDecoration(labelText: 'Серия паспорта', border: OutlineInputBorder()),
                validator: Validators.required(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _passportNumber,
                decoration: const InputDecoration(labelText: 'Номер паспорта', border: OutlineInputBorder()),
                validator: Validators.required(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _licenseNumber,
          decoration: const InputDecoration(labelText: 'ID лицензии', border: OutlineInputBorder()),
          validator: Validators.combine([Validators.required(), Validators.lengthRange(3, 30)]),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _issuedController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Лицензия выдана',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today_outlined),
          ),
          onTap: () => _pickDate(
            initial: _licenseIssuedAt,
            firstDate: DateTime(1990),
            onPicked: (d) => setState(() {
              _licenseIssuedAt = d;
              _issuedController.text = _formatDate(d);
              if (_licenseExpiresAt != null && !_licenseExpiresAt!.isAfter(d)) {
                _licenseExpiresAt = null;
                _expiresController.clear();
              }
            }),
          ),
          validator: (_) => _licenseIssuedAt == null ? 'Укажите дату выдачи' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _expiresController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Лицензия действует до',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today_outlined),
          ),
          onTap: () => _pickDate(
            initial: _licenseExpiresAt,
            firstDate: _licenseIssuedAt?.add(const Duration(days: 1)) ?? DateTime(1990),
            onPicked: (d) => setState(() {
              _licenseExpiresAt = d;
              _expiresController.text = _formatDate(d);
            }),
          ),
          validator: (_) {
            if (_licenseExpiresAt == null) return 'Укажите срок действия';
            if (_licenseIssuedAt != null && !_licenseExpiresAt!.isAfter(_licenseIssuedAt!)) {
              return 'Должна быть позже даты выдачи';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Уже есть аккаунт? Войти'),
        ),
      ],
    );
  }
}
