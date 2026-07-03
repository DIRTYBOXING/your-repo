import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: July 3, 2026\n\n'
              'Data Fight Central operates the Data Fight Central mobile application. This page informs you of our policies regarding the collection, use, and disclosure of personal data when you use our Service and the choices you have associated with that data.\n\n'
              '1. Information Collection and Use\n'
              'We collect several different types of information for various purposes to provide and improve our Service to you. Types of Data Collected: Personal Data, Usage Data, Tracking & Cookies Data...\n\n'
              '2. Use of Data\n'
              'Data Fight Central uses the collected data for various purposes: To provide and maintain the Service, to notify you about changes to our Service, to allow you to participate in interactive features of our Service when you choose to do so...\n\n'
              '[...Full Privacy Policy text would go here...]',
            ),
          ],
        ),
      ),
    );
  }
}
