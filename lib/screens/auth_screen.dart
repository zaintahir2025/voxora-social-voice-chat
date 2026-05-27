import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _handle = TextEditingController();
  final _bio = TextEditingController();
  final _interests = TextEditingController();

  bool _login = true;
  bool _busy = false;
  bool _showPassword = false;
  String _error = '';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _handle.dispose();
    _bio.dispose();
    _interests.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: VoxoraColors.darkSpace,
      body: Stack(
        children: [
          // Futuristic Background Gradients
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [VoxoraColors.neonPurple.withValues(alpha: 0.3), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [VoxoraColors.neonCyan.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    decoration: BoxDecoration(
                      color: VoxoraColors.darkPanel.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/voxora-mark.svg',
                                  width: 48,
                                  height: 48,
                                  colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'VOXORA',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'INITIALIZE NEURAL LINK',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                letterSpacing: 2,
                                color: scheme.primary.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 32),
                            SegmentedButton<bool>(
                              segments: [
                                ButtonSegment(
                                  value: true,
                                  label: Text('AUTHENTICATE', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                                ),
                                ButtonSegment(
                                  value: false,
                                  label: Text('REGISTER', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                                ),
                              ],
                              selected: {_login},
                              onSelectionChanged: (value) => setState(() {
                                _login = value.first;
                                _error = '';
                              }),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                  if (states.contains(WidgetState.selected)) return scheme.primary.withValues(alpha: 0.2);
                                  return Colors.transparent;
                                }),
                                side: WidgetStateProperty.all(BorderSide(color: scheme.primary)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (!_login) ...[
                              _field(_name, 'Display name', Icons.person_outline, validator: _minTwo),
                              const SizedBox(height: 16),
                              _field(_handle, 'Handle', Icons.alternate_email, validator: _handleRule),
                              const SizedBox(height: 16),
                            ],
                            _field(
                              _email,
                              'Email',
                              Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) => (value ?? '').contains('@') ? null : 'Enter a valid email.',
                            ),
                            const SizedBox(height: 16),
                            _field(
                              _password,
                              'Password',
                              Icons.lock_outline,
                              obscureText: !_showPassword,
                              suffix: IconButton(
                                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: scheme.primary),
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                              ),
                              validator: (value) {
                                final password = value ?? '';
                                if (_login) return password.isEmpty ? 'Enter your password.' : null;
                                final strong = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{10,}$');
                                return strong.hasMatch(password) ? null : 'Use 10+ chars with upper, lower, number, and symbol.';
                              },
                            ),
                            if (!_login) ...[
                              const SizedBox(height: 16),
                              _field(_bio, 'Bio', Icons.info_outline, maxLines: 3),
                              const SizedBox(height: 16),
                              _field(_interests, 'Interests', Icons.interests_outlined),
                            ],
                            if (_error.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: VoxoraColors.neonPink.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: VoxoraColors.neonPink),
                                ),
                                child: Text(_error, style: const TextStyle(color: VoxoraColors.neonPink)),
                              ),
                            ],
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _busy ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: scheme.primary,
                                foregroundColor: VoxoraColors.darkSpace,
                              ),
                              child: _busy
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: VoxoraColors.darkSpace))
                                  : Text(_login ? 'ACCESS SYSTEM' : 'CREATE PROTOCOL', style: const TextStyle(fontSize: 16, letterSpacing: 2)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextFormField _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: VoxoraColors.darkSpace.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }

  String? _minTwo(String? value) => (value ?? '').trim().length < 2 ? 'Enter at least 2 characters.' : null;

  String? _handleRule(String? value) {
    final clean = (value ?? '').trim();
    if (clean.length < 3) return 'Enter at least 3 characters.';
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(clean)) return 'Use letters, numbers, dots, dashes, or underscores.';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = ''; });
    final app = context.read<AppProvider>();
    final error = _login
        ? await app.signIn(email: _email.text, password: _password.text)
        : await app.signUp(
            email: _email.text,
            password: _password.text,
            fullName: _name.text,
            handle: _handle.text,
            bio: _bio.text,
            interests: _interests.text,
          );
    if (!mounted) return;
    setState(() { _busy = false; _error = error ?? ''; });
  }
}
