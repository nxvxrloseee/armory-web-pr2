import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../state/auth_notifier.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    final isStaff = auth.has(Role.seller);
    final isAdmin = auth.has(Role.admin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оружейный магазин — каталог'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text('${user.fullName} · ${user.role.label}')),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _NavCard(
              icon: Icons.inventory_2_outlined,
              label: 'Оружие',
              onTap: () => context.go('/weapons'),
            ),
            _NavCard(
              icon: Icons.factory_outlined,
              label: 'Производители',
              onTap: () => context.go('/manufacturers'),
            ),
            _NavCard(
              icon: Icons.category_outlined,
              label: 'Категории',
              onTap: () => context.go('/categories'),
            ),
            _NavCard(
              icon: Icons.engineering_outlined,
              label: 'Конструкторы',
              onTap: () => context.go('/designers'),
            ),
            // Список всех покупателей — персональные данные, доступны
            // только сотрудникам магазина (продавец/администратор).
            if (isStaff)
              _NavCard(
                icon: Icons.people_outline,
                label: 'Покупатели',
                onTap: () => context.go('/clients'),
              ),
            _NavCard(
              icon: Icons.receipt_long_outlined,
              label: isStaff ? 'Заказы' : 'Мои заказы',
              onTap: () => context.go('/orders'),
            ),
            if (isAdmin)
              _NavCard(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Администрирование',
                onTap: () => context.go('/admin'),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 140,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 12),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
