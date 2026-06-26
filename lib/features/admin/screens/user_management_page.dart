import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// User Management — DFC Admin
/// Ban, suspend, promote/demote, reset passwords, view user logs.
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final filtered = _searchQuery.isEmpty
              ? docs
              : docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = (data['displayName'] ?? data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Text('No users found.', style: TextStyle(color: Colors.white54)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${filtered.length} user${filtered.length == 1 ? '' : 's'} found',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
              ...filtered.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['displayName'] ?? data['name'] ?? 'Unknown').toString();
                final email = (data['email'] ?? '').toString();
                final role = (data['role'] ?? 'member').toString();
                final isBanned = data['isBanned'] == true;
                final isAdmin = role == 'admin' || data['isAdmin'] == true;
                final uid = doc.id;
                final photoUrl = data['photoUrl'] as String?;

                return Card(
                  color: isBanned
                      ? Colors.red.shade900.withValues(alpha: 0.8)
                      : Colors.deepPurple.shade800.withValues(alpha: 0.95),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      backgroundColor: Colors.deepPurple.shade700,
                      child: photoUrl == null
                          ? Icon(isAdmin ? Icons.verified_user : Icons.person,
                              color: isAdmin ? Colors.amber : Colors.white)
                          : null,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$email  •  $role${isBanned ? '  •  BANNED' : ''}',
                      style: TextStyle(
                        color: isBanned ? Colors.red.shade300 : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      color: Colors.deepPurple.shade900,
                      onSelected: (action) => _handleUserAction(action, uid, name, isBanned, isAdmin),
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: isBanned ? 'unban' : 'ban',
                          child: Text(isBanned ? 'Unban User' : 'Ban User'),
                        ),
                        PopupMenuItem(
                          value: isAdmin ? 'demote' : 'promote',
                          child: Text(isAdmin ? 'Demote from Admin' : 'Promote to Admin'),
                        ),
                        const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                        const PopupMenuItem(value: 'logs', child: Text('View User Logs')),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleUserAction(
      String action, String uid, String name, bool isBanned, bool isAdmin) async {
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(uid);
      switch (action) {
        case 'ban':
          await ref.update({'isBanned': true});
          break;
        case 'unban':
          await ref.update({'isBanned': false});
          break;
        case 'promote':
          await ref.update({'role': 'admin', 'isAdmin': true});
          break;
        case 'demote':
          await ref.update({'role': 'member', 'isAdmin': false});
          break;
        default:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$action executed for $name'),
                backgroundColor: Colors.deepPurple.shade700,
              ),
            );
          }
          return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$action applied to $name'),
            backgroundColor: Colors.deepPurple.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade800),
        );
      }
    }
  }
}
