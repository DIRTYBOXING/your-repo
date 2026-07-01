import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MEDICAL & SAFETY TABLET
/// Post-fight vitals and SCAT5 Concussion Protocol interface.
/// ═══════════════════════════════════════════════════════════════════════════
class MedicalSafetyScreen extends StatefulWidget {
  const MedicalSafetyScreen({super.key});

  @override
  State<MedicalSafetyScreen> createState() => _MedicalSafetyScreenState();
}

class _MedicalSafetyScreenState extends State<MedicalSafetyScreen> {
  // Mocking active fight data. In production, this pulls from the active event.
  final String _fighterId = 'demo_fighter_123';
  final String _fighterName = 'Marcus Torres';
  final String _eventId = 'demo_event_123';

  final _hrCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();

  // SCAT5 Symptoms
  bool _symptomHeadache = false;
  bool _symptomNausea = false;
  bool _symptomDizziness = false;
  bool _symptomFoggy = false;

  bool _isSubmitting = false;

  Future<void> _submitMedicalClearance() async {
    setState(() => _isSubmitting = true);
    try {
      final doctorId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_doc';
      final hasConcussionSymptoms =
          _symptomHeadache ||
          _symptomNausea ||
          _symptomDizziness ||
          _symptomFoggy;

      // 1. Write the medical check
      final checkRef = await FirebaseFirestore.instance
          .collection('medical_checks')
          .add({
            'fighter_id': _fighterId,
            'event_id': _eventId,
            'doctor_id': doctorId,
            'check_type': 'post_fight',
            'heart_rate': int.tryParse(_hrCtrl.text),
            'blood_pressure': _bpCtrl.text,
            'passed': !hasConcussionSymptoms,
            'concussion_cleared': !hasConcussionSymptoms,
            'created_at': FieldValue.serverTimestamp(),
          });

      // 2. Auto-trigger regulatory suspension if concussion is detected
      if (hasConcussionSymptoms) {
        await FirebaseFirestore.instance.collection('suspensions').add({
          'fighter_id': _fighterId,
          'medical_check_id': checkRef.id,
          'reason': 'Concussion Protocol / Head Trauma',
          'days': 30, // Minimum mandatory stand-down
          'start_date': FieldValue.serverTimestamp(),
          'end_date': DateTime.now()
              .add(const Duration(days: 30))
              .toIso8601String(),
          'is_active': true,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasConcussionSymptoms
                  ? '⚠️ MEDICAL SUSPENSION APPLIED (30 DAYS)'
                  : '✅ FIGHTER CLEARED',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: hasConcussionSymptoms
                ? AppColors.neonOrange
                : AppColors.neonGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _hrCtrl.dispose();
    _bpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text(
          'RINGSIDE MEDICAL TENT',
          style: TextStyle(
            color: AppColors.neonRed,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'POST-FIGHT EVALUATION: ${_fighterName.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'VITALS',
            style: TextStyle(
              color: AppColors.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hrCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Heart Rate (bpm)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: AppColors.panel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _bpCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Blood Pressure',
                    hintText: '120/80',
                    hintStyle: const TextStyle(color: Colors.white24),
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: AppColors.panel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Text(
            'SCAT5 CONCUSSION SCREENING',
            style: TextStyle(
              color: AppColors.neonOrange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select all symptoms observed or reported by the fighter:',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),

          _buildCheckbox(
            'Severe Headache or Pressure',
            _symptomHeadache,
            (val) => setState(() => _symptomHeadache = val!),
          ),
          _buildCheckbox(
            'Nausea or Vomiting',
            _symptomNausea,
            (val) => setState(() => _symptomNausea = val!),
          ),
          _buildCheckbox(
            'Dizziness or Balance Issues',
            _symptomDizziness,
            (val) => setState(() => _symptomDizziness = val!),
          ),
          _buildCheckbox(
            'Feeling "Foggy" or Slowed Down',
            _symptomFoggy,
            (val) => setState(() => _symptomFoggy = val!),
          ),

          const SizedBox(height: 48),
          SizedBox(
            height: 60,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (_symptomHeadache ||
                        _symptomNausea ||
                        _symptomDizziness ||
                        _symptomFoggy)
                    ? AppColors.neonOrange
                    : AppColors.neonGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSubmitting ? null : _submitMedicalClearance,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.health_and_safety),
              label: Text(
                (_symptomHeadache ||
                        _symptomNausea ||
                        _symptomDizziness ||
                        _symptomFoggy)
                    ? 'APPLY 30-DAY MEDICAL SUSPENSION'
                    : 'CLEAR FIGHTER',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? AppColors.neonOrange : AppColors.border,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            color: value ? AppColors.neonOrange : Colors.white,
            fontWeight: value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        value: value,
        activeColor: AppColors.neonOrange,
        checkColor: Colors.black,
        onChanged: onChanged,
      ),
    );
  }
}
