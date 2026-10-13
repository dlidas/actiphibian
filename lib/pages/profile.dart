import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ProfilePage(),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Icon(Icons.person, size: 100),

            const SizedBox(height: 20),

            //Credentials
            const Column(
              children: [
                Text(
                  "Username",
                  style: TextStyle(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  "Full name",
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            //Streak Box
            InkWell(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Center(
                  child: Text("Streak Heat Map"),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Link this box to the stat page ---
            //Stat Box
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Center(
                        child: Text("Statistics"),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // --- Link this box to the collection page ---
                // Amphibian Collection Box
                Expanded(
                  child: InkWell(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Center(
                        child: Text("Amphibian Collection"),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 20),

            //Socials
            InkWell(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 38, 90, 150),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Center(
                  child: Text("Socials"),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        )
      ),
    );
  }
}