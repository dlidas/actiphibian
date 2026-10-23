import 'package:flutter/material.dart';
import '../widgets/user_stats_app_bar.dart';

//Preview of social page
class SocialsPage extends StatelessWidget {
  const SocialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    final pondMates = ['Frog Knight', 'Amphibian Queen'];

    return Scaffold(
      appBar: const UserStatsAppBar(title: 'Pond Mates'),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: pondMates.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person_outline),
            ),
            title: Text(
              pondMates[index],
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
