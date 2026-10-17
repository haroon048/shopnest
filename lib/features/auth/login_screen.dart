import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shopnest/features/auth/signup.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'auth_provider.dart';

// Animated login: swinging lamp + animated text fields (floating label,
// focus glow, icon light-up) + role based routing.
class LoginScreen extends StatefulWidget {
  final String? role; // 'admin' ya 'customer' (route se null bhi aa sakta hai)
  final bool hideSignUp;
  const LoginScreen({super.key, this.role, this.hideSignUp = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;

  // Route se role null aaye to default customer
  String get _role => widget.role ?? 'customer';

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your email.';
    if (!v.contains('@')) return 'Please enter a valid email address.';
    return null;
  }

  String? _passValidator(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your password.';
    if (v.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('user-not-found') ||
        msg.contains('wrong-password') ||
        msg.contains('invalid-credential')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('network')) {
      return 'No internet connection. Please check and retry.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final ok = await context.read<AuthProvider>().signIn(
            _email.text.trim(),
            _pass.text.trim(),
            expectedRole: _role,
          );
      if (!mounted) return;
      // FIX: fail hone par Home par mat jao — provider ka error dikhao
      if (!ok) {
        final msg = context.read<AuthProvider>().error ??
            'Login failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        return;
      }
      final isAdmin = context.read<AuthProvider>().isAdmin;
      Navigator.pushNamedAndRemoveUntil(
        context,
        isAdmin ? AppRoutes.adminMain : AppRoutes.main,
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final ok = await context.read<AuthProvider>().signInWithGoogle(
            expectedRole: _role,
          );
      if (!mounted) return;
      // FIX: cancel/fail hone par Home par mat jao — provider ka error dikhao
      if (!ok) {
        final msg = context.read<AuthProvider>().error;
        // User ne popup cancel kiya to khamoshi se wapas (koi error nahi)
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
        return;
      }
      final isAdmin = context.read<AuthProvider>().isAdmin;
      Navigator.pushNamedAndRemoveUntil(
        context,
        isAdmin ? AppRoutes.adminMain : AppRoutes.main,
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ambientOrbs(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LampHeader(),
                    _pulsingLogo(),
                    const SizedBox(height: 18),
                    Text('Welcome Back',
                            style: AppTextStyles.heading.copyWith(fontSize: 28),
                            textAlign: TextAlign.center)
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 500.ms)
                        .slideY(
                            begin: 0.3,
                            end: 0,
                            delay: 500.ms,
                            duration: 500.ms),
                    const SizedBox(height: 8),
                    Text('Log in to continue shopping.',
                            style: AppTextStyles.caption.copyWith(fontSize: 14),
                            textAlign: TextAlign.center)
                        .animate()
                        .fadeIn(delay: 650.ms, duration: 500.ms),
                    const SizedBox(height: 30),
                    _AnimatedField(
                      controller: _email,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _emailValidator,
                    ).animate().fadeIn(delay: 750.ms, duration: 450.ms).slideX(
                        begin: 0.15, end: 0, delay: 750.ms, duration: 450.ms),
                    const SizedBox(height: 16),
                    _AnimatedField(
                      controller: _pass,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _signIn(),
                      validator: _passValidator,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ).animate().fadeIn(delay: 850.ms, duration: 450.ms).slideX(
                        begin: 0.15, end: 0, delay: 850.ms, duration: 450.ms),
                    const SizedBox(height: 30),
                    _gradientButton(
                      label: 'Log In',
                      loading: _loading,
                      onTap: _loading ? null : _signIn,
                    ).animate().fadeIn(delay: 950.ms, duration: 450.ms).scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                        delay: 950.ms,
                        duration: 450.ms,
                        curve: Curves.easeOutBack),
                    const SizedBox(height: 22),
                    _orDivider()
                        .animate()
                        .fadeIn(delay: 1050.ms, duration: 400.ms),
                    const SizedBox(height: 22),
                    _googleButton()
                        .animate()
                        .fadeIn(delay: 1100.ms, duration: 450.ms),
                    if (!widget.hideSignUp) ...[
                      const SizedBox(height: 26),
                      _signupLink()
                          .animate()
                          .fadeIn(delay: 1200.ms, duration: 400.ms),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Halke tairte hue glows ----------
  Widget _ambientOrbs() {
    return Stack(
      children: [
        Positioned(
          top: 120,
          right: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryViolet.withValues(alpha: 0.10),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(
              begin: const Offset(0.12, 0.12),
              end: const Offset(-0.12, -0.1),
              duration: 7000.ms,
              curve: Curves.easeInOut),
        ),
        Positioned(
          bottom: 40,
          left: -70,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.07),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(
              begin: const Offset(-0.1, -0.1),
              end: const Offset(0.12, 0.12),
              duration: 8000.ms,
              curve: Curves.easeInOut),
        ),
      ],
    );
  }

  // ---------- Logo jo halki saans leta hai ----------
  Widget _pulsingLogo() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryViolet.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
          ),
          child: Image.asset(
            'assets/images/logo/logo.png',
            width: 52,
            height: 52,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primaryViolet,
              size: 52,
            ),
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.06, 1.06),
          duration: 2000.ms,
          curve: Curves.easeInOut),
    );
  }

  // ---------- Gradient button ----------
  Widget _gradientButton({
    required String label,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryViolet.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _orDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('OR',
              style: AppTextStyles.caption
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
      ],
    );
  }

  // ---------- Google button ----------
  Widget _googleButton() {
    return GestureDetector(
      onTap: _googleLoading ? null : _googleSignIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surface.withValues(alpha: 0.7),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Center(
          child: _googleLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryViolet,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/icons/google.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.g_mobiledata,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Continue with Google',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _signupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ",
            style: AppTextStyles.caption.copyWith(fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SignupScreen()),
          ),
          child: const Text('Sign Up',
              style: TextStyle(
                  color: AppColors.primaryPink,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ============================================================
// VIDEO-STYLE ANIMATED TEXT FIELD
// Floating label + focus glow + icon light-up + animated border
// ============================================================
class _AnimatedField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const _AnimatedField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  void _onFocusChange() => setState(() => _focused = _focus.hasFocus);
  void _onTextChange() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Label upar tairta hai jab focus ho ya text likha ho
    final active = _focused || widget.controller.text.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.surface.withValues(alpha: 0.7),
        border: Border.all(
          color: _focused
              ? AppColors.primaryViolet
              : Colors.white.withValues(alpha: 0.10),
          width: _focused ? 1.6 : 1,
        ),
        // Focus par roshni ka glow
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primaryViolet.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppColors.primaryPink.withValues(alpha: 0.15),
                  blurRadius: 32,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 8),
          // Icon jo focus par roshan hota hai
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _focused ? AppColors.primaryGradient : null,
              color: _focused ? null : Colors.white.withValues(alpha: 0.06),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AppColors.primaryViolet.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _focused ? Colors.white : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Stack(
              children: [
                TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: widget.onSubmitted,
                  validator: widget.validator,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: AppColors.primaryViolet,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(8, 30, 8, 12),
                  ),
                ),
                // Tairta hua label
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  left: 8,
                  top: active ? 8 : 21,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    style: TextStyle(
                      color: _focused
                          ? AppColors.primaryViolet
                          : AppColors.textMuted,
                      fontSize: active ? 11 : 15,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: active ? 0.5 : 0,
                    ),
                    child: Text(widget.label),
                  ),
                ),
              ],
            ),
          ),
          if (widget.suffix != null) widget.suffix!,
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

