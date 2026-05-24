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
  bool _isLogin = false;
  bool _busy = false;
  String _error = '';
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _nameC = TextEditingController();
  final _handleC = TextEditingController();
  final _bioC = TextEditingController();
  final _interestsC = TextEditingController();

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    _nameC.dispose();
    _handleC.dispose();
    _bioC.dispose();
    _interestsC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = ''; });
    final app = context.read<AppProvider>();
    String? err;
    try {
      if (_isLogin) {
        err = await app.signIn(email: _emailC.text.trim(), password: _passwordC.text);
      } else {
        err = await app.signUp(
          email: _emailC.text.trim(),
          password: _passwordC.text,
          fullName: _nameC.text.trim(),
          handle: _handleC.text.trim(),
          bio: _bioC.text.trim(),
          interests: _interestsC.text.trim(),
        );
      }
    } catch (error) {
      err = error.toString();
    }
    if (mounted) setState(() { _busy = false; _error = err ?? ''; });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: isWide
          ? Row(children: [Expanded(child: _heroBanner(context)), SizedBox(width: 460, child: _authCard(context))])
          : SingleChildScrollView(child: _authCard(context)),
    );
  }

  Widget _heroBanner(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x6B0C0D18), Color(0x9E6C3CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset('assets/voxora-mark.svg', width: 78, height: 78),
          const SizedBox(height: 18),
          Text('VOXORA LIVE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text('Step into rooms\nthat feel alive.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white, fontSize: 48, height: 1.0,
            ),
          ),
          const SizedBox(height: 18),
          Text('Real profiles, live rooms, private groups, and games in one free space.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _authCard(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 600),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.94), const Color(0xFFF5F7FF).withValues(alpha: 0.9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Segmented control
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: VoxoraColors.line),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withValues(alpha: 0.68),
            ),
            child: Row(children: [
              _segmentButton('Sign up', !_isLogin, () => setState(() => _isLogin = false)),
              _segmentButton('Log in', _isLogin, () => setState(() => _isLogin = true)),
            ]),
          ),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: Column(
              children: [
                if (!_isLogin) ...[
                  _field(_nameC, 'Display name', validator: (v) => (v?.length ?? 0) < 2 ? 'Too short' : null),
                  const SizedBox(height: 14),
                  _field(_handleC, 'Handle', validator: (v) => (v?.length ?? 0) < 3 ? 'Too short' : null),
                  const SizedBox(height: 14),
                ],
                _field(_emailC, 'Email', type: TextInputType.emailAddress,
                  validator: (v) => (v ?? '').contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 14),
                _field(_passwordC, 'Password', obscure: true,
                  validator: (v) => (v?.length ?? 0) < 8 ? 'At least 8 characters' : null,
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 14),
                  _field(_bioC, 'Bio', maxLines: 3),
                  const SizedBox(height: 14),
                  _field(_interestsC, 'Interests (comma-separated)'),
                ],
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBFA),
                      border: Border.all(color: const Color(0xFFFECDCA)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error, style: const TextStyle(color: VoxoraColors.danger)),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: VoxoraTheme.gradientButtonDecoration,
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: Icon(_busy ? Icons.hourglass_empty : Icons.lock_outline, size: 18),
                      label: Text(_busy ? 'Please wait' : (_isLogin ? 'Log in' : 'Create account')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: active
                ? const LinearGradient(colors: [VoxoraColors.primary, VoxoraColors.cyan])
                : null,
          ),
          child: Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : VoxoraColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(labelText: label, hintText: label),
    );
  }
}
