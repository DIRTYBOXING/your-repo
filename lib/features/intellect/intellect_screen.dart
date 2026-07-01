import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class IntellectScreen extends StatelessWidget {
  const IntellectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DFC Intellect Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome to the Intellect Hub',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'DFC is more than fighting. Explore stock markets, sports science, climate action, community support, and solutions for addiction, violence, and more.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          const Card(
            color: Colors.yellowAccent,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Stock Markets & Financial Literacy'),
                  Text('• Sports Science & Performance'),
                  Text('• Saving the Planet & Climate Data'),
                  Text('• Community Projects & Volunteering'),
                  Text('• Help for Drugs, Alcohol, Gambling, Porn, Violence'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.purple[50],
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suicide, Mental, Physical & Financial Health',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Support is needed at any age, at any time.'),
                  Text(
                    '• Staying fit and strong—physically and mentally—helps you get through tough times.',
                  ),
                  Text(
                    '• You are not alone. Reach out for help, talk to someone, and keep moving forward.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '“You cannot be defeated by time if you keep your mind and body strong.”',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.lightbulb),
            label: const Text('Learn More & Get Help'),
            onPressed: () async {
              final uri = Uri.parse('https://www.beyondblue.org.au/');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Lifeline 13 11 14  |  Beyond Blue 1300 22 4636',
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
