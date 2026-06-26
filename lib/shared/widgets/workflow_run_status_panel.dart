import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class WorkflowRunStatusPanel extends StatelessWidget {
  const WorkflowRunStatusPanel({
    super.key,
    this.limit = 8,
    this.eventIds,
    this.title = 'Recent Workflow Runs',
    this.subtitle =
        'Live state from workflow_runs across content, prediction, and automation lanes.',
    this.emptyStateText = 'No workflow runs recorded yet.',
  });

  final int limit;
  final Set<String>? eventIds;
  final String title;
  final String subtitle;
  final String emptyStateText;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('workflow_runs')
        .orderBy('updatedAt', descending: true)
        .limit(limit);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          final rawDocs = snapshot.data?.docs ?? const [];
          final docs = _filterDocs(rawDocs);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub, color: AppTheme.neonCyan, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: AppTheme.neonCyan),
                  ),
                )
              else if (snapshot.hasError)
                Text(
                  'Could not load workflow status: ${snapshot.error}',
                  style: const TextStyle(color: AppTheme.error, fontSize: 12),
                )
              else if (docs.isEmpty)
                Text(
                  emptyStateText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 18,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final workflowType =
                        data['workflowType']?.toString() ?? 'unknown';
                    final status = data['status']?.toString() ?? 'unknown';
                    final requestId =
                        data['requestId']?.toString() ?? docs[index].id;
                    final eventId = data['eventId']?.toString();
                    final updatedAt = _asDateTime(data['updatedAt']);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _statusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatWorkflowType(workflowType),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(
                                        status,
                                      ).withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: _statusColor(status),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Request ${_shortRequestId(requestId)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 12,
                                ),
                              ),
                              if (eventId != null && eventId.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Event $eventId',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              if (updatedAt != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    _formatDateTime(updatedAt),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final allowedEventIds = eventIds
        ?.where((id) => id.trim().isNotEmpty)
        .toSet();
    if (allowedEventIds == null || allowedEventIds.isEmpty) {
      return docs;
    }

    return docs
        .where((doc) {
          final eventId = doc.data()['eventId']?.toString();
          return eventId != null && allowedEventIds.contains(eventId);
        })
        .toList(growable: false);
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.neonGreen;
      case 'processing':
      case 'pending':
        return AppTheme.neonCyan;
      case 'failed':
      case 'error':
        return AppTheme.error;
      default:
        return Colors.white70;
    }
  }

  static String _shortRequestId(String requestId) {
    if (requestId.length <= 18) {
      return requestId;
    }
    return '${requestId.substring(0, 10)}...${requestId.substring(requestId.length - 6)}';
  }

  static String _formatWorkflowType(String workflowType) {
    return workflowType
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  static String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }
}
