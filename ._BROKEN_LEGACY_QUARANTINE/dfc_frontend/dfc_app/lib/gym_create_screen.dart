import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gym_model.dart';
import '../providers/admin_gym_providers.dart';
import '../../../core/layout/dfc_layout.dart';
import '../../../core/layout/dfc_padding.dart';
import '../../../shared/widgets/dfc_image_upload_widget.dart';

class GymCreateScreen extends ConsumerStatefulWidget {
  const GymCreateScreen({super.key});

  @override
  ConsumerState<GymCreateScreen> createState() => _GymCreateScreenState();
}

class _GymCreateScreenState extends ConsumerState<GymCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  String _uploadedLogoUrl = '';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final newGym = GymModel(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      logoUrl: _uploadedLogoUrl,
    );

    try {
      final api = ref.read(gymApiServiceProvider);
      await api.createGym(newGym);
      ref.invalidate(adminGymListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gym added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        title: const Text('Add New Gym', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0A0E17),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: DfcPadding(
        child: DfcLayout.constrain(
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DfcImageUploadWidget(
                  label: 'Upload Gym Logo',
                  folderPath: 'gyms/logos',
                  onUploadComplete: (url) {
                    setState(() => _uploadedLogoUrl = url);
                  },
                ),
                const SizedBox(height: 24),
                _buildTextField(_nameCtrl, 'Gym Name'),
                const SizedBox(height: 16),
                _buildTextField(_cityCtrl, 'City'),
                const SizedBox(height: 16),
                _buildTextField(_countryCtrl, 'Country'),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'ADD GYM',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
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
      ),
      validator: (value) => value != null && value.isEmpty ? 'Required' : null,
    );
  }
}
