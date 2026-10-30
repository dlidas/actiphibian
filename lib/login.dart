import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/data/user_manager.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'models/user.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  String _username = '';
  bool _isSaving = false;

  bool get _canSubmit => _username.trim().isNotEmpty && !_isSaving;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _getStarted() async {
    if (!_canSubmit) return;
    setState(() => _isSaving = true);

    //Create user model with given username
    User user = User.newUser();
    user.username = _username.trim();

    //Update shared user
    Provider.of<UserManager>(context, listen: false).updateUser(user);

    //Save user to local db before the main page reads it
    try {
      await LocalDb.addUser(user);
    } catch (error, stackTrace) {
      debugPrint('Could not save the new user: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your name. Try again.')),
      );
      return;
    }
    if (!mounted) return;

    //Send to Home page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainApp()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("Actiphibian"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            //Icon
            Padding(
              padding: const EdgeInsets.only(top: 110.0),
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 100,
                  child: Image.asset('assets/images/placeholder-frog-icon.png'),
                ),
              ),
            ),

            //Welcome message
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 15),
              child: Text(
                'Welcome!',
                style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 50,
                      ),
              ),
            ),

            //Username input
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 15),
              child: TextField(
                controller: _usernameController,
                maxLength: 30,
                textInputAction: TextInputAction.done,
                onChanged: (value) => setState(() => _username = value),
                onSubmitted: (_) => _getStarted(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Username',
                  helperText: 'Enter a name to get started',
                ),
              ),
            ),

            //Login button
            SizedBox(
              height: 65,
              width: 360,
              child: SizedBox(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return Theme.of(context).colorScheme.primary.withAlpha(90);
                        }
                        if (states.contains(WidgetState.pressed)) {
                          return Theme.of(context).colorScheme.tertiary;
                        }
                        return Theme.of(context).colorScheme.primary;
                      }),
                    ),
                    onPressed: _canSubmit ? _getStarted : null,
                    child: Text(
                      'Get Started',
                      style: TextStyle(
                        color: Color(0xFF1D3B00),
                        fontSize: 20,
                      ),
                    ),
                  )
                ),
              ),
            ),

            //Spacing
            SizedBox(
              height: 50,
            ),
          ],
        ),
      ),
    );
  }
}