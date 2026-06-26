import 'package:flutter/material.dart';

/// Accessible Friend/Group Management Screen
import 'services/friend_service.dart';
import 'models/friend_model.dart';

class HandicappedFriendGroupScreen extends StatefulWidget {
  const HandicappedFriendGroupScreen({super.key});
  @override
  State<HandicappedFriendGroupScreen> createState() =>
      _HandicappedFriendGroupScreenState();
}

class _HandicappedFriendGroupScreenState
    extends State<HandicappedFriendGroupScreen> {
  List<HandicappedFriend> _friends = [];
  bool _loading = true;
  final String _userId = 'user_basic'; // Replace with real user logic

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    setState(() => _loading = true);
    final friends = await HandicappedFriendService().fetchFriends(_userId);
    setState(() {
      _friends = friends;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends & Groups', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.amber),
            tooltip: 'Add Group',
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
            : Column(
                children: [
                  if (_friends.isEmpty)
                    Card(
                      color: Colors.deepPurple.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: ListTile(
                        leading: const Icon(
                          Icons.person_outline,
                          color: Colors.amber,
                          size: 32,
                        ),
                        title: const Text(
                          'No friends or groups yet.',
                          style: TextStyle(color: Colors.amber, fontSize: 20),
                        ),
                        subtitle: const Text(
                          'Add friends or create groups to start.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add, color: Colors.amber),
                          tooltip: 'Add Friend/Group',
                          onPressed: _fetchFriends,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          return Card(
                            color: Colors.deepPurple.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.amber,
                                size: 32,
                              ),
                              title: Text(
                                friend.name,
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                'ID: ${friend.id}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.amber,
                                ),
                                tooltip: 'Refresh',
                                onPressed: _fetchFriends,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.group, color: Colors.black),
                    label: const Text(
                      'Create Group',
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      minimumSize: const Size(200, 60),
                      textStyle: const TextStyle(fontSize: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.deepPurple.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: const ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: Colors.amber,
                      ),
                      title: Text(
                        'Tips',
                        style: TextStyle(color: Colors.amber, fontSize: 18),
                      ),
                      subtitle: Text(
                        'Tap the add button to invite friends or create new groups.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
