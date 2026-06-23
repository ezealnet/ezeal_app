import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Services and config imports
import 'core/router/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // Ensure Flutter engine is initialized before calling platform services
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase from Environment Config
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Ezeal',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Supports responsive dark/light mode automatically
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
