import 'package:flutter/material.dart';
import 'api_service.dart';
import 'blue/controllers/moderation_controller.dart';
import 'blue/models/moderation_model.dart';
import 'blue/repositories/moderation_repository.dart';
import 'blue/state/moderation_state.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  late final ModerationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ModerationController(
      repo: ModerationRepository(api: ApiService()),
    )..loadReports();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAction(ReportModel report, String action) {
    _controller.resolve(report.id, action, report.targetId, report.type);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report ${report.id} marked as $action.'),
        backgroundColor: action == 'DISMISS'
            ? Colors.blueAccent
            : Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            // ─── HEADER ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'MODERATION QUEUE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'ACTION REQUIRED',
                      style: TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── REPORTS LIST ────────────────────────────────────────────────
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final state = _controller.state;

                  if (state is ModerationInitial ||
                      state is ModerationLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.purpleAccent,
                      ),
                    );
                  }

                  if (state is ModerationError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  if (state is ModerationLoaded) {
                    if (state.reports.isEmpty) {
                      return const Center(
                        child: Text(
                          'Queue is clear. Good job.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _controller.loadReports,
                      color: Colors.purpleAccent,
                      backgroundColor: const Color(0xFF0A0E17),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        itemCount: state.reports.length,
                        itemBuilder: (context, index) {
                          return _buildReportCard(state.reports[index]);
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TYPE: ${report.type}',
                style: const TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'REPORT ID: ${report.id}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.reason,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              report.contentPreview,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleAction(report, 'DISMISS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text('DISMISS'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAction(
                    report,
                    report.type == 'USER' ? 'BAN' : 'DELETE',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    report.type == 'USER' ? 'BAN USER' : 'DELETE CONTENT',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
