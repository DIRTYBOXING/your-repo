import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../services/ppv_service.dart';

class PpvDetailScreen extends StatelessWidget {
  final String eventId;

  const PpvDetailScreen({super.key, required this.eventId});

  Future<void> _handleWatchPressed(BuildContext context) async {
    final service = PpvService();
    final result = await service.checkPpvAndEnter(eventId);

    if (result['allowed'] == true && result['streamUrl'] != null) {
      if (context.mounted) {
        context.push('/ppv-stream/$eventId');
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase required to watch.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Details: $eventId',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleWatchPressed(context),
                child: const Text('WATCH LIVE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
