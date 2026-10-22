import 'package:flutter/material.dart';

class SocialsPage extends StatelessWidget {
  const SocialsPage({super.key});

  @override
  Widget build(BuildContext context) {

    // Temp data
    final pondMates = ['Frog Knight', 'Amphibian Queen'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pond Mates'),
      ),

      body: ListView.builder(
        itemCount: pondMates.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(pondMates[index]),
            ),
          );
        },
      ),
    );
  }
}