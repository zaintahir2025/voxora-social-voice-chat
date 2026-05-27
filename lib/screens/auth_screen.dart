import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

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
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, 10),
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
                        Image.asset(
                          Theme.of(context).brightness == Brightness.dark
                              ? 'assets/logo_dark.png'
                              : 'assets/logo_light.png',
                          width: 240,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Jump in and have fun!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('Log In')),
                            ButtonSegment(value: false, label: Text('Sign Up')),
                          ],
                          selected: {_login},
                          onSelectionChanged: (value) => setState(() {
                            _login = value.first;
                            _error = '';
                          }),
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
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: scheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: scheme.error),
                                const SizedBox(width: 12),
                                Expanded(child: Text(_error, style: TextStyle(color: scheme.error, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _busy ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: _busy
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                              : Text(_login ? 'Let\'s Go!' : 'Create Account', style: const TextStyle(fontSize: 20)),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
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
