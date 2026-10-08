import 'package:flutter/material.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("Actiphibian"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 110.0),
              child: Center(
                child: Container(
                  width: 200,
                  height: 100,
                  child: Image.asset('assets/images/placeholder-frog-icon.png'),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 15),
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Username',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 15.0, 
                right: 15.0, 
                top: 15.0, 
                bottom: 0,
              ),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
              ),
            ),
            SizedBox(
              height: 65,
              width: 360,
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    child: Text(
                      'Log in',
                      style: TextStyle(
                        color: Color(0xFF1D3B00),
                        fontSize: 20,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (context) => const MainApp()),
                      );
                      print('Login successful.');
                    },
                  )
                ),
              ),
            ),
            SizedBox(
              height: 50,
            ),
            Container(
              child: Center(
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 62),
                      child: Text('Forgot password?'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 1.0),
                      child: InkWell(
                        onTap: () {
                          print('hello');
                        },
                        child: Text(
                          'Get help logging in',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}