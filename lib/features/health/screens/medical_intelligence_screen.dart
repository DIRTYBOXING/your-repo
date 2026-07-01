import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/design_tokens.dart';

/// Personal Medical Intelligence Companion
/// Not a medical device or authority.
class MedicalIntelligenceScreen extends StatefulWidget {
  const MedicalIntelligenceScreen({super.key});

  @override
  State<MedicalIntelligenceScreen> createState() =>
      _MedicalIntelligenceScreenState();
}

class _MedicalIntelligenceScreenState extends State<MedicalIntelligenceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Medical Intelligence',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: DesignTokens.spacingXL),
              _buildBodyAndScansRow(),
              const SizedBox(height: DesignTokens.spacingXL),
              _buildInjuryLogSection(),
              const SizedBox(height: DesignTokens.spacingXL),
              _buildAgeTimeline(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DesignTokens.neonMagenta,
        onPressed: _showAddInjurySheet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log Pain / Injury'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SamurAI Medical Companion',
            style: TextStyle(
              color: Colors.white,
              fontSize: DesignTokens.fontSizeTitleLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Personal injury log, scans diary, and recovery keys. '
            'This is not medical advice — it helps you remember '
            'what doctors, nurses and your own body are telling you.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: DesignTokens.fontSizeSubtitleLarge,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyAndScansRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;
        final children = <Widget>[
          Expanded(flex: 3, child: _buildBodyMapCard()),
          const SizedBox(
            width: DesignTokens.spacingL,
            height: DesignTokens.spacingL,
          ),
          Expanded(flex: 2, child: _buildScansSummaryCard()),
        ];
        return isWide ? Row(children: children) : Column(children: children);
      },
    );
  }

  Widget _buildBodyMapCard() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.4),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Holographic Body Map',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a zone to log pain, surgery, scans or rehab.',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeSubtitle,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),
          AspectRatio(
            aspectRatio: 3 / 5,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, _) {
                return CustomPaint(
                  painter: _BodyMapPainter(pulse: _pulseAnim.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScansSummaryCard() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.4),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scans & Blood Work Diary',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'X-ray, MRI, CT, ECG, EEG, blood tests and blood pressure. '
            'Use this as a checklist before and after appointments.',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeSubtitle,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          _buildScanBullet(
            'Today',
            'Prepare questions for your doctor and note symptoms.',
          ),
          _buildScanBullet(
            'After Results',
            'Record what they say in your own words.',
          ),
          _buildScanBullet(
            'SamurAI Notes',
            'Write what actually helps: sleep, meds, stretching, food.',
          ),
          const SizedBox(height: DesignTokens.spacingL),
          if (user != null)
            Text(
              'Linked to your DFC profile: ${user.uid.substring(0, 6)}...',
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeCaption,
              ),
            )
          else
            const Text(
              'Log in to sync this with your secure profile.',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeCaption,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanBullet(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, right: 8),
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label — ',
                    style: const TextStyle(
                      color: DesignTokens.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: DesignTokens.fontSizeSubtitle,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeSubtitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInjuryLogSection() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.35),
          width: DesignTokens.borderThin,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Injury Log',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'For each injury, track pain, surgeries, rehab and what actually '
            'reduces the pain. Use this with your doctors — not instead of them.',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeSubtitle,
              height: 1.4,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          _InjuryLogList(),
        ],
      ),
    );
  }

  Widget _buildAgeTimeline() {
    const ages = [30, 35, 40, 45, 50];
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.4),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Longevity Timeline',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '30 → 35 → 40 → 45 → 50. Use this to plan how you want your '
            'body to feel after war, surgeries, competition and hard sport.',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeSubtitle,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ages.map((age) {
              return Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$age',
                    style: const TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: DesignTokens.fontSizeSubtitle,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: DesignTokens.spacingL),
          const Text(
            'Recovery Key Examples',
            style: TextStyle(
              color: DesignTokens.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: DesignTokens.fontSizeSubtitleLarge,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '• Arthritis: joint-friendly strength work, heat/ice schedule, medication notes.\n'
            '• Post-surgery: surgeon orders, physio plan, red-flag symptoms to watch.\n'
            '• Head trauma: symptom diary, sleep pattern, balance and mood notes.',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeSubtitle,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddInjurySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddInjurySheet(),
    );
  }
}

/// Simple neon body outline for the holographic map.
class _BodyMapPainter extends CustomPainter {
  _BodyMapPainter({required this.pulse});

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = DesignTokens.neonCyan.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final glow = Paint()
      ..color = DesignTokens.neonCyan.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 + pulse * 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

    final body = Path();
    final w = size.width;
    final h = size.height;

    // Head
    body.addOval(
      Rect.fromCircle(center: Offset(w / 2, h * 0.09), radius: w * 0.14),
    );

