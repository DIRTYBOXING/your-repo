import 'package:flutter/material.dart';
import '../models/moderation_item.dart';

class ModerationItemCard extends StatelessWidget {
  final ModerationItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onFlag;

  const ModerationItemCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
    required this.onFlag,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(item.content),
        subtitle: Text(
          'Type: ${item.type.name} | Submitted by: ${item.submittedBy}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: onApprove,
              tooltip: 'Approve',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onReject,
              tooltip: 'Reject',
            ),
            IconButton(
              icon: const Icon(Icons.flag),
              onPressed: onFlag,
              tooltip: 'Flag',
            ),
          ],
        ),
      ),
    );
  }
}
