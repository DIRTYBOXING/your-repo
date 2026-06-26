import 'package:flutter/material.dart';

/// Accessible Outbox Screen for Handicapped Social Workflow
import 'services/message_service.dart';
import 'models/message_model.dart';

class HandicappedOutboxScreen extends StatefulWidget {
  const HandicappedOutboxScreen({super.key});
  @override
  State<HandicappedOutboxScreen> createState() =>
      _HandicappedOutboxScreenState();
}

class _HandicappedOutboxScreenState extends State<HandicappedOutboxScreen> {
  List<HandicappedMessage> _messages = [];
  bool _loading = true;
  final String _userId = 'user_basic'; // Replace with real user logic

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() => _loading = true);
    final messages = await HandicappedMessageService().fetchOutbox(_userId);
    setState(() {
      _messages = messages;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outbox', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.amber),
            tooltip: 'Search Sent',
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
                  if (_messages.isEmpty)
                    Card(
                      color: Colors.deepPurple.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: ListTile(
                        leading: const Icon(
                          Icons.send,
                          color: Colors.amber,
                          size: 32,
                        ),
                        title: const Text(
                          'No sent messages.',
                          style: TextStyle(color: Colors.amber, fontSize: 20),
                        ),
                        subtitle: const Text(
                          'Your outbox is empty.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.amber),
                          tooltip: 'Refresh',
                          onPressed: _fetchMessages,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return Card(
                            color: Colors.deepPurple.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(
                                Icons.send,
                                color: Colors.amber,
                                size: 32,
                              ),
                              title: Text(
                                msg.content,
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                'To: ${msg.receiverId} • ${msg.sentAt}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.amber,
                                ),
                                tooltip: 'Refresh',
                                onPressed: _fetchMessages,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file, color: Colors.black),
                    label: const Text(
                      'Attach File',
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
                        'Tap the refresh button to check for sent messages. Use search to find sent items.',
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