    // Torso
    body.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.18, w * 0.5, h * 0.32),
        Radius.circular(w * 0.18),
      ),
    );

    // Hips
    body.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.48, w * 0.44, h * 0.10),
        Radius.circular(w * 0.12),
      ),
    );

    // Legs
    body.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.58, w * 0.12, h * 0.30),
        Radius.circular(w * 0.08),
      ),
    );
    body.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.58, h * 0.58, w * 0.12, h * 0.30),
        Radius.circular(w * 0.08),
      ),
    );

    // Arms
    body.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.22, w * 0.14, h * 0.32),
        Radius.circular(w * 0.08),
      ),
    );
    body.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.80, h * 0.22, w * 0.14, h * 0.32),
        Radius.circular(w * 0.08),
      ),
    );

    canvas.drawPath(body, glow);
    canvas.drawPath(body, outline);

    // Simple spine line
    final spine = Paint()
      ..color = DesignTokens.neonCyan.withValues(alpha: 0.6)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(w / 2, h * 0.18), Offset(w / 2, h * 0.86), spine);
  }

  @override
  bool shouldRepaint(covariant _BodyMapPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

/// Stateless list wrapper so it can manage its own Firestore stream.
class _InjuryLogList extends StatelessWidget {
  const _InjuryLogList();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Sign in to save your injury log securely. '
          'Otherwise, write notes in your own notebook.',
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeSubtitle,
          ),
        ),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('injury_logs')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Could not load injury log right now.',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeSubtitle,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No injuries logged yet. Start with the area that hurts most '
              'and write what makes it better or worse.',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeSubtitle,
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final region = data['region'] as String? ?? 'Unknown area';
            final label = data['label'] as String? ?? 'Pain / injury';
            final severity = data['severity'] as int? ?? 0;
            final rehab = data['rehabPlan'] as String? ?? '';
            final relief = data['painRelief'] as String? ?? '';
            final scanType = data['scanType'] as String? ?? '';

            Color chipColor;
            if (severity >= 8) {
              chipColor = DesignTokens.neonRed;
            } else if (severity >= 4) {
              chipColor = DesignTokens.neonAmber;
            } else {
              chipColor = DesignTokens.neonGreen;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.bgSecondary,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                border: Border.all(
                  color: chipColor.withValues(alpha: 0.35),
                  width: DesignTokens.borderThin,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: DesignTokens.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: DesignTokens.fontSizeSubtitleLarge,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: chipColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusPill,
                          ),
                        ),
                        child: Text(
                          'Pain $severity/10',
                          style: TextStyle(
                            color: chipColor,
                            fontSize: DesignTokens.fontSizeCaption,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    region,
                    style: const TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: DesignTokens.fontSizeSubtitle,
                    ),
                  ),
                  if (scanType.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.monitor_heart,
                          size: 14,
                          color: DesignTokens.neonCyan,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scanType,
                          style: const TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: DesignTokens.fontSizeCaption,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (rehab.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Rehab key: $rehab',
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeSubtitle,
                      ),
                    ),
                  ],
                  if (relief.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Pain relief that helps: $relief',
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeSubtitle,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _AddInjurySheet extends StatefulWidget {
  const _AddInjurySheet();

  @override
  State<_AddInjurySheet> createState() => _AddInjurySheetState();
}

class _AddInjurySheetState extends State<_AddInjurySheet> {
  final _formKey = GlobalKey<FormState>();
  final _regionController = TextEditingController();
  final _labelController = TextEditingController();
  final _rehabController = TextEditingController();
  final _reliefController = TextEditingController();
  final _notesController = TextEditingController();

  int _severity = 5;
  String _scanType = 'None';

  bool _isSaving = false;

  @override
  void dispose() {
    _regionController.dispose();
    _labelController.dispose();
    _rehabController.dispose();
    _reliefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.spacingL,
        right: DesignTokens.spacingL,
        top: DesignTokens.spacingL,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Log Pain / Injury',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This is for your memory. Always follow medical advice from '
              'qualified professionals — SamurAI is a helper, not a doctor.',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeSubtitle,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Short title (e.g. Left knee pain)',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _regionController,
              decoration: const InputDecoration(
                labelText: 'Body area (e.g. Knee, lower back, neck)',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Pain level',
                  style: TextStyle(color: DesignTokens.textSecondary),
                ),
                Expanded(
                  child: Slider(
                    value: _severity.toDouble(),
                    max: 10,
                    divisions: 10,
                    label: '$_severity',
                    activeColor: DesignTokens.neonMagenta,
                    onChanged: (v) => setState(() => _severity = v.round()),
                  ),
                ),
                Text(
                  '$_severity/10',
                  style: const TextStyle(color: DesignTokens.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _scanType,
              decoration: const InputDecoration(
                labelText: 'Related scan / test (optional)',
              ),
              items:
                  const [
                        'None',
                        'X-ray',
                        'MRI',
                        'CT',
                        'Ultrasound',
                        'ECG',
                        'EEG',
                        'Blood test',
                        'Blood pressure',
                      ]
                      .map(
                        (e) =>
                            DropdownMenuItem<String>(value: e, child: Text(e)),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _scanType = v ?? 'None'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _rehabController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Rehab key (exercises, stretches, pacing)',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _reliefController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'What actually reduces the pain?',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Extra notes you want future-you to remember',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSaving ? 'Saving...' : 'Save to Injury Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to save your injury log.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('injury_logs').add({
        'userId': uid,
        'label': _labelController.text.trim(),
        'region': _regionController.text.trim(),
        'severity': _severity,
        'scanType': _scanType == 'None' ? '' : _scanType,
        'rehabPlan': _rehabController.text.trim(),
        'painRelief': _reliefController.text.trim(),
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving injury log.')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
