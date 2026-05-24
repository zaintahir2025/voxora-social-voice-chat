import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/constants.dart';
import 'config/theme.dart';
import 'providers/app_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? startupError;
  if (isSupabaseConfigured) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey)
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      startupError = error;
    }
  }

  runApp(VoxoraApp(startupError: startupError));
}

class VoxoraApp extends StatelessWidget {
  const VoxoraApp({super.key, this.startupError});

  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    if (!isSupabaseConfigured || startupError != null) {
      return MaterialApp(
        title: 'Voxora',
        debugShowCheckedModeBanner: false,
        theme: VoxoraTheme.theme,
        home: SetupScreen(error: startupError?.toString()),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: MaterialApp(
        title: 'Voxora',
        debugShowCheckedModeBanner: false,
        theme: VoxoraTheme.theme,
        home: Consumer<AppProvider>(
          builder: (context, app, _) {
            if (app.loading) return const LoadingScreen();
            if (app.session == null || app.profile == null) return const AuthScreen();
            return const HomeScreen();
          },
        ),
      ),
    );
  }
}