// ============================================================
// SWINGING LAMP HEADER (CustomPainter se bana hua)
// ============================================================
class _LampHeader extends StatefulWidget {
  const _LampHeader();

  @override
  State<_LampHeader> createState() => _LampHeaderState();
}

class _LampHeaderState extends State<_LampHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swing;
  late final Animation<double> _angle;

  @override
  void initState() {
    super.initState();
    // Halka jhoolna: aage-peeche loop
    _swing = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _angle = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(parent: _swing, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _angle,
        builder: (context, _) => Transform.rotate(
          // Pivot upar: jahan cord laga hai
          angle: _angle.value,
          alignment: Alignment.topCenter,
          child: const CustomPaint(
            painter: _LampPainter(),
            child: SizedBox.expand(),
          ),
        ),
      ),
    )
        // Screen khulne par lamp upar se neeche aata hai
        .animate()
        .slideY(
            begin: -1.2, end: 0, duration: 900.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 600.ms);
  }
}

// Lamp: cord + shade + bulb + roshni ka cone (sab code se draw)
class _LampPainter extends CustomPainter {
  const _LampPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 1. Cord (upar se latki hui taar)
    canvas.drawLine(
      Offset(cx, 0),
      Offset(cx, h * 0.16),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 3,
    );

    // 2. Shade (ulti balti jaisi shape, gradient)
    final shadeTop = h * 0.16;
    final shadeBottom = h * 0.34;
    final shadePath = Path()
      ..moveTo(cx - 26, shadeTop)
      ..lineTo(cx + 26, shadeTop)
      ..lineTo(cx + 60, shadeBottom)
      ..lineTo(cx - 60, shadeBottom)
      ..close();
    canvas.drawPath(
      shadePath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(
            Rect.fromLTWH(cx - 60, shadeTop, 120, shadeBottom - shadeTop)),
    );

    // 3. Bulb ka glow
    final bulbY = shadeBottom + 14;
    canvas.drawCircle(
      Offset(cx, bulbY),
      62,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF0ABFC).withValues(alpha: 0.85),
            const Color(0xFFEC4899).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, bulbY), radius: 62)),
    );

    // 4. Bulb
    canvas.drawCircle(
      Offset(cx, bulbY),
      12,
      Paint()..color = const Color(0xFFFDE68A),
    );

    // 5. Roshni ka cone (neeche khulta hua, halka hota hua)
    final conePath = Path()
      ..moveTo(cx - 38, bulbY)
      ..lineTo(cx + 38, bulbY)
      ..lineTo(cx + 130, h)
      ..lineTo(cx - 130, h)
      ..close();
    canvas.drawPath(
      conePath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFA855F7).withValues(alpha: 0.35),
            const Color(0xFFEC4899).withValues(alpha: 0.12),
            const Color(0xFFEC4899).withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(cx - 130, bulbY, 260, h - bulbY)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
