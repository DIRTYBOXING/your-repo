import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/services/auth_service.dart';

class SamuraiOwnerScreen extends StatelessWidget {
  const SamuraiOwnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Owner UIDs and admins go straight through
    if (!authService.isAdmin && !authService.isOwner) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('ACCESS DENIED'),
          backgroundColor: Colors.black,
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, color: Colors.redAccent, size: 64),
              SizedBox(height: 16),
              Text(
                'OWNER ACCESS REQUIRED',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final email = authService.currentUser?.email ?? 'unknown';
    final role = authService.userRole.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text('SAMURAI Command Center'),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.withValues(alpha: 0.15), Colors.black],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SAMURAI ENGINE STATUS',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'User: $email',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Role: $role',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ENGINE CONTROLS',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _ctrl(context, '🔥', 'Force Content Pump', Colors.orangeAccent),
          _ctrl(context, '🤖', 'Activate Swarm', Colors.cyanAccent),
          _ctrl(context, '📡', 'Broadcast Signal', Colors.greenAccent),
          _ctrl(context, '🧹', 'Clear All Caches', Colors.redAccent),
          _ctrl(context, '📊', 'Seed Demo Data', Colors.purpleAccent),
          const SizedBox(height: 24),
          const Text(
            'QUICK NAV',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _nav(
            context,
            Icons.publish,
            'Content Command Center',
            '/content-command-center',
            Colors.greenAccent,
          ),
          _nav(
            context,
            Icons.hive,
            'Swarm Dashboard',
            '/swarm-dashboard',
            Colors.cyanAccent,
          ),
          _nav(
            context,
            Icons.flash_on,
            'FightWire',
            '/fightwire',
            Colors.orangeAccent,
          ),
          _nav(context, Icons.event, 'Events', '/events', Colors.greenAccent),
          _nav(
            context,
            Icons.people,
            'Social Feed',
            '/social',
            Colors.cyanAccent,
          ),
          _nav(context, Icons.live_tv, 'PPV Hub', '/ppv', Colors.purpleAccent),
          _nav(
            context,
            Icons.domain_verification,
            'Approved Domains',
            '/admin/approved-domains',
            Colors.amberAccent,
          ),
        ],
      ),
    );
  }

  static Widget _ctrl(
    BuildContext context,
    String emoji,
    String title,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title activated!'),
              backgroundColor: Colors.green[800],
            ),
          );
        },
        tileColor: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        leading: Text(emoji, style: const TextStyle(fontSize: 22)),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: Icon(Icons.play_arrow, color: color, size: 20),
      ),
    );
  }

  static Widget _nav(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: () => context.push(route),
      dense: true,
    );
  }
}
