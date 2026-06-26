import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fighter_model.dart';
import '../providers/fighter_providers.dart';
import '../../../shared/widgets/dfc_image_upload_widget.dart';

class FighterCreateScreen extends ConsumerStatefulWidget {
  const FighterCreateScreen({super.key});

  @override
  ConsumerState<FighterCreateScreen> createState() =>
      _FighterCreateScreenState();
}

class _FighterCreateScreenState extends ConsumerState<FighterCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _weightClassCtrl = TextEditingController();
  final _gymIdCtrl = TextEditingController();
  String _uploadedImageUrl = '';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final newFighter = FighterModel(
      id: 'f_${DateTime.now().millisecondsSinceEpoch}', // Will be overridden if backend handles IDs
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      nickname: _nicknameCtrl.text.trim(),
      weightClass: _weightClassCtrl.text.trim(),
      gymId: _gymIdCtrl.text.trim(),
      promotionId:
          'p_001', // Defaulting to base promotion, can add dropdown later
      profileImageUrl: _uploadedImageUrl,
    );

    try {
      final api = ref.read(fighterApiServiceProvider);
      await api.createFighter(newFighter);

      // Refresh the Fighter List Roster immediately
      ref.invalidate(fighterListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fighter created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _nicknameCtrl.dispose();
    _weightClassCtrl.dispose();
    _gymIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        title: const Text(
          'Add New Fighter',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0A0E17),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DfcImageUploadWidget(
                label: 'Upload Profile Picture',
                folderPath: 'fighters/profiles',
                onUploadComplete: (url) {
                  setState(() => _uploadedImageUrl = url);
                },
              ),
              const SizedBox(height: 24),
              _buildTextField(_firstNameCtrl, 'First Name'),
              const SizedBox(height: 16),
              _buildTextField(_lastNameCtrl, 'Last Name'),
              const SizedBox(height: 16),
              _buildTextField(_nicknameCtrl, 'Nickname'),
              const SizedBox(height: 16),
              _buildTextField(
                _weightClassCtrl,
                'Weight Class (e.g., Welterweight)',
              ),
              const SizedBox(height: 16),
              _buildTextField(_gymIdCtrl, 'Gym ID (e.g., g_001)'),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'CREATE FIGHTER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1A1C23),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
      validator: (value) => value != null && value.isEmpty ? 'Required' : null,
    );
  }
}
