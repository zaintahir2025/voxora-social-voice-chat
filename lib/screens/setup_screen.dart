import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/theme.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth < 360 ? 16.0 : 24.0;
            final maxCardWidth = (constraints.maxWidth - padding * 2)
                .clamp(0.0, 640.0)
                .toDouble();
            final minContentHeight = (constraints.maxHeight - padding * 2)
                .clamp(0.0, double.infinity)
                .toDouble();

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minContentHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxCardWidth),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: EdgeInsets.all(
                          constraints.maxWidth < 420 ? 22 : 28,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/voxora-mark.svg',
                              width: 54,
                              height: 54,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Backend Configuration Required',
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Set your Supabase credentials with --dart-define before running the app.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                'flutter run\n'
                                '  --dart-define=SUPABASE_URL=https://x.co\n'
                                '  --dart-define=SUPABASE_ANON_KEY=your_key',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: VoxoraColors.rose.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Startup error: $error',
                                  style: const TextStyle(
                                    color: VoxoraColors.rose,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
