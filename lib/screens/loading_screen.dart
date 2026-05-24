import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/theme.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _fadeIn = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _scaleUp = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoxoraColors.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              VoxoraColors.primary.withValues(alpha: 0.08),
              VoxoraColors.bg,
              VoxoraColors.cyan.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Transform.scale(
              scale: _scaleUp.value,
              child: Opacity(
                opacity: _fadeIn.value,
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
                        boxShadow: [
                          BoxShadow(
                            color: VoxoraColors.primary.withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: SvgPicture.asset('assets/voxora-mark.svg',
                          width: 72, height: 72),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'VOXORA',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: VoxoraColors.text,
                                letterSpacing: 6,
                                fontSize: 28,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Talk. Play. Build.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: VoxoraColors.muted,
                            letterSpacing: 2,
                          ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor:
                              VoxoraColors.line.withValues(alpha: 0.3),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(VoxoraColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
