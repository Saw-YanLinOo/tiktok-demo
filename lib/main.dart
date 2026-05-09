import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/views/home_page.dart';
import 'features/live/views/featured_page.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/bottom_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load secrets from .env — keys are never hardcoded
  await dotenv.load(fileName: '.env');

  // Force portrait + full immersive dark status bar
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  runApp(
    // ProviderScope is required for Riverpod
    const ProviderScope(child: FlickoApp()),
  );
}

class FlickoApp extends StatelessWidget {
  const FlickoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flicko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _pages = [
    HomePage(),
    FeaturedPage(),
    SizedBox(), // create — out of scope
    SizedBox(), // messages — out of scope
    SizedBox(), // me — out of scope
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentTab,
        children: _pages,
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}
