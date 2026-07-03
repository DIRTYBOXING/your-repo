import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: July 3, 2026\n\n'
              'Welcome to Data Fight Central. These terms and conditions outline the rules and regulations for the use of our application.\n\n'
              'By accessing this app we assume you accept these terms and conditions. Do not continue to use Data Fight Central if you do not agree to take all of the terms and conditions stated on this page.\n\n'
              '1. License to Use Application\n'
              'Unless otherwise stated, Data Fight Central and/or its licensors own the intellectual property rights for all material on Data Fight Central. All intellectual property rights are reserved...\n\n'
              '2. User Content\n'
              'In these terms and conditions, "your user content" means material (including without limitation text, images, audio material, video material and audio-visual material) that you submit to this application, for whatever purpose...\n\n'
              '[...Full Terms of Service text would go here...]',
            ),
          ],
        ),
      ),
    );
  }
}
