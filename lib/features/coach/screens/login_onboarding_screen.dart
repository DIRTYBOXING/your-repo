import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/auth_service.dart';

class LoginOnboardingScreen extends StatefulWidget {
  const LoginOnboardingScreen({super.key});

  @override
  State<LoginOnboardingScreen> createState() => _LoginOnboardingScreenState();
}

class _LoginOnboardingScreenState extends State<LoginOnboardingScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleAuth(bool isLogin) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();

    final result = isLogin
        ? await auth.loginWithEmail(_emailCtrl.text, _passwordCtrl.text)
        : await auth.registerWithEmail(_emailCtrl.text, _passwordCtrl.text);

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        (user) async {
          if (!isLogin) {
            // Auto-complete onboarding to drop them straight into the platform
            await auth.completeOnboarding();
          }
          if (mounted) context.go('/admin-console');
        },
        (error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ENTER DFC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator(color: AppColors.neonCyan)
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _handleAuth(true),
                        child: const Text(
                          'LOGIN',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.neonCyan,
                          side: const BorderSide(color: AppColors.neonCyan),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _handleAuth(false),
                        child: const Text(
                          'REGISTER',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
