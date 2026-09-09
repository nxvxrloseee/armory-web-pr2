import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/client.dart';
import '../../repositories/client_repository.dart';
import '../../widgets/confirm_dialog.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  Client? _client;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final client = await context.read<ClientRepository>().findById(widget.id);
    if (!mounted) return;
    setState(() {
      _client = client;
      _loading = false;
    });
  }

  Future<void> _handleSoftDelete(Client c) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить запись?',
      message: 'Логическое удаление: запись скроется из списка, её можно восстановить.',
    );
    if (!ok || !mounted) return;
    await context.read<ClientRepository>().softDelete(c.id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleRestore(Client c) async {
    await context.read<ClientRepository>().restore(c.id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleHardDelete(Client c) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить безвозвратно?',
      message: 'Физическое удаление нельзя отменить.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!ok || !mounted) return;
    await context.read<ClientRepository>().hardDelete(c.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = _client;
    return Scaffold(
      appBar: AppBar(
        title: Text(c?.fullName ?? 'Покупатель'),
        actions: [
          if (c != null)
            IconButton(
              tooltip: 'Изменить',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final changed = await context.push<bool>('/clients/${c.id}/edit');
                if (changed == true) await _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : c == null
              ? Center(child: Text('Запись №${widget.id} не найдена'))
              : _buildContent(context, c),
    );
  }

  Widget _buildContent(BuildContext context, Client c) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.isDeleted)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.red.withValues(alpha: 0.1),
                child: const Text('Эта запись удалена', style: TextStyle(color: Colors.red)),
              ),
            _row('Имя', c.fullName),
            _row('Почта', c.email),
            _row('Телефон', c.phone),
            const SizedBox(height: 16),
            Text('Лицензия на оружие', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _row('Номер', c.licenseNumber),
            _row('Выдана', _formatDate(c.licenseIssuedAt)),
            _row('Действует до', _formatDate(c.licenseExpiresAt)),
            if (c.isLicenseExpired)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange.withValues(alpha: 0.15),
                  child: const Text('Срок действия лицензии истёк', style: TextStyle(color: Colors.orange)),
                ),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: [
                if (!c.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _handleSoftDelete(c),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Удалить'),
                  ),
                if (c.isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _handleRestore(c),
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _handleHardDelete(c),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Удалить навсегда'),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Назад к списку'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
