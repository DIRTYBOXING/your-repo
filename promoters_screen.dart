import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/promoter_providers.dart';

class PromotersScreen extends ConsumerWidget {
  const PromotersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotersAsync = ref.watch(promoterListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        title: const Text(
          'Promoters Manager',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF0A0E17),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: promotersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (promoters) {
          if (promoters.isEmpty) {
            return const Center(
              child: Text(
                'No promoters found. Add one to begin.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promoters.length,
            itemBuilder: (context, index) {
              final promoter = promoters[index];
              return Card(
                color: const Color(0xFF1A1C23),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.business_center,
                      color: Colors.amber,
                    ),
                  ),
                  title: Text(
                    promoter.companyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${promoter.name} • ${promoter.email}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
                  onTap: () {
                    // Future: Go to Promoter Edit Screen
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        onPressed: () {
          // Route into the unified onboarding sequence explicitly
          Navigator.pushNamed(context, '/promoter_onboarding');
        },
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Add Promoter',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
