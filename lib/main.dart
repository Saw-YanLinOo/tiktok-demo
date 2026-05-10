import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared/theme/app_theme.dart';
import 'shared/widgets/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load secrets from .env — keys are never hardcoded
  await dotenv.load(fileName: '.env');

  // Force portrait + full immersive dark status bar
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  runApp(
    // ProviderScope is required for Riverpod
    const ProviderScope(child: TikDemoApp()),
  );
}

class TikDemoApp extends StatelessWidget {
  const TikDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikDemo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}

