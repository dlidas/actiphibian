import 'package:actiphibian/data/userManager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Welcome, ${Provider.of<UserManager>(context).user.username}'),
    );
  }
}