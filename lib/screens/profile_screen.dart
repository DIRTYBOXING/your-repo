// lib/screens/profile_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_client.dart';

class ProfileScreen extends StatefulWidget {
  final ApiClient api;
  const ProfileScreen({required this.api, Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  final _nameController = TextEditingController();

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
    });
    final res = await widget.api.get('/api/v1/users/me');
    if (res.statusCode == 200) {
      _profile = Map<String, dynamic>.from(jsonDecode(res.body));
      _nameController.text = _profile?['displayName'] ?? '';
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    final payload = {'displayName': _nameController.text};
    await widget.api.put('/api/v1/users/me', payload);
    await _loadProfile();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
            const SizedBox(height: 20),
            if (_profile != null) Text('Email: ${_profile!['email'] ?? '—'}'),
          ],
        ),
      ),
    );
  }
}
