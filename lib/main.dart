import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/app_database.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FlashNoteApp()));
}

class FlashNoteApp extends ConsumerStatefulWidget {
  const FlashNoteApp({super.key});

  @override
  ConsumerState<FlashNoteApp> createState() => _FlashNoteAppState();
}

class _FlashNoteAppState extends ConsumerState<FlashNoteApp> {
  @override
  void initState() {
    super.initState();
    // Load theme mode from database after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = ref.read(appDatabaseProvider);
      ref.read(themeMode_Provider.notifier).load(db);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeMode_Provider);
    return MaterialApp.router(
      title: '闪记',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
