import 'package:flutter/material.dart';
import 'creator_subscription_controller.dart';

class EntitlementGate extends StatelessWidget {
  final CreatorSubscriptionController controller;
  final String creatorId;
  final String scope; // e.g. "fighter:vault"
  final String? level;
  final Widget child;
  final VoidCallback onLockedTap;

  const EntitlementGate({
    super.key,
    required this.controller,
    required this.creatorId,
    required this.scope,
    this.level,
    required this.child,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    final has = controller.hasAccess(creatorId, scope, level: level);
    if (has) return child;

    return GestureDetector(
      onTap: onLockedTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent),
        ),
        child: const Center(child: Text("LOCKED • TAP TO UNLOCK", style: TextStyle(color: Colors.cyanAccent))),
      ),
    );
  }
}