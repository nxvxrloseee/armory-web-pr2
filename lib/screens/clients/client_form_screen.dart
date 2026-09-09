import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/client.dart';
import '../../repositories/client_repository.dart';
import '../../repositories/repository_exceptions.dart';
import '../../utils/validators.dart';
import '../../widgets/entity_form_scaffold.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Один экран на создание и на изменение. Лицензия — связь один к одному —
/// редактируется прямо здесь же, вложенной группой полей (см. приложение Б,
/// раздел 3.3): отдельного экрана или репозитория для неё нет.
class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _issuedController = TextEditingController();
  final _expiresController = TextEditingController();

  DateTime? _licenseIssuedAt;
  DateTime? _licenseExpiresAt;

  bool _loading = true;
  bool _dirty = false;
  String? _emailServerError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    _issuedController.dispose();
    _expiresController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Client? client;
    if (widget.isEditing) {
      client = await context.read<ClientRepository>().findById(widget.id!);
    }
    if (!mounted) return;
    setState(() {
      if (client != null) {
        _fullNameController.text = client.fullName;
        _emailController.text = client.email;
        _phoneController.text = client.phone;
        _licenseNumberController.text = client.licenseNumber;
        _licenseIssuedAt = client.licenseIssuedAt;
        _licenseExpiresAt = client.licenseExpiresAt;
        _issuedController.text = _formatDate(client.licenseIssuedAt);
        _expiresController.text = _formatDate(client.licenseExpiresAt);
      }
      _loading = false;
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickDate({required bool isIssued}) async {
    final now = DateTime.now();
    // Каскад связанных списков (задание, раздел 4, оценка «5»): выбранная
    // дата выдачи сужает доступный диапазон в календаре «Действует до» —
    // выбрать более раннюю дату там физически нельзя, а не только получить
    // ошибку валидации постфактум.
    final earliestExpiry = _licenseIssuedAt?.add(const Duration(days: 1)) ?? DateTime(1990);
    final firstDate = isIssued ? DateTime(1990) : earliestExpiry;
    var initial = (isIssued ? _licenseIssuedAt : _licenseExpiresAt) ?? now;
    if (initial.isBefore(firstDate)) initial = firstDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) return;
    setState(() {
      if (isIssued) {
        _licenseIssuedAt = picked;
        _issuedController.text = _formatDate(picked);
        // Ранее выбранный срок действия мог оказаться раньше новой даты
        // выдачи — раз диапазон сузился, сбрасываем его, чтобы не оставлять
        // на экране значение, которое календарь для «Действует до» больше
        // не позволил бы выбрать.
        if (_licenseExpiresAt != null && !_licenseExpiresAt!.isAfter(picked)) {
          _licenseExpiresAt = null;
          _expiresController.clear();
        }
      } else {
        _licenseExpiresAt = picked;
        _expiresController.text = _formatDate(picked);
      }
    });
    _markDirty();
  }

  Future<void> _handleSubmit() async {
    final draft = Client(
      id: widget.id ?? 0,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      licenseNumber: _licenseNumberController.text.trim(),
      licenseIssuedAt: _licenseIssuedAt!,
      licenseExpiresAt: _licenseExpiresAt!,
    );
    final repository = context.read<ClientRepository>();
    try {
      if (widget.isEditing) {
        await repository.update(draft);
      } else {
        await repository.create(draft);
      }
    } on UniqueConstraintException catch (e) {
      setState(() => _emailServerError = e.message);
      return;
    }
    if (!mounted) return;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.isEditing ? 'Изменить покупателя' : 'Новый покупатель')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return EntityFormScaffold(
      title: widget.isEditing ? 'Изменить покупателя' : 'Новый покупатель',
      isDirty: _dirty,
      onSave: _handleSubmit,
      fields: [
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(labelText: 'ФИО', border: OutlineInputBorder()),
          validator: Validators.combine([Validators.required(), Validators.maxLength(120)]),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Почта',
            border: const OutlineInputBorder(),
            errorText: _emailServerError,
          ),
          validator: Validators.combine([Validators.required(), Validators.email()]),
          onChanged: (_) {
            if (_emailServerError != null) setState(() => _emailServerError = null);
            _markDirty();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Телефон', border: OutlineInputBorder()),
          validator: Validators.combine([Validators.required(), Validators.lengthRange(5, 20)]),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 24),
        const Text('Лицензия на оружие', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _licenseNumberController,
          decoration: const InputDecoration(labelText: 'Номер лицензии', border: OutlineInputBorder()),
          validator: Validators.combine([Validators.required(), Validators.lengthRange(3, 30)]),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _issuedController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Дата выдачи',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today_outlined),
          ),
          onTap: () => _pickDate(isIssued: true),
          validator: (_) => _licenseIssuedAt == null ? 'Укажите дату выдачи' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _expiresController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Действует до',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today_outlined),
          ),
          onTap: () => _pickDate(isIssued: false),
          validator: (_) {
            if (_licenseExpiresAt == null) return 'Укажите срок действия';
            if (_licenseIssuedAt != null && !_licenseExpiresAt!.isAfter(_licenseIssuedAt!)) {
              return 'Должна быть позже даты выдачи';
            }
            return null;
          },
        ),
      ],
    );
  }
}
