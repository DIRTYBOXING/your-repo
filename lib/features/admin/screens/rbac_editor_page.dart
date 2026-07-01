import 'package:flutter/material.dart';

/// Role-Based Access Control (RBAC) Editor — DFC Admin
/// Create/edit roles, assign granular permissions, and manage user-role assignments.
class RBACEditorPage extends StatelessWidget {
  const RBACEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample roles and permissions (replace with backend integration)
    final roles = [
      _Role('Owner', ['All']),
      _Role('Admin', ['User Management', 'Moderation', 'Settings']),
      _Role('Moderator', ['Moderation']),
      _Role('User', ['View', 'Post']),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Role & Permission Editor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Manage roles and permissions. Assign users to roles for granular access control.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...roles.map(
            (r) => Card(
              color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.security,
                  color: Colors.amber,
                  size: 32,
                ),
                title: Text(
                  r.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Permissions: ${r.permissions.join(', ')}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: Colors.deepPurple.shade900,
                        title: Text(
                          'Edit ${r.name}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          'Permissions: ${r.permissions.join(", ")}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${r.name} role updated'),
                                  backgroundColor: Colors.deepPurple.shade700,
                                ),
                              );
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade700,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add New Role'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.deepPurple.shade900,
                  title: const Text(
                    'Add New Role',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Enter role name and assign permissions.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New role created'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Role {
  final String name;
  final List<String> permissions;
  _Role(this.name, this.permissions);
}
