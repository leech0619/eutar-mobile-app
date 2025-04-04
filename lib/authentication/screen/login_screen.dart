import 'package:flutter/material.dart';
import '../controller/login_controller.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController _controller = LoginController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {}); // Update the UI when the controller notifies listeners
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Login',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 80.0, 16.0, 16.0),
          child: Form(
            key: _controller.formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Image.asset(
                  'assets/icon/login_icon.png', // Replace with your app logo path
                  height: 200,
                ),
                const SizedBox(height: 30),
                // Email field with reserved space for error message
                Container(
                  height: 90, // Text field height + error message height
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _controller.emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: _controller.validateEmail,
                      ),
                      if (_controller.errorMessage != null &&
                          _controller.errorMessage!.contains('email'))
                        Text(
                          _controller.errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  height: 80, // Text field height + error message height
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _controller.passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: _controller.validatePassword,
                      ),
                      if (_controller.errorMessage != null &&
                          _controller.errorMessage!.contains('password'))
                        Text(
                          _controller.errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'First time user? Register',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _controller.resetPassword(context),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                Container(
                  height:
                      70, // Reserve space for the button and loading indicator
                  alignment: Alignment.center,
                  child:
                      _controller.isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15,
                              ),
                            ),
                            onPressed: () => _controller.login(context),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                ),
                const SizedBox(height: 10),

                // General Error Message
                if (_controller.errorMessage !=
                    null) // Display error message if it exists
                  Text(
                    _controller.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
