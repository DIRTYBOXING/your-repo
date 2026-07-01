import 'package:flutter/material.dart';
import 'wearable_controller.dart';
import 'oauth_service.dart';
import 'api_service.dart';
import 'blue/controllers/health_document_controller.dart';
import 'blue/repositories/health_document_repository.dart';
import 'blue/state/health_document_state.dart';

class HealthIngestionScreen extends StatefulWidget {
  const HealthIngestionScreen({super.key});

  @override
  State<HealthIngestionScreen> createState() => _HealthIngestionScreenState();
}

class _HealthIngestionScreenState extends State<HealthIngestionScreen> {
  // Mock State
  bool _isOuraConnected = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  late final WearableController _wearableController;
  late final HealthDocumentController _documentController;

  @override
  void initState() {
    super.initState();
    _wearableController = WearableController(
      oauthService: OAuthWearableService(),
      apiService: ApiService(),
    );
    _documentController = HealthDocumentController(
      repository: HealthDocumentRepository(apiService: ApiService()),
    );
    _documentController.loadDocuments();
  }

  @override
  void dispose() {
    _wearableController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  void _simulateUpload(String filename, String docType) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.1;
    });

    for (int i = 2; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _uploadProgress = i / 10;
        });
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      // Trigger the V12 backend sync
      await _documentController.uploadDocument(filename, docType);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload Complete: $filename sent to AI Pipeline'),
          backgroundColor: Colors.greenAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: [
            const SizedBox(height: 32),

            // ─── 1. HEADER ───────────────────────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'HEALTH INGESTION',
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
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sync, color: Colors.blueAccent, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'SYNCING',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ─── 2. WEARABLE API INTEGRATIONS ────────────────────────────────
            _buildSectionHeader(
              Icons.watch,
              'BIOMETRIC STREAMS',
              Colors.cyanAccent,
            ),
            _DfcCard(
              height: 160,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ListenableBuilder(
                    listenable: _wearableController,
                    builder: (context, _) {
                      final state = _wearableController.state;
                      final isConnected =
                          state == WearableState.connected ||
                          state == WearableState.syncing ||
                          state == WearableState.authenticating;

                      String statusText = 'Disconnected';
                      if (state == WearableState.authenticating) {
                        statusText = 'Authenticating with Whoop...';
                      } else if (state == WearableState.syncing) {
                        statusText = 'Syncing telemetry...';
                      } else if (state == WearableState.connected) {
                        statusText = 'Connected (Last sync: Just now)';
                      } else if (state == WearableState.error) {
                        statusText = 'Connection Error';
                      }

                      return _buildWearableToggle(
                        name: 'WHOOP API (OAuth)',
                        status: statusText,
                        isActive: isConnected,
                        color: Colors.white,
                        onToggle: (val) {
                          if (val && state == WearableState.disconnected) {
                            _wearableController.connectWhoop();
                          } else if (val && state == WearableState.connected) {
                            _wearableController.syncData();
                          }
                        },
                      );
                    },
                  ),
                  const Divider(color: Colors.white10),
                  _buildWearableToggle(
                    name: 'OURA RING',
                    status: _isOuraConnected ? 'Connected' : 'Disconnected',
                    isActive: _isOuraConnected,
                    color: Colors.cyanAccent,
                    onToggle: (val) => setState(() => _isOuraConnected = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── 3. MEDICAL & DOCUMENT UPLOAD PIPELINE ───────────────────────
            _buildSectionHeader(
              Icons.upload_file,
              'SECURE MEDICAL UPLOAD',
              Colors.orangeAccent,
            ),
            _DfcCard(
              height: 200,
              glow: _isUploading,
              child: _isUploading
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'UPLOADING & ENCRYPTING...',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.white10,
                          color: Colors.orangeAccent,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${(_uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_upload,
                          color: Colors.white38,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Drag & drop medical files or tap to browse.',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildUploadButton(
                              'BLOODWORK',
                              Colors.redAccent,
                              () => _simulateUpload(
                                'Bloodwork_Q4.pdf',
                                'bloodwork',
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildUploadButton(
                              'MRI / SCANS',
                              Colors.blueAccent,
                              () => _simulateUpload(
                                'Left_Shoulder_MRI.pdf',
                                'scan',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // ─── 4. PROCESSING QUEUE / PIPELINE STATUS ───────────────────────
            _buildSectionHeader(
              Icons.memory,
              'AI PROCESSING QUEUE',
              Colors.purpleAccent,
            ),
            _DfcCard(
              height: 180,
              child: ListenableBuilder(
                listenable: _documentController,
                builder: (context, _) {
                  final state = _documentController.state;
                  if (state is HealthDocumentInitial ||
                      state is HealthDocumentLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.purpleAccent,
                      ),
                    );
                  }
                  if (state is HealthDocumentError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }
                  if (state is HealthDocumentLoaded) {
                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: state.documents.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final doc = state.documents[index];
                        Color statusColor = Colors.orangeAccent;
                        if (doc.progress >= 1.0) {
                          statusColor = Colors.greenAccent;
                        } else if (doc.progress >= 0.5)
                          statusColor = Colors.purpleAccent;

                        return _buildProcessingItem(
                          filename: doc.filename,
                          status: doc.status,
                          progress: doc.progress,
                          color: statusColor,
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWearableToggle({
    required String name,
    required String status,
    required bool isActive,
    required Color color,
    required ValueChanged<bool> onToggle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.fitness_center, color: color, size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                status,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
        Switch(
          value: isActive,
          onChanged: onToggle,
          activeThumbColor: color,
          activeTrackColor: color.withValues(alpha: 0.3),
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: Colors.white10,
        ),
      ],
    );
  }

  Widget _buildUploadButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildProcessingItem({
    required String filename,
    required String status,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                filename,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white10,
          color: color,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}

class _DfcCard extends StatelessWidget {
  final double height;
  final bool glow;
  final Widget child;

  const _DfcCard({
    required this.height,
    this.glow = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Colors.orangeAccent.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
