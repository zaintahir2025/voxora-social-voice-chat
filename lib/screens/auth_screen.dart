import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/voxora-mark.svg',
                              width: 38,
                              height: 38,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Voxora',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  Text(
                                    'Friends, posts, chat, calls, and games',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: true,
                              icon: Icon(Icons.login),
                              label: Text('Log in'),
                            ),
                            ButtonSegment(
                              value: false,
                              icon: Icon(Icons.person_add_alt_1),
                              label: Text('Sign up'),
                            ),
                          ],
                          selected: {_login},
                          onSelectionChanged: (value) => setState(() {
                            _login = value.first;
                            _error = '';
                          }),
                        ),
                        const SizedBox(height: 18),
                        if (!_login) ...[
                          _field(
                            _name,
                            'Display name',
                            Icons.person_outline,
                            validator: _minTwo,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            _handle,
                            'Handle',
                            Icons.alternate_email,
                            validator: _handleRule,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _field(
                          _email,
                          'Email',
                          Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => (value ?? '').contains('@')
                              ? null
                              : 'Enter a valid email.',
                        ),
                        const SizedBox(height: 12),
                        _field(
                          _password,
                          'Password',
                          Icons.lock_outline,
                          obscureText: !_showPassword,
                          suffix: IconButton(
                            tooltip: _showPassword
                                ? 'Hide password'
                                : 'Show password',
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (_login) {
                              return password.isEmpty
                                  ? 'Enter your password.'
                                  : null;
                            }
                            final strong = RegExp(
                              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{10,}$',
                            );
                            return strong.hasMatch(password)
                                ? null
                                : 'Use 10+ chars with upper, lower, number, and symbol.';
                          },
                        ),
                        if (!_login) ...[
                          const SizedBox(height: 12),
                          _field(_bio, 'Bio', Icons.info_outline, maxLines: 3),
                          const SizedBox(height: 12),
                          _field(
                            _interests,
                            'Interests',
                            Icons.interests_outlined,
                          ),
                        ],
                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: VoxoraColors.rose.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _error,
                              style: const TextStyle(color: VoxoraColors.rose),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _busy ? null : _submit,
                          icon: _busy
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : Icon(
                                  _login ? Icons.login : Icons.person_add_alt_1,
                                ),
                          label: Text(_login ? 'Log in' : 'Create account'),
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

  String? _minTwo(String? value) =>
      (value ?? '').trim().length < 2 ? 'Enter at least 2 characters.' : null;

  String? _handleRule(String? value) {
    final clean = (value ?? '').trim();
    if (clean.length < 3) return 'Enter at least 3 characters.';
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(clean)) {
      return 'Use letters, numbers, dots, dashes, or underscores.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = '';
    });
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
    setState(() {
      _busy = false;
      _error = error ?? '';
    });
  }
}
