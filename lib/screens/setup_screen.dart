import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/theme.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/voxora-mark.svg', width: 86, height: 86),
              const SizedBox(height: 18),
              Text('Backend configuration required',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Text(
                  'Pass SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define when running the app.\n\n'
                  'Example:\n'
                  'flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co '
                  '--dart-define=SUPABASE_ANON_KEY=your_key'
                  '${error == null ? '' : '\n\nStartup error: $error'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: VoxoraColors.muted),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
