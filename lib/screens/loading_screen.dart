import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoxoraColors.darkSpace,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: VoxoraColors.neonCyan.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: SvgPicture.asset('assets/voxora-mark.svg', width: 80, height: 80, colorFilter: const ColorFilter.mode(VoxoraColors.neonCyan, BlendMode.srcIn)),
            ),
            const SizedBox(height: 30),
            Text(
              'V O X O R A',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 8,
                shadows: [
                  Shadow(
                    color: VoxoraColors.neonCyan.withValues(alpha: 0.8),
                    blurRadius: 10,
                  )
                ]
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'INITIALIZING NEURAL NETWORKS...',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: VoxoraColors.neonCyan.withValues(alpha: 0.8),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 4,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(VoxoraColors.neonCyan),
                    backgroundColor: VoxoraColors.darkBorder,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
