import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC CONNECTIVITY BANNER — Offline/online status bar
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Drop into any Scaffold body as a top-level widget. Uses Firestore
/// connectivity check (no extra packages) — leverages the Firebase SDK
/// already in the project.
///
/// Usage:
///   Column(children: [
///     const DFCConnectivityBanner(),
///     Expanded(child: yourContent),
///   ])
///
/// Or wrap your Scaffold body:
///   DFCConnectivityWrapper(child: yourContent)
/// ═══════════════════════════════════════════════════════════════════════════

class DFCConnectivityBanner extends StatefulWidget {
  const DFCConnectivityBanner({super.key});

  @override
  State<DFCConnectivityBanner> createState() => _DFCConnectivityBannerState();
}

class _DFCConnectivityBannerState extends State<DFCConnectivityBanner>
    with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  bool _showBanner = false;
  Timer? _checkTimer;
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    // Check every 10 seconds
    _check();
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  Future<void> _check() async {
    try {
      // Lightweight Firestore read to test connectivity.
      // The doc may not exist — that's fine; if we reached the server
      // without a network exception, we are online.
      await FirebaseFirestore.instance
          .collection('_connectivity_check')
          .doc('ping')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      _setOnline();
    } on FirebaseException catch (e) {
      // permission-denied / not-found / unavailable codes that still
      // prove the server was reachable (not a network issue).
      if (e.code == 'permission-denied' ||
          e.code == 'not-found' ||
          e.code == 'unauthenticated') {
        _setOnline();
      } else {
        _setOffline();
      }
    } catch (_) {
      _setOffline();
    }
  }

  void _setOffline() {
    if (!mounted) return;
    if (!_isOffline) {
      setState(() {
        _isOffline = true;
        _showBanner = true;
      });
      _slideCtrl.forward();
    }
  }

  void _setOnline() {
    if (!mounted) return;
    if (_isOffline) {
      setState(() => _isOffline = false);
      // Show "back online" briefly then hide
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _slideCtrl.reverse().then((_) {
            if (mounted) setState(() => _showBanner = false);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: _isOffline
            ? DesignTokens.neonRed.withValues(alpha: 0.9)
            : DesignTokens.neonGreen.withValues(alpha: 0.9),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isOffline ? Icons.wifi_off : Icons.wifi,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _isOffline ? 'No internet connection' : 'Back online',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience wrapper — adds connectivity banner above any child widget
class DFCConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const DFCConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DFCConnectivityBanner(),
        Expanded(child: child),
      ],
    );
  }
}
