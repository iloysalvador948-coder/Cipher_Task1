import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();
  final _otp = TextEditingController();

  bool _otpStage = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _confirmPass.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _begin() async {
    final auth = context.read<AuthViewModel>();
    auth.clearError();

    // UI convenience check
    if (_pass.text != _confirmPass.text) {
      _snack('Passwords do not match.');
      return;
    }

    final ok = await auth.beginRegistration(
      email: _email.text,
      password: _pass.text,
      confirmPassword: _confirmPass.text,
    );

    if (!mounted) return;
    if (!ok) {
      _snack(auth.error ?? 'Registration failed');
      return;
    }

    setState(() => _otpStage = true);

    final otp = auth.otpForSimulation ?? '------';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('OTP (Simulation Only)'),
        content: Text(
          'This is a simulation.\n\nYour OTP code is:\n\n$otp\n\nType it in the OTP field to finish registration.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    final auth = context.read<AuthViewModel>();
    auth.clearError();

    final ok = await auth.confirmRegistrationOtpAndCreateUser(
      email: _email.text,
      password: _pass.text,
      otpInput: _otp.text,
    );

    if (!mounted) return;
    if (ok) {
      _snack('Account created! You can login now.');
      Navigator.pop(context);
    } else {
      _snack(auth.error ?? 'OTP failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Constants.dsBlack,
      appBar: AppBar(
        backgroundColor: Constants.dsBlack,
        foregroundColor: Colors.white,
        title: const Text('Register • CipherTask'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: Constants.dsCrimson.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _email,
                    enabled: !auth.isBusy && !_otpStage,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _pass,
                    enabled: !auth.isBusy && !_otpStage,
                    obscureText: _obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password (min 8 chars)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ✅ Confirm Password
                  TextField(
                    controller: _confirmPass,
                    enabled: !auth.isBusy && !_otpStage,
                    obscureText: _obscureConfirm,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Retype Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_otpStage) ...[
                    TextField(
                      controller: _otp,
                      enabled: !auth.isBusy,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'OTP (Simulation)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton(
                    onPressed: auth.isBusy
                        ? null
                        : _otpStage
                            ? _confirm
                            : _begin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.dsTeal,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: auth.isBusy
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_otpStage ? 'Confirm OTP & Create Account' : 'Generate OTP (Simulation)'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}