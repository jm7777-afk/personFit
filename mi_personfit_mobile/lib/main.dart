import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiPersonFitApp());
}

class MiPersonFitApp extends StatelessWidget {
  const MiPersonFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi PersonFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthScreen(),
    );
  }
}
