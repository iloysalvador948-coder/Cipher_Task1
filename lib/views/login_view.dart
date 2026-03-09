import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'register_view.dart';
import 'todo_list_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _otpCtrl  = TextEditingController();
  bool _obscure   = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().checkBiometricsAvailability();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  void _goTodos() => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TodoListView()));

  // ── Password login ─────────────────────────────────────────────────────────
  Future<void> _login() async {
    final auth = context.read<AuthViewModel>();
    auth.clearError();
    final ok = await auth.loginWithPassword(
        email: _email.text, password: _password.text);
    if (!mounted) return;
    if (ok) _goTodos(); else _snack(auth.error ?? 'Login failed');
  }

  // ── Google login ───────────────────────────────────────────────────────────
  Future<void> _googleLogin() async {
    final auth = context.read<AuthViewModel>();
    auth.clearError();
    final ok = await auth.beginGoogleLogin();
    if (!mounted) return;
    if (ok) _showGoogleOtpDialog();
    else if (auth.error != null) _snack(auth.error!);
  }

  void _showGoogleOtpDialog() {
    final auth  = context.read<AuthViewModel>();
    final email = auth.pendingGoogleEmail ?? '';
    final cs    = Theme.of(context).colorScheme;
    _otpCtrl.clear();

    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Image.network(
              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
              height: 24, width: 24,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.g_mobiledata_rounded, color: cs.secondary, size: 28),
            ),
            const SizedBox(width: 8),
            const Text('Verify Your Email'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('A 6-digit code was sent to:',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Text(email,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: cs.secondary)),
              const SizedBox(height: 4),
              const Text('Check your inbox (or debug console).',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller:   _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength:    6,
                textAlign:    TextAlign.center,
                autofocus:    true,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800,
                    letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  labelText:   '6-Digit OTP',
                  prefixIcon:  const Icon(Icons.key_outlined),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: cs.secondary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<AuthViewModel>().cancelGoogleOtp();
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: auth.isBusy
                  ? null
                  : () async {
                      await context.read<AuthViewModel>().beginGoogleLogin();
                      if (mounted) _snack('New OTP sent!');
                    },
              child: Text('Resend',
                  style: TextStyle(color: cs.secondary)),
            ),
            FilledButton(
              onPressed: auth.isBusy
                  ? null
                  : () async {
                      final vm  = context.read<AuthViewModel>();
                      final ok2 = await vm.confirmGoogleOtp(_otpCtrl.text);
                      if (!mounted) return;
                      if (ok2) { Navigator.pop(ctx); _goTodos(); }
                      else       _snack(vm.error ?? 'Invalid OTP');
                    },
              style: FilledButton.styleFrom(
                  backgroundColor: cs.secondary),
              child: auth.isBusy
                  ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Verify',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Biometric unlock ───────────────────────────────────────────────────────
  Future<void> _bioUnlock() async {
    final auth = context.read<AuthViewModel>();
    auth.clearError();
    final ok = await auth.unlockWithBiometrics();
    if (!mounted) return;
    if (ok) _goTodos(); else _snack(auth.error ?? 'Biometric failed');
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthViewModel>();
    final themeVm = context.watch<ThemeViewModel>();
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bioOk   = auth.biometricsChecked && auth.biometricsAvailable;
    final cs      = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(children: [
        // Background blobs
        Positioned(
          top: -80, right: -60,
          child: _Blob(
              color: cs.primary.withOpacity(isDark ? 0.25 : 0.12),
              size:  260),
        ),
        Positioned(
          bottom: -60, left: -40,
          child: _Blob(
              color: cs.secondary.withOpacity(isDark ? 0.20 : 0.10),
              size:  200),
        ),

        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Theme toggle
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined),
                        onPressed: themeVm.toggle,
                      ),
                    ),

                    // Logo
                    Center(
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [cs.primary, cs.secondary],
                            begin:  Alignment.topLeft,
                            end:    Alignment.bottomRight,
                          ),
                          boxShadow: [BoxShadow(
                            color:      cs.primary.withOpacity(0.4),
                            blurRadius: 20, spreadRadius: 2,
                          )],
                        ),
                        child: const Icon(Icons.shield_outlined,
                            size: 36, color: Colors.white),
                      ),
                    ).animate().scale(
                        duration: 500.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 16),
                    Text('CipherTask',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                fontWeight:    FontWeight.w900,
                                letterSpacing: 1.5))
                        .animate().fadeIn(delay: 100.ms),
                    Text('Your encrypted todo vault',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium)
                        .animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 32),

                    // Email
                    TextField(
                      controller:   _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText:  'Email',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 14),

                    // Password
                    TextField(
                      controller:  _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText:  'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 22),

                    // Sign In
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: auth.isBusy ? null : _login,
                        icon:  const Icon(Icons.login_rounded),
                        label: auth.isBusy
                            ? const SizedBox(
                                height: 18, width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Sign In'),
                      ),
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 12),

                    // OR divider
                    Row(children: [
                      Expanded(child: Divider(
                          color: isDark ? Colors.white24 : Colors.black26)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38,
                                fontSize: 13)),
                      ),
                      Expanded(child: Divider(
                          color: isDark ? Colors.white24 : Colors.black26)),
                    ]),

                    const SizedBox(height: 12),

                    // Google
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: auth.isBusy ? null : _googleLogin,
                        icon: Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          height: 18, width: 18,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata_rounded, size: 22),
                        ),
                        label: const Text('Continue with Google'),
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 10),

                    // Biometrics
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            (auth.isBusy || !bioOk) ? null : _bioUnlock,
                        icon:  const Icon(Icons.fingerprint_rounded),
                        label: Text(bioOk
                            ? 'Unlock with Fingerprint'
                            : 'Fingerprint not available'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              isDark ? Colors.white60 : Colors.black54,
                          side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.black26),
                        ),
                      ),
                    ).animate().fadeIn(delay: 440.ms),

                    const SizedBox(height: 20),

                    // Register link
                    Center(
                      child: TextButton(
                        onPressed: auth.isBusy
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const RegisterView())),
                        child: Text("Don't have an account? Create one",
                            style: TextStyle(color: cs.secondary)),
                      ),
                    ).animate().fadeIn(delay: 480.ms),

                    const SizedBox(height: 8),
                    Text(
                      'Auto-lock after ${Constants.inactivityTimeoutSeconds}s of inactivity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white24 : Colors.black26),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color; final double size;
  const _Blob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape:     BoxShape.circle,
          color:     color,
          boxShadow: [BoxShadow(color: color, blurRadius: size / 2)],
        ),
      );
}