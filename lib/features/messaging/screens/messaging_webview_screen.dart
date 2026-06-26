import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MessagingWebviewScreen extends StatelessWidget {
  const MessagingWebviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const messengerUrl = String.fromEnvironment(
      'MESSENGER_URL',
      defaultValue: 'https://messenger.datafightcentral.com',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('DFC Messenger'),
        backgroundColor: const Color(0xFF1A1A40),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Open DFC Messenger'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FFD0),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () async {
            final uri = Uri.parse(messengerUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }
}
