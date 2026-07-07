import 'package:flutter/material.dart';

import 'package:datafightcentral/lib/features/ppv/services/ppv_access_service.dart';
import 'package:datafightcentral/lib/features/ppv/screens/ppv_live_watch_screen.dart';
import 'package:datafightcentral/lib/features/ppv/widgets/ppv_gate.dart';

/// PPVWatchGatekeeperScreen
///
/// Central entry for "Watch PPV".
/// Uses PPVAccessService to check entitlement.
///   - Entitled → PPVLiveWatchScreen (direct, no re-wrap)
///   - Not entitled → PpvGate (existing paywall + checkout)
///   - Error → retry UI
class PPVWatchGatekeeperScreen extends StatefulWidget {
  final String ppvId;
  final String userId;

  /// Injectable access service (for testing / DI).
  final PPVAccessService accessService;

  /// Optional callback when access is granted (analytics / logging).
  final void Function(String ppvId, String userId)? onAccessGranted;

  const PPVWatchGatekeeperScreen({
    super.key,
    required this.ppvId,
    required this.userId,
    required this.accessService,
    this.onAccessGranted,
  });

  @override
  State<PPVWatchGatekeeperScreen> createState() =>
      _PPVWatchGatekeeperScreenState();
}

class _PPVWatchGatekeeperScreenState extends State<PPVWatchGatekeeperScreen> {
  bool _loading = true;
  bool _hasAccess = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final hasAccess = await widget.accessService.hasAccessForUser(
        widget.userId,
        widget.ppvId,
      );

      if (!mounted) return;

      setState(() {
        _hasAccess = hasAccess;
        _loading = false;
      });

      if (hasAccess && widget.onAccessGranted != null) {
        widget.onAccessGranted!(widget.ppvId, widget.userId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1) Loading state
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2) Error state
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('PPV Watch')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Unable to check access for ${widget.ppvId}.'),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkAccess,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // 3) Entitled → go straight to live watch screen
    if (_hasAccess) {
      return PPVLiveWatchScreen(ppvId: widget.ppvId);
    }

    // 4) Not entitled → delegate to existing PpvGate (paywall + checkout)
    return PpvGate(
      ppvId: widget.ppvId,
      child: PPVLiveWatchScreen(ppvId: widget.ppvId),
    );
  }
}
