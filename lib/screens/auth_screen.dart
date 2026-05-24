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

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = false;
  bool _busy = false;
  String _error = '';
  bool _showPassword = false;
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _nameC = TextEditingController();
  final _handleC = TextEditingController();
  final _bioC = TextEditingController();
  final _interestsC = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    _nameC.dispose();
    _handleC.dispose();
    _bioC.dispose();
    _interestsC.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    final app = context.read<AppProvider>();
    String? err;
    try {
      if (_isLogin) {
        err = await app.signIn(
            email: _emailC.text.trim(), password: _passwordC.text);
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
    if (mounted) {
      setState(() {
        _busy = false;
        _error = err ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: VoxoraColors.bg,
      body: isWide
          ? Row(children: [
              Expanded(child: _heroBanner(context)),
              SizedBox(width: 480, child: _authCard(context))
            ])
          : SingleChildScrollView(child: _authCard(context)),
    );
  }

  Widget _heroBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VoxoraColors.bg,
            VoxoraColors.primary.withValues(alpha: 0.12),
            VoxoraColors.cyan.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  VoxoraColors.primary.withValues(alpha: 0.2),
                  VoxoraColors.cyan.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: SvgPicture.asset('assets/voxora-mark.svg',
                width: 56, height: 56),
          ),
          const SizedBox(height: 32),
          Text(
            'VOXORA',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: VoxoraColors.primary, letterSpacing: 4),
          ),
          const SizedBox(height: 12),
          Text(
            'Step into rooms\nthat feel alive.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: VoxoraColors.text,
                  fontSize: 44,
                  height: 1.1,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'Real profiles, live rooms, private groups, and games\nin one free space.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: VoxoraColors.muted,
                  height: 1.7,
                ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _featureChip(Icons.radio, 'Voice Rooms'),
              _featureChip(Icons.chat_bubble_outline, 'Real-time Chat'),
              _featureChip(Icons.sports_esports, 'In-app Games'),
              _featureChip(Icons.people_outline, 'Social Network'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: VoxoraColors.surfaceLight,
          border: Border.all(color: VoxoraColors.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: VoxoraColors.cyan),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: VoxoraColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _authCard(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        constraints: const BoxConstraints(minHeight: 600),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: VoxoraColors.surface,
          border: Border(
            left: BorderSide(
                color: VoxoraColors.line,
                width: MediaQuery.of(context).size.width > 900 ? 1 : 0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (MediaQuery.of(context).size.width <= 900) ...[
              SvgPicture.asset('assets/voxora-mark.svg', width: 52, height: 52),
              const SizedBox(height: 16),
              Text('Voxora',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Talk. Play. Build.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 32),
            ],
            // Segmented control
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: VoxoraColors.line),
                borderRadius: BorderRadius.circular(12),
                color: VoxoraColors.surfaceLight,
              ),
              child: Row(children: [
                _segmentButton('Sign up', !_isLogin,
                    () => setState(() => _isLogin = false)),
                _segmentButton(
                    'Log in', _isLogin, () => setState(() => _isLogin = true)),
              ]),
            ),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (!_isLogin) ...[
                    _field(_nameC, 'Display name', Icons.person_outline,
                        validator: (v) =>
                            (v?.length ?? 0) < 2 ? 'Too short' : null),
                    const SizedBox(height: 14),
                    _field(_handleC, 'Handle', Icons.alternate_email,
                        validator: (v) =>
                            (v?.length ?? 0) < 3 ? 'Too short' : null),
                    const SizedBox(height: 14),
                  ],
                  _field(_emailC, 'Email', Icons.email_outlined,
                      type: TextInputType.emailAddress,
                      validator: (v) =>
                          (v ?? '').contains('@') ? null : 'Enter a valid email'),
                  const SizedBox(height: 14),
                  _field(
                      _passwordC, 'Password', Icons.lock_outline,
                      obscure: !_showPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                            color: VoxoraColors.muted),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                      validator: (v) => (v?.length ?? 0) < 8
                          ? 'At least 8 characters'
                          : null),
                  if (!_isLogin) ...[
                    const SizedBox(height: 14),
                    _field(_bioC, 'Bio (optional)', Icons.info_outline,
                        maxLines: 2),
                    const SizedBox(height: 14),
                    _field(_interestsC, 'Interests (comma-separated)',
                        Icons.interests_outlined),
                  ],
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: VoxoraColors.danger.withValues(alpha: 0.1),
                        border: Border.all(
                            color: VoxoraColors.danger.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline,
                            size: 18, color: VoxoraColors.danger),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_error,
                              style: const TextStyle(
                                  color: VoxoraColors.danger, fontSize: 13)),
                        ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: VoxoraTheme.gradientButtonDecoration,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _submit,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Icon(
                                _isLogin ? Icons.login : Icons.person_add,
                                size: 18),
                        label: Text(_busy
                            ? 'Please wait...'
                            : (_isLogin ? 'Log in' : 'Create account')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(0, 52),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: active
                ? const LinearGradient(
                    colors: [VoxoraColors.primary, VoxoraColors.coral])
                : null,
            boxShadow: active
                ? [
                    BoxShadow(
                        color: VoxoraColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8)
                  ]
                : null,
          ),
          child: Text(label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : VoxoraColors.muted,
              )),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: VoxoraColors.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: label,
        prefixIcon: Icon(icon, size: 20, color: VoxoraColors.muted),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
