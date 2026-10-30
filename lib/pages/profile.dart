import 'package:actiphibian/data/user_manager.dart';
import 'package:actiphibian/main.dart';
import 'package:actiphibian/widgets/pond_action_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:actiphibian/data/repo.dart';
import 'statistics.dart';
import 'socials.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final username = context.watch<UserManager>().user.username?.trim();

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 260,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/ProfileBanner.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: colors.primary,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: colors.secondary,
                      foregroundColor: colors.onSecondary,
                      child: const Icon(Icons.person, size: 75),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                username == null || username.isEmpty ? 'Pond friend' : username,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: FutureBuilder<int>(
                    future: LocalDb.getStreak(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('ERROR - Could Not Load Current Streak');
                      }
                      final currentStreak = snapshot.data ?? 0;
                      return Text(
                        'Current Streak: $currentStreak',
                        style: TextStyle(
                          fontSize: 18,
                          color: colors.onSecondary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PondActionCard(
                icon: Icons.insights_outlined,
                title: 'Statistics',
                subtitle: 'Review your progress and milestones.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const StatisticsPage(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PondActionCard(
                icon: Icons.pets_outlined,
                leading: Image.asset(
                  'assets/images/placeholder-frog-icon.png',
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                ),
                title: 'Amphibian Collection',
                subtitle: 'See the friends you have collected.',
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const MainPage(pageIndex: 3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PondActionCard(
                icon: Icons.people_outline,
                title: 'Socials',
                subtitle: 'Visit your social space.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const SocialsPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
