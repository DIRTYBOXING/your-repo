import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bout_slot_model.dart';
import '../../../shared/models/bout_offer_model.dart';
import '../../../shared/services/matchmaking_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 📋 BOUT OFFER SCREEN — Fighter applies for an open slot
// ─────────────────────────────────────────────────────────────────────────────

class BoutOfferScreen extends StatefulWidget {
  final BoutSlotModel slot;
  final String userId;

  const BoutOfferScreen({super.key, required this.slot, required this.userId});

  @override
  State<BoutOfferScreen> createState() => _BoutOfferScreenState();
}

class _BoutOfferScreenState extends State<BoutOfferScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  final _service = MatchmakingService();

  bool _submitting = false;
  bool _submitted = false;

  late final AnimationController _successCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final offer = BoutOfferModel(
      id: '',
      slotId: widget.slot.id,
      fighterId: widget.userId,
      fighterName: 'My Fighter Profile',
      fighterRecord: '0-0-0',
      fighterCountry: '',
      weightClass: widget.slot.weightClass,
      message: _messageCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _service.submitOffer(offer);
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitted = true;
        });
        _successCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _slotTypeColor(widget.slot.slotType);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        title: const Text(
          'Apply for Slot',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _submitted ? _buildSuccessView() : _buildForm(typeColor),
    );
  }

  Widget _buildForm(Color typeColor) {
    final slot = widget.slot;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr =
        '${slot.eventDate.day} ${months[slot.eventDate.month - 1]} ${slot.eventDate.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Slot Summary Card ────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: typeColor.withValues(alpha: 0.40),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: typeColor.withValues(alpha: 0.60),
                          ),
                        ),
                        child: Text(
                          slot.slotType.label,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (slot.purse > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFD740,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(
                                0xFFFFD740,
                              ).withValues(alpha: 0.40),
                            ),
                          ),
                          child: Text(
                            '\$${_formatMoney(slot.purse)} purse',
                            style: const TextStyle(
                              color: Color(0xFFFFD740),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    slot.eventName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${slot.venue} · ${slot.city}, ${slot.country}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _badge(slot.weightClass, AppTheme.accentTeal),
                      _badge(slot.sportType, const Color(0xFF69FF47)),
                    ],
                  ),
                  if (slot.notes != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      slot.notes!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.group,
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${slot.applicationCount} applications so far',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Promoter ─────────────────────────────────────────────────
            const Text(
              'PROMOTER',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, size: 16, color: AppTheme.accentTeal),
                  const SizedBox(width: 8),
                  Text(
                    slot.promoterName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Cover Message ────────────────────────────────────────────
            const Text(
              'COVER MESSAGE',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Introduce yourself. Share your record, training camp, and why you\'re the right fighter for this slot...',
                hintStyle: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppTheme.cardBackground,
                counterStyle: const TextStyle(color: AppTheme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.accentTeal),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please write a cover message.';
                }
                if (v.trim().length < 20) {
                  return 'Message too short — tell the promoter about yourself.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Important Notes ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.accentTeal.withValues(alpha: 0.20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppTheme.accentTeal,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Before You Apply',
                        style: TextStyle(
                          color: AppTheme.accentTeal,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _infoLine(
                    'Ensure your fighter profile is complete and up to date.',
                  ),
                  _infoLine(
                    'Your record must be accurate — promoters verify all records.',
                  ),
                  _infoLine(
                    'You will be notified when the promoter reviews your application.',
                  ),
                  _infoLine(
                    'All contracts are subject to DFC platform terms and conditions.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit Button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(
                  _submitting ? 'Submitting...' : 'SUBMIT APPLICATION',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.neonGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.neonGreen.withValues(alpha: 0.50),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 52,
                color: AppTheme.neonGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Application Submitted!',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.slot.eventName,
              style: const TextStyle(
                color: AppTheme.accentTeal,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'The promoter will review your application.\nYou\'ll be notified of their decision.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () => Navigator.of(context)
                ..pop()
                ..pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cardBackground,
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
              ),
              child: const Text('Back to Board'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _slotTypeColor(BoutSlotType type) {
    switch (type) {
      case BoutSlotType.mainEvent:
        return const Color(0xFFFFD740);
      case BoutSlotType.coMain:
        return const Color(0xFF00E5FF);
      case BoutSlotType.prelim:
        return const Color(0xFF69FF47);
      case BoutSlotType.amateur:
        return const Color(0xFFAB47BC);
    }
  }

  String _formatMoney(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
