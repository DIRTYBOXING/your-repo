import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/dfc_glass_panel.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER EVENT MANAGER
/// Where promoters configure PPV pricing, streaming URLs, and publish events.
/// ═══════════════════════════════════════════════════════════════════════════
class EventManagerScreen extends StatefulWidget {
  const EventManagerScreen({super.key});

  @override
  State<EventManagerScreen> createState() => _EventManagerScreenState();
}

class _EventManagerScreenState extends State<EventManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _streamUrlCtrl = TextEditingController();
  bool _isLive = false;
  bool _isSaving = false;

  Future<void> _saveAndPublish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final promoterId = context.read<AuthService>().currentUser?.uid;
      if (promoterId == null) throw Exception("Unauthorized: Not logged in.");

      final priceCents = (double.parse(_priceCtrl.text) * 100).toInt();
      
      // 1. Create the base event document
      final eventRef = await FirebaseFirestore.instance.collection('events').add({
        'name': _titleCtrl.text,
        'promoter_id': promoterId,
        'status': _isLive ? 'live' : 'published',
        'date': FieldValue.serverTimestamp(),
      });

      // 2. Create the PPV Event document for the Storefront
      await FirebaseFirestore.instance.collection('ppvEvents').doc(eventRef.id).set({
        'event_id': eventRef.id,
        'price': priceCents / 100, // Storing decimal for easy display
        'priceCents': priceCents,
        'streamUrl': _streamUrlCtrl.text,
        'isActive': _isLive,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Event Successfully Published!'),
          backgroundColor: AppColors.neonGreen,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save event: $e'),
          backgroundColor: AppColors.neonRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _streamUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text('EVENT MANAGER', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, letterSpacing: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            physics: const BouncingScrollPhysics(),
            children: [
              DfcGlassPanel(
                accent: AppColors.neonCyan,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EVENT DETAILS', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Event Title',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: AppColors.bg.withValues(alpha: 0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'PPV Ticket Price (USD)',
                        prefixIcon: const Icon(Icons.attach_money, color: Colors.white54),
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: AppColors.bg.withValues(alpha: 0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              DfcGlassPanel(
                accent: AppColors.neonMagenta,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BROADCAST SETTINGS', style: TextStyle(color: AppColors.neonMagenta, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _streamUrlCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mux HLS Stream URL',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: AppColors.bg.withValues(alpha: 0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('GO LIVE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Instantly opens the PPV stream for buyers.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      value: _isLive,
                      activeColor: AppColors.neonRed,
                      onChanged: (val) => setState(() => _isLive = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGreen, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isSaving ? null : _saveAndPublish,
                child: _isSaving ? const CircularProgressIndicator(color: Colors.black) : const Text('SAVE & PUBLISH EVENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}