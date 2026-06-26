import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/account_recovery_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  ACCOUNT RECOVERY v1.0
//  Find My Account · Forgot Password · Forgot Email · Recovery
//  Facebook-style recovery flow with masked email reveal
// ═══════════════════════════════════════════════════════════════════

class AccountRecoveryScreen extends StatefulWidget {
  const AccountRecoveryScreen({super.key});

  @override
  State<AccountRecoveryScreen> createState() => _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends State<AccountRecoveryScreen> {
  final _controller = TextEditingController();
  String _mode = 'choose'; // 'choose', 'email', 'username', 'phone', 'result'
  String _resultMessage = '';
  String _resultMaskedEmail = '';
  bool _loading = false;
  bool _success = false;

  void _goBackSafely() {
    if (_mode != 'choose') {
      setState(() {
        _mode = 'choose';
        _resultMessage = '';
        _resultMaskedEmail = '';
        _controller.clear();
      });
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  Future<void> _recoverByEmail() async {
    final email = _controller.text.trim();
    if (email.isEmpty) return;

    setState(() => _loading = true);
    final svc = context.read<AccountRecoveryService>();
    final sent = await svc.sendPasswordReset(email);

    if (mounted) {
      setState(() {
        _loading = false;
        _mode = 'result';
        _success = sent;
        _resultMessage = sent
            ? 'If an account exists with that email, a password reset link has been sent. Check your inbox (and spam folder).'
            : svc.error ?? 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _recoverByUsername() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    setState(() => _loading = true);
    final svc = context.read<AccountRecoveryService>();
    final maskedEmail = await svc.findAccountByUsername(username);

    if (mounted) {
      setState(() {
        _loading = false;
        _mode = 'result';
        _success = maskedEmail != null;
        if (maskedEmail != null) {
          _resultMaskedEmail = maskedEmail;
          _resultMessage = 'We found your account. Your email is:';
        } else {
          _resultMessage = 'No account found with that username. Double-check the spelling and try again.';
        }
      });
    }
  }

  Future<void> _recoverByPhone() async {
    final phone = _controller.text.trim();
    if (phone.isEmpty) return;

    setState(() => _loading = true);
    final svc = context.read<AccountRecoveryService>();
    final maskedEmail = await svc.findAccountByPhone(phone);

    if (mounted) {
      setState(() {
        _loading = false;
        _mode = 'result';
        _success = maskedEmail != null;
        if (maskedEmail != null) {
          _resultMaskedEmail = maskedEmail;
          _resultMessage = 'We found your account. Your email is:';
        } else {
          _resultMessage = 'No account found with that recovery phone number.';
        }
      });
    }
  }

  Future<void> _sendResetToMasked() async {
    if (_resultMaskedEmail.isEmpty) return;

    setState(() => _loading = true);
    // The masked email view means we already found the account;
    // the service already logged the lookup, now send reset to the actual email
    // We use the original controller input to find and send
    final svc = context.read<AccountRecoveryService>();
    final email = _controller.text.trim();

    // Try sending reset via recovery email path
    final sent = await svc.sendResetToRecoveryEmail(email);

    if (mounted) {
      setState(() {
        _loading = false;
        _resultMessage = sent
            ? 'Password reset link sent to your email.'
            : 'We found your account but couldn\'t send the reset. Try the email recovery option instead.';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DesignTokens.neonAmber.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: _goBackSafely,
          ),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [DesignTokens.neonAmber, DesignTokens.neonCyan],
            ).createShader(r),
            child: const Text(
              'ACCOUNT RECOVERY',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_mode) {
      case 'email':
        return _buildInputMode(
          title: 'Reset Your Password',
          subtitle: 'Enter the email address associated with your account and we\'ll send you a link to reset your password.',
          hint: 'your@email.com',
          icon: Icons.email_outlined,
          inputType: TextInputType.emailAddress,
          buttonLabel: 'Send Reset Link',
          onSubmit: _recoverByEmail,
        );
      case 'username':
        return _buildInputMode(
          title: 'Find By Username',
          subtitle: 'Enter your DFC username or display name. We\'ll show you the masked email so you can recover access.',
          hint: 'username or display name',
          icon: Icons.alternate_email,
          inputType: TextInputType.text,
          buttonLabel: 'Find Account',
          onSubmit: _recoverByUsername,
        );
      case 'phone':
        return _buildInputMode(
          title: 'Find By Phone',
          subtitle: 'Enter the recovery phone number you set up in Security Settings. We\'ll find your account.',
          hint: '+61 4XX XXX XXX',
          icon: Icons.phone,
          inputType: TextInputType.phone,
          buttonLabel: 'Find Account',
          onSubmit: _recoverByPhone,
        );
      case 'result':
        return _buildResult();
      default:
        return _buildChooseMode();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  CHOOSE MODE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildChooseMode() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      children: [
        // Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonAmber.withValues(alpha: 0.08),
                DesignTokens.neonCyan.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DesignTokens.neonAmber.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.help_outline, color: DesignTokens.neonAmber, size: 28),
              ),
              const SizedBox(height: 14),
              const Text(
                'Trouble Logging In?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how you\'d like to recover access to your DataFight account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Recovery options
        _recoveryOption(
          icon: Icons.email_outlined,
          title: 'Password Reset via Email',
          subtitle: 'I know my email but forgot my password',
          color: DesignTokens.neonCyan,
          onTap: () => setState(() => _mode = 'email'),
        ),
        _recoveryOption(
          icon: Icons.alternate_email,
          title: 'Find Account by Username',
          subtitle: 'I remember my username but not my email',
          color: DesignTokens.neonGreen,
          onTap: () => setState(() => _mode = 'username'),
        ),
        _recoveryOption(
          icon: Icons.phone,
          title: 'Find Account by Phone',
          subtitle: 'I set up a recovery phone number',
          color: DesignTokens.neonAmber,
          onTap: () => setState(() => _mode = 'phone'),
        ),
        const SizedBox(height: 16),
        _recoveryOption(
          icon: Icons.email,
          title: 'Resend Verification Email',
          subtitle: 'I need to verify my email address',
          color: DesignTokens.neonMagenta,
          onTap: () async {
            final svc = context.read<AccountRecoveryService>();
            final sent = await svc.resendEmailVerification();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: DesignTokens.bgSecondary,
                  content: Text(
                    sent ? 'Verification email sent!' : (svc.error ?? 'Could not send'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _recoveryOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withValues(alpha: 0.08),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.15), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  INPUT MODE (email / username / phone)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInputMode({
    required String title,
    required String subtitle,
    required String hint,
    required IconData icon,
    required TextInputType inputType,
    required String buttonLabel,
    required VoidCallback onSubmit,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DesignTokens.neonCyan, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            keyboardType: inputType,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
              prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.2)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DesignTokens.neonCyan),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.15),
                foregroundColor: DesignTokens.neonCyan,
                side: const BorderSide(color: DesignTokens.neonCyan, width: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.neonCyan,
                      ),
                    )
                  : Text(
                      buttonLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  RESULT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildResult() {
    final color = _success ? DesignTokens.neonGreen : DesignTokens.neonRed;
    final icon = _success ? Icons.check_circle : Icons.error_outline;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            _resultMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (_resultMaskedEmail.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
              ),
              child: Text(
                _resultMaskedEmail,
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendResetToMasked,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.15),
                  foregroundColor: DesignTokens.neonCyan,
                  side: const BorderSide(color: DesignTokens.neonCyan, width: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.neonCyan),
                      )
                    : const Text(
                        'Send Password Reset to This Email',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => setState(() {
              _mode = 'choose';
              _resultMessage = '';
              _resultMaskedEmail = '';
              _controller.clear();
            }),
            child: const Text(
              'Try Another Method',
              style: TextStyle(color: DesignTokens.neonAmber, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
