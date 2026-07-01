import 'package:flutter/material.dart';
import '../../../shared/services/email_campaign_service.dart'
    show EmailCampaignService;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// EmailCampaignDashboard — Admin UI for launching campaigns, reviewing stats, customizing content, and managing gym lists.
class EmailCampaignDashboard extends StatefulWidget {
  const EmailCampaignDashboard({super.key});

  @override
  State<EmailCampaignDashboard> createState() => _EmailCampaignDashboardState();
}

class _EmailCampaignDashboardState extends State<EmailCampaignDashboard> {
  final _service = EmailCampaignService();
  final _subjectController = TextEditingController(
    text:
        'Join the Ultimate Legends Movement — Elevate Your Gym, Fighters & Community!',
  );
  final _bodyController = TextEditingController(
    text: '''Dear Gym Owner,

We invite you to be part of the Ultimate Legends Championship Series — Australia & New Zealand’s premier combat sports platform. Whether your gym specializes in MMA, boxing, Muay Thai, kickboxing, jujitsu, or any martial art, Data Fight Central is your gateway to:

- National exposure for your fighters and gym
- Access to exclusive events, tournaments, and live streaming
- Opportunities for sponsorship, VIP tables, and community engagement
- Real-time performance analytics and digital marketing support
- Mentorship, youth programs, and mental health initiatives

Our mission: Empower every gym, coach, and athlete to reach new heights. Showcase your talent, connect with promoters, and join a movement that celebrates the spirit of combat sports.

Reply to this email or visit datafightcentral.com to register your gym and fighters for upcoming events.

Let’s build legends together!

Best regards,
Data Fight Central Team
noreply@datafightcentral.com''',
  );
  List<Map<String, String>> _gyms = [];
  String? _csvError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Campaigns'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Gym List (CSV)',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['csv'],
                      );
                  if (!mounted) return;
                  if (result != null && result.files.single.path != null) {
                    final file = File(result.files.single.path!);
                    try {
                      final csvContent = await file.readAsString();
                      if (!mounted) return;
                      final lines = csvContent.split('\n');
                      final header = lines.first.split(',');
                      setState(() {
                        _gyms = lines
                            .skip(1)
                            .where((line) => line.trim().isNotEmpty)
                            .map((line) {
                              final values = line.split(',');
                              return {
                                header[0]: values[0],
                                header[1]: values[1],
                              };
                            })
                            .toList();
                        _csvError = null;
                      });
                    } catch (e) {
                      if (!mounted) return;
                      setState(() {
                        _csvError = 'CSV parsing error.';
                      });
                    }
                  } else {
                    setState(() {
                      _csvError = 'No file selected.';
                    });
                  }
                },
                child: const Text('Upload CSV'),
              ),
              if (_csvError != null)
                Text(_csvError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              const Text(
                'Gyms in Australia & NZ:',
                style: TextStyle(color: Colors.amber),
              ),
              ..._gyms.map(
                (gym) => ListTile(
                  title: Text(
                    gym['Gym Name'] ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    gym['Email'] ?? '',
                    style: const TextStyle(color: Colors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  labelStyle: TextStyle(color: Colors.amber),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  labelStyle: TextStyle(color: Colors.amber),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 6,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  final recipients = _gyms
                      .where((gym) => (gym['Email'] ?? '').isNotEmpty)
                      .map(
                        (gym) => {
                          'email': gym['Email']!,
                          'name': gym['Gym Name'] ?? '',
                        },
                      )
                      .toList();
                  if (recipients.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No recipients. Upload a CSV first.'),
                      ),
                    );
                    return;
                  }
                  final result = await _service.sendCampaignEmail(
                    subject: _subjectController.text,
                    htmlBody: _bodyController.text,
                    recipients: recipients,
                  );
                  if (!context.mounted) return;
                  final ok = result['success'] == true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Campaign sent to ${result['sent']} recipients!'
                            : 'Send failed: ${result['error']}',
                      ),
                    ),
                  );
                },
                child: const Text('Send Campaign'),
              ),
              // Recipient management, analytics, delivery logs, opt-out controls pending
            ],
          ),
        ),
      ),
    );
  }
}
