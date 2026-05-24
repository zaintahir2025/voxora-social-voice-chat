import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/theme.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoxoraColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      VoxoraColors.primary.withValues(alpha: 0.2),
                      VoxoraColors.cyan.withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: SvgPicture.asset('assets/voxora-mark.svg',
                    width: 64, height: 64),
              ),
              const SizedBox(height: 24),
              Text('Backend Configuration Required',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: VoxoraColors.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: VoxoraColors.surface,
                    border: Border.all(color: VoxoraColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pass SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define when running the app.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: VoxoraColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: VoxoraColors.surfaceLight,
                          border: Border.all(color: VoxoraColors.line),
                        ),
                        child: SelectableText(
                          'flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co '
                          '--dart-define=SUPABASE_ANON_KEY=your_key',
                          style: TextStyle(
                            color: VoxoraColors.cyan,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: VoxoraColors.danger.withValues(alpha: 0.1),
                            border: Border.all(color: VoxoraColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline, size: 18, color: VoxoraColors.danger),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Startup error: $error',
                                  style: const TextStyle(color: VoxoraColors.danger, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
