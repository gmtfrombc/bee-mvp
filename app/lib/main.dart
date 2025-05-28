import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/momentum/presentation/screens/momentum_screen.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: BEEApp()));
}

class BEEApp extends StatelessWidget {
  const BEEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BEE Momentum Meter',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MomentumScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
