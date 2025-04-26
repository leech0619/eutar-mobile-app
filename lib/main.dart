import 'package:eutar/home/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'authentication/screen/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add error handling for dotenv loading
  try {
    await dotenv.load(fileName: ".env");
    print("Successfully loaded .env file with keys: ${dotenv.env.keys}");
  } catch (e) {
    print("Error loading .env file: $e");
    // Continue execution even if .env fails to load
  }
  
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = GoogleFonts.openSansTextTheme();

    final ThemeData theme = ThemeData(
      textTheme: textTheme,
      primaryColor: Colors.blue,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eUTAR',
      theme: theme,
      home:
          const AuthWrapper(), // Use AuthWrapper to determine the initial screen
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _checkLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false; // Check the login state
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData && snapshot.data == true) {
          return const HomeScreen(); // Navigate to HomeScreen if logged in
        } else {
          return const LoginScreen(); // Navigate to LoginScreen if not logged in
        }
      },
    );
  }
}
