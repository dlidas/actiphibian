import 'package:actiphibian/data/userManager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenFocus;

  const HomePage({
    super.key,
    required this.onOpenTasks,
    required this.onOpenFocus,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final username = context.watch<UserManager>().user.username?.trim() ?? '';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: colors.secondary,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.water, color: colors.onSecondary, size: 32),
                  const SizedBox(height: 18),
                  Text(
                    username.isEmpty
                        ? 'Welcome to your pond'
                        : 'Welcome, $username',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Small steps make a big splash. What would you like to do today?',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: colors.onSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Get started',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _HomeActionCard(
            icon: Icons.check_circle_outline,
            title: 'Plan your tasks',
            subtitle: 'See what needs doing and track your progress.',
            onTap: onOpenTasks,
          ),
          const SizedBox(height: 12),
          _HomeActionCard(
            icon: Icons.timer_outlined,
            title: 'Start a focus session',
            subtitle: 'Set a timer and make time for focused work.',
            onTap: onOpenFocus,
          ),
        ],
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colors.secondary,
          foregroundColor: colors.onSecondary,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
