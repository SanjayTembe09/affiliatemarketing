import 'package:flutter/material.dart';
import 'auth_screen.dart'; // Ensure this points to your auth screen file

void main() {
  runApp(const NanoConnectApp());
}

class NanoConnectApp extends StatelessWidget {
  const NanoConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NanoConnect',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617),
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: Colors.lightBlue,
          secondary: Colors.purpleAccent,
          surface: Color(0xFF0F172A),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}