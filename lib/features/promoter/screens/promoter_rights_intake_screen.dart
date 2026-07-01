import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/ppv_license_model.dart';
import '../../../shared/services/ppv_license_service.dart';

class PromoterRightsIntakeScreen extends StatefulWidget {
  const PromoterRightsIntakeScreen({
    super.key,
    this.prefilledEventId,
    this.prefilledPpvEventId,
  });

  final String? prefilledEventId;
  final String? prefilledPpvEventId;

  @override
  State<PromoterRightsIntakeScreen> createState() =>
      _PromoterRightsIntakeScreenState();
}

class _PromoterRightsIntakeScreenState
    extends State<PromoterRightsIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PpvLicenseService();

  final _eventIdCtrl = TextEditingController();
  final _ppvEventIdCtrl = TextEditingController();
  final _licensorEntityCtrl = TextEditingController();
  final _licensorContactCtrl = TextEditingController();
  final _licensorAbnCtrl = TextEditingController();
  final _paymentTermsCtrl = TextEditingController(text: 'Net 30 after event');
  final _minimumGuaranteeCtrl = TextEditingController();
  final _revenueShareCtrl = TextEditingController(text: '70');

  TerritoryScope _territory = TerritoryScope.australia;
  ExclusivityType _exclusivity = ExclusivityType.nonExclusive;
  RevenueModel _revenueModel = RevenueModel.hybrid;
  DateTime _termStart = DateTime.now();
  DateTime _termEnd = DateTime.now().add(const Duration(days: 30));
  bool _musicRightsCleared = false;
  bool _talentReleasesObtained = false;
  bool _archivalFootageCleared = false;
  bool _logosTrademarkCleared = false;
  bool _eventInsuranceConfirmed = false;
  bool _cyberInsuranceConfirmed = false;
  bool _licensorAttestationSigned = false;
  bool _isSaving = false;
  String? _licenseId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _eventIdCtrl.text = widget.prefilledEventId ?? '';
    _ppvEventIdCtrl.text = widget.prefilledPpvEventId ?? '';
    _loadExisting();
  }

  @override
  void dispose() {
    _eventIdCtrl.dispose();
    _ppvEventIdCtrl.dispose();
    _licensorEntityCtrl.dispose();
    _licensorContactCtrl.dispose();
    _licensorAbnCtrl.dispose();
    _paymentTermsCtrl.dispose();
    _minimumGuaranteeCtrl.dispose();
    _revenueShareCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    PpvLicenseModel? license;
    if (_eventIdCtrl.text.trim().isNotEmpty) {
      license = await _service.getLicenseForEventId(_eventIdCtrl.text.trim());
    } else if (_ppvEventIdCtrl.text.trim().isNotEmpty) {
      license = await _service.getLicenseForEvent(_ppvEventIdCtrl.text.trim());
    }
    if (!mounted || license == null) return;
    final existing = license;

    setState(() {
      _licenseId = existing.id;
      _eventIdCtrl.text = existing.eventId;
      _ppvEventIdCtrl.text = existing.ppvEventId;
      _licensorEntityCtrl.text = existing.licensorEntity;
      _licensorContactCtrl.text = existing.licensorContact;
      _licensorAbnCtrl.text = existing.licensorAbn ?? '';
      _paymentTermsCtrl.text = existing.paymentTerms ?? 'Net 30 after event';
      _minimumGuaranteeCtrl.text = existing.minimumGuaranteeCents == null
          ? ''
          : (existing.minimumGuaranteeCents! / 100).toStringAsFixed(2);
      _revenueShareCtrl.text = existing.revenueSharePct == null
          ? '70'
          : (existing.revenueSharePct! * 100).toStringAsFixed(0);
      _territory = existing.territory;
      _exclusivity = existing.exclusivity;
      _revenueModel = existing.revenueModel;
      _termStart = existing.termStart;
      _termEnd = existing.termEnd;
      _musicRightsCleared = existing.musicRightsCleared;
      _talentReleasesObtained = existing.talentReleasesObtained;
      _archivalFootageCleared = existing.archivalFootageCleared;
      _logosTrademarkCleared = existing.logosTrademarkCleared;
      _eventInsuranceConfirmed = existing.eventInsuranceConfirmed;
      _cyberInsuranceConfirmed = existing.cyberInsuranceConfirmed;
      _licensorAttestationSigned = existing.licensorAttestationSigned;
    });
  }

  Future<void> _pickDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? _termStart : _termEnd,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _termStart = selected;
        if (_termEnd.isBefore(_termStart)) {
          _termEnd = _termStart.add(const Duration(days: 30));
        }
      } else {
        _termEnd = selected;
      }
    });
  }

  Future<void> _save({required bool submitForReview}) async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _error = 'Sign in is required.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final revenueSharePct = double.tryParse(_revenueShareCtrl.text.trim());
    final minimumGuarantee = double.tryParse(_minimumGuaranteeCtrl.text.trim());
    final updates = <String, dynamic>{
      'ppvEventId': _ppvEventIdCtrl.text.trim(),
      'eventId': _eventIdCtrl.text.trim(),
      'promoterId': userId,
      'licensorEntity': _licensorEntityCtrl.text.trim(),
      'licensorContact': _licensorContactCtrl.text.trim(),
      'licensorAbn': _licensorAbnCtrl.text.trim().isEmpty
          ? null
          : _licensorAbnCtrl.text.trim(),
      'territory': _territory.name,
      'exclusivity': _exclusivity.name,
      'termStart': _termStart,
      'termEnd': _termEnd,
      'revenueModel': _revenueModel.name,
      'revenueSharePct': revenueSharePct == null ? null : revenueSharePct / 100,
      'minimumGuaranteeCents': minimumGuarantee == null
          ? null
          : (minimumGuarantee * 100).round(),
      'paymentTerms': _paymentTermsCtrl.text.trim(),
      'musicRightsCleared': _musicRightsCleared,
      'talentReleasesObtained': _talentReleasesObtained,
      'archivalFootageCleared': _archivalFootageCleared,
      'logosTrademarkCleared': _logosTrademarkCleared,
      'eventInsuranceConfirmed': _eventInsuranceConfirmed,
      'cyberInsuranceConfirmed': _cyberInsuranceConfirmed,
      'licensorAttestationSigned': _licensorAttestationSigned,
    };

    try {
      if (_licenseId == null) {
        final now = DateTime.now();
        _licenseId = await _service.createLicense(
          userId: userId,
          license: PpvLicenseModel(
            id: '',
            ppvEventId: _ppvEventIdCtrl.text.trim(),
            eventId: _eventIdCtrl.text.trim(),
            promoterId: userId,
            licensorEntity: _licensorEntityCtrl.text.trim(),
            licensorContact: _licensorContactCtrl.text.trim(),
            licensorAbn: _licensorAbnCtrl.text.trim().isEmpty
                ? null
                : _licensorAbnCtrl.text.trim(),
            territory: _territory,
            exclusivity: _exclusivity,
            termStart: _termStart,
            termEnd: _termEnd,
            revenueModel: _revenueModel,
            revenueSharePct: revenueSharePct == null
                ? null
                : revenueSharePct / 100,
            minimumGuaranteeCents: minimumGuarantee == null
                ? null
                : (minimumGuarantee * 100).round(),
            paymentTerms: _paymentTermsCtrl.text.trim(),
            musicRightsCleared: _musicRightsCleared,
            talentReleasesObtained: _talentReleasesObtained,
            archivalFootageCleared: _archivalFootageCleared,
            logosTrademarkCleared: _logosTrademarkCleared,
            eventInsuranceConfirmed: _eventInsuranceConfirmed,
            cyberInsuranceConfirmed: _cyberInsuranceConfirmed,
            licensorAttestationSigned: _licensorAttestationSigned,
            createdBy: userId,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await _service.updateLicense(
          licenseId: _licenseId!,
          userId: userId,
          updates: updates,
        );
      }

      if (submitForReview && _licenseId != null) {
        await _service.submitForReview(licenseId: _licenseId!, userId: userId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            submitForReview
                ? 'Rights intake submitted for review.'
                : 'Rights intake draft saved.',
          ),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
      context.pop();
    } catch (e) {
      setState(() => _error = 'Failed to save rights intake: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Rights Intake'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Event Linkage'),
            _textField('Event ID', _eventIdCtrl, required: true),
            _textField('PPV Event ID', _ppvEventIdCtrl),
            _sectionTitle('Licensor'),
            _textField('Licensor Entity', _licensorEntityCtrl, required: true),
            _textField(
              'Licensor Contact',
              _licensorContactCtrl,
              required: true,
            ),
            _textField('ABN / License Number', _licensorAbnCtrl),
            _sectionTitle('Commercial Terms'),
            _dropdown<TerritoryScope>(
              'Territory',
              _territory,
              TerritoryScope.values,
              (value) {
                if (value != null) setState(() => _territory = value);
              },
            ),
            _dropdown<ExclusivityType>(
              'Exclusivity',
              _exclusivity,
              ExclusivityType.values,
              (value) {
                if (value != null) setState(() => _exclusivity = value);
              },
            ),
            _dropdown<RevenueModel>(
              'Revenue Model',
              _revenueModel,
              RevenueModel.values,
              (value) {
                if (value != null) setState(() => _revenueModel = value);
              },
            ),
            _textField('Revenue Share %', _revenueShareCtrl),
            _textField(
              'Minimum Guarantee',
              _minimumGuaranteeCtrl,
              keyboardType: TextInputType.number,
            ),
            _textField('Payment Terms', _paymentTermsCtrl),
            const SizedBox(height: 12),
            _dateRow('Term Start', _termStart, () => _pickDate(start: true)),
            _dateRow('Term End', _termEnd, () => _pickDate(start: false)),
            _sectionTitle('Clearances'),
            _toggle(
              'Music Rights Cleared',
              _musicRightsCleared,
              (value) => setState(() => _musicRightsCleared = value),
            ),
            _toggle(
              'Talent Releases Obtained',
              _talentReleasesObtained,
              (value) => setState(() => _talentReleasesObtained = value),
            ),
            _toggle(
              'Archival Footage Cleared',
              _archivalFootageCleared,
              (value) => setState(() => _archivalFootageCleared = value),
            ),
            _toggle(
              'Logos / Trademark Cleared',
              _logosTrademarkCleared,
              (value) => setState(() => _logosTrademarkCleared = value),
            ),
            _toggle(
              'Event Insurance Confirmed',
              _eventInsuranceConfirmed,
              (value) => setState(() => _eventInsuranceConfirmed = value),
            ),
            _toggle(
              'Cyber Insurance Confirmed',
              _cyberInsuranceConfirmed,
              (value) => setState(() => _cyberInsuranceConfirmed = value),
            ),
            _toggle(
              'Licensor Attestation Signed',
              _licensorAttestationSigned,
              (value) => setState(() => _licensorAttestationSigned = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => _save(submitForReview: false),
                    child: const Text('Save Draft'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () => _save(submitForReview: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonCyan,
                    ),
                    child: Text(_isSaving ? 'Saving...' : 'Submit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.accentTeal,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: required
            ? (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppTheme.cardDark,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _dropdown<T>(
    String label,
    T value,
    List<T> items,
    ValueChanged<T?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        onChanged: onChanged,
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString().split('.').last),
              ),
            )
            .toList(),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppTheme.cardDark,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      title: Text(label),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _dateRow(String label, DateTime value, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: onTap,
    );
  }
}
