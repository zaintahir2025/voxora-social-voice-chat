import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../widgets/common_widgets.dart';

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
          email: _emailC.text.trim(),
          password: _passwordC.text,
        );
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
      body: VSpaceBackground(
        dense: true,
        child: SafeArea(
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: _heroBanner(context)),
                    SizedBox(width: 520, child: _authCard(context)),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _mobileHero(context),
                      const SizedBox(height: 22),
                      _authCard(context),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _heroBanner(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final headlineSize = compact ? 52.0 : 76.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 36 : 64,
            42,
            compact ? 28 : 46,
            54,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _brandPill(context),
              const Spacer(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: constraints.maxWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'BEYOND VOICE\nAND ( ITS )\nFAMILIAR BOUNDARIES',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontSize: headlineSize,
                              height: 1.02,
                              color: VoxoraColors.cream,
                            ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: compact ? 8 : 24,
                    top: compact ? 42 : 58,
                    child: Transform.rotate(
                      angle: -0.04,
                      child: Text(
                        'Live signal',
                        style: VoxoraTheme.condiment(
                          fontSize: compact ? 38 : 54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'A social voice system built for rooms, presence, and conversations that keep their shape.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: VoxoraColors.cream.withValues(alpha: 0.72),
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  _socialGlass(Icons.mail_outline),
                  const SizedBox(width: 12),
                  _socialGlass(Icons.alternate_email),
                  const SizedBox(width: 12),
                  _socialGlass(Icons.code),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mobileHero(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _brandPill(context),
      const SizedBox(height: 30),
      Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'BEYOND VOICE\nAND ( ITS )\nBOUNDARIES',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 40,
                  height: 1.05,
                  color: VoxoraColors.cream,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 6,
            child: Transform.rotate(
              angle: -0.05,
              child: Text(
                'Live signal',
                style: VoxoraTheme.condiment(fontSize: 32),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _brandPill(BuildContext context) => VLiquidGlass(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    borderRadius: BorderRadius.circular(999),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/voxora-mark.svg', width: 24, height: 24),
        const SizedBox(width: 10),
        Text(
          'VOXORA',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: VoxoraColors.cream,
            letterSpacing: 1.6,
          ),
        ),
      ],
    ),
  );

  Widget _socialGlass(IconData icon) => VLiquidGlass(
    padding: EdgeInsets.zero,
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      width: 56,
      height: 56,
      child: Icon(icon, color: VoxoraColors.cream, size: 20),
    ),
  );

  Widget _authCard(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 18 : 0, 0, isWide ? 42 : 0, 0),
          child: VLiquidGlass(
            padding: EdgeInsets.all(isWide ? 34 : 24),
            borderRadius: BorderRadius.circular(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isWide) ...[
                  SvgPicture.asset(
                    'assets/voxora-mark.svg',
                    width: 46,
                    height: 46,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'VOXORA',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Signal open',
                    style: VoxoraTheme.condiment(fontSize: 26),
                  ),
                  const SizedBox(height: 24),
                ],
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      _segmentButton(
                        'Sign up',
                        !_isLogin,
                        () => setState(() => _isLogin = false),
                      ),
                      _segmentButton(
                        'Log in',
                        _isLogin,
                        () => setState(() => _isLogin = true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!_isLogin) ...[
                        _field(
                          _nameC,
                          'Display name',
                          Icons.person_outline,
                          validator: (v) =>
                              (v?.length ?? 0) < 2 ? 'Too short' : null,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          _handleC,
                          'Handle',
                          Icons.alternate_email,
                          validator: (v) =>
                              (v?.length ?? 0) < 3 ? 'Too short' : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _field(
                        _emailC,
                        'Email',
                        Icons.email_outlined,
                        type: TextInputType.emailAddress,
                        validator: (v) => (v ?? '').contains('@')
                            ? null
                            : 'Enter a valid email',
                      ),
                      const SizedBox(height: 14),
                      _field(
                        _passwordC,
                        'Password',
                        Icons.lock_outline,
                        obscure: !_showPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                            color: VoxoraColors.muted,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                        validator: (v) {
                          final value = v ?? '';
                          if (_isLogin) {
                            return value.isEmpty ? 'Enter your password' : null;
                          }
                          final strongPassword = RegExp(
                            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{10,}$',
                          );
                          return strongPassword.hasMatch(value)
                              ? null
                              : 'Use 10+ chars with upper, lower, number, symbol';
                        },
                      ),
                      if (!_isLogin) ...[
                        const SizedBox(height: 14),
                        _field(
                          _bioC,
                          'Bio (optional)',
                          Icons.info_outline,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          _interestsC,
                          'Interests (comma-separated)',
                          Icons.interests_outlined,
                        ),
                      ],
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: VoxoraColors.danger.withValues(alpha: 0.1),
                            border: Border.all(
                              color: VoxoraColors.danger.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 18,
                                color: VoxoraColors.danger,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: const TextStyle(
                                    color: VoxoraColors.danger,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                                      strokeWidth: 2,
                                      color: VoxoraColors.bg,
                                    ),
                                  )
                                : Icon(
                                    _isLogin ? Icons.login : Icons.person_add,
                                    size: 18,
                                  ),
                            label: Text(
                              _busy
                                  ? 'Please wait...'
                                  : (_isLogin ? 'Log in' : 'Create account'),
                            ),
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
            borderRadius: BorderRadius.circular(999),
            gradient: active
                ? const LinearGradient(
                    colors: [VoxoraColors.neon, Color(0xFFD7FF7A)],
                  )
                : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: VoxoraColors.neon.withValues(alpha: 0.28),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: active ? VoxoraColors.bg : VoxoraColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
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
      style: const TextStyle(color: VoxoraColors.text, fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: label,
        hintText: label,
        prefixIcon: Icon(icon, size: 20, color: VoxoraColors.muted),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
