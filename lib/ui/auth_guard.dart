// lib/ui/auth_guard.dart
import 'package:flutter/material.dart';
import '../../lib/shared/services/auth_service.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({Key? key, required this.child}) : super(key: key);

  Future<bool> _hasToken() async {
    final authService = AuthService();
    return authService.currentUser != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasToken(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data == true) return child;
        return Scaffold(
          appBar: AppBar(title: const Text('Sign In Required')),
          body: Center(child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Sign In'),
          )),
        );
      },
    );
  }
}
