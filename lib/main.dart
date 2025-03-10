import 'package:eutar/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screen/home_screen.dart';
import 'screen/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of application.
  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = GoogleFonts.openSansTextTheme();

    final ThemeData theme = ThemeData(
      textTheme: textTheme,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eUTAR',
      theme: theme,
      home: LoginScreen(),
    );
  }
}


