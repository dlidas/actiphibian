import 'package:actiphibian/data/userManager.dart';
import 'package:actiphibian/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'statistics.dart';
import 'socials.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final userName = context.watch<UserManager>().user.username?.trim();
    final username = userName == null || userName.isEmpty
        ? 'Pond friend'
        : userName;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/ProfileBanner.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: colors.secondary,
                      child: Icon(
                        Icons.water,
                        size: 56,
                        color: colors.onSecondary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -32),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: colors.surface,
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: colors.secondary,
                            foregroundColor: colors.onSecondary,
                            child: const Icon(Icons.person, size: 38),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: Text(
                          username,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your pond',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _ProfileAction(
            icon: Icons.insights_outlined,
            title: 'Statistics',
            subtitle: 'Review your progress and milestones.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const StatisticsPage()),
            ),
          ),
          const SizedBox(height: 12),
          _ProfileAction(
            icon: Icons.pets_outlined,
            title: 'Amphibian collection',
            subtitle: 'See the friends you have collected.',
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const MainPage(pageIndex: 3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ProfileAction(
            icon: Icons.people_outline,
            title: 'Pond mates',
            subtitle: 'Visit your social space.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SocialsPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileAction({
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
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
