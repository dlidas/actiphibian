import 'package:flutter/material.dart';
import 'collection.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                // Profile Banner
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 260,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            'assets/images/ProfileBanner.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    CircleAvatar(
                      radius: 70,
                      backgroundColor: const Color.fromARGB(255, 171, 228, 114),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color.fromARGB(255, 225, 249, 185),
                        child: const Icon(
                          Icons.person,
                          size: 75,
                          color: Color.fromARGB(255, 29, 59, 0),
                        ),
                      ),
                    ),
                  ],
                ),

                // Credentials
                const Column(
                  children: [
                    Text(
                      "Username",
                      style: TextStyle(
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Streak Box
                InkWell(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Center(
                      child: Text("Streak Heat Map",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stat Box
                Row(
                  children: [
                    const SizedBox(width: 10),

                    // Amphibian Collection Box
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CollectionPage(),
                            ),
                          );
                        },
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Center(
                            child: Text("Amphibian Collection",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 20),
              const SizedBox(width: 10),
            ],
          )
        ),
      ),
    );
  }
}