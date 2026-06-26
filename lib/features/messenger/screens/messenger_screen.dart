import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// DFC MessengerScreen — Redirects to the real DFC Messaging inbox.
class MessengerScreen extends StatefulWidget {
  const MessengerScreen({super.key});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/messaging');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF09111C),
                  AppTheme.primaryBackground,
                  Color(0xFF0A1D2B),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_rounded, color: AppTheme.neonCyan, size: 28),
                  SizedBox(height: 10),
                  Text(
                    'Opening DFC Messenger',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Loading inbox lanes, priority threads, and live conversation signals.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 14),
                  CircularProgressIndicator(color: AppTheme.neonCyan),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
