import 'package:flutter/material.dart';

import 'pages/auth/login_page.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomeScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
