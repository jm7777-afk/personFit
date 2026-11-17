import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KryonApp());
}

class KryonApp extends StatelessWidget {
  const KryonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kryon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
