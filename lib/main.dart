import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/constants.dart';
import 'config/theme.dart';
import 'providers/app_provider.dart';
import 'providers/bot_game_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? startupError;
  if (isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      ).timeout(const Duration(seconds: 10));
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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => BotGameProvider()),
      ],
      child: MaterialApp(
        title: 'Voxora',
        debugShowCheckedModeBanner: false,
        theme: VoxoraTheme.theme,
        home: Consumer<AppProvider>(
          builder: (context, app, _) {
            if (app.loading) return const LoadingScreen();
            if (app.session != null &&
                app.profile == null &&
                app.dataError.isNotEmpty) {
              return _DataErrorScreen(error: app.dataError);
            }
            if (app.session == null || app.profile == null) {
              return const AuthScreen();
            }
            return const HomeScreen();
          },
        ),
      ),
    );
  }
}

class _DataErrorScreen extends StatelessWidget {
  const _DataErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();

    return Scaffold(
      backgroundColor: VoxoraColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  color: VoxoraColors.danger,
                  size: 48,
                ),
                const SizedBox(height: 18),
                Text(
                  'Could not load your workspace',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final userId = app.session?.user.id;
                        if (userId != null) {
                          app.loadAppData(userId);
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                    OutlinedButton.icon(
                      onPressed: app.signOut,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
