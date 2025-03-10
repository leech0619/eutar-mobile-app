import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          'Login',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
        child: Column(
          children: [
            // App logo
            Image.asset(
              'assets/icon/login_icon.png', // Replace with your app logo path
              height: 200,
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              onPressed: () {
                // Handle login logic here
              },
              child: Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    // Handle register logic here
                  },
                  child: Text(
                    'First time user? Register',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Handle forgot password logic here
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}