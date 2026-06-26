import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/design_tokens.dart';

// This screen is ONLY for posting 'Looking for a Fighter' events.
class LookingForFighterScreen extends StatefulWidget {
  const LookingForFighterScreen({super.key});

  @override
  State<LookingForFighterScreen> createState() =>
      _LookingForFighterScreenState();
}

class _LookingForFighterScreenState extends State<LookingForFighterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedSport = AppConstants.sportTypes.first;
  String _selectedWeight = AppConstants.mmaWeightClasses.first;
  final _eventNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  bool _submitted = false;

  List<String> get _weightClasses {
    if (_selectedSport == 'Boxing') return AppConstants.boxingWeightClasses;
    return AppConstants.mmaWeightClasses;
  }

  @override
  void dispose() {
    _eventNameCtrl.dispose();
    _locationCtrl.dispose();
    _dateCtrl.dispose();
    _detailsCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Fighter request posted — promoters and matchmakers will see this.',
        ),
        backgroundColor: DesignTokens.neonCyan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        title: const Text(
          'Looking for a Fighter',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: DesignTokens.textPrimary,
          ),
        ),
        elevation: 0,
      ),
      body: _submitted ? _buildConfirmation() : _buildForm(),
    );
  }

  Widget _buildConfirmation() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: DesignTokens.neonCyan,
              size: 72,
            ),
            const SizedBox(height: 24),
            const Text(
              'Request Posted',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_eventNameCtrl.text}\n$_selectedSport · $_selectedWeight · ${_locationCtrl.text}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Matchmakers, managers, and fighters on DFC will be notified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonCyan,
              ),
              onPressed: () => setState(() {
                _submitted = false;
                _formKey.currentState?.reset();
                _eventNameCtrl.clear();
                _locationCtrl.clear();
                _dateCtrl.clear();
                _detailsCtrl.clear();
                _contactCtrl.clear();
              }),
              child: const Text(
                'Post Another',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.sports_mma, color: DesignTokens.neonCyan, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Post a callout for fighters. Promoters, matchmakers, and managers can fill spots on your card.',
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _label('Event / Show Name'),
          _textField(
            _eventNameCtrl,
            'e.g. IBC III — Brisbane',
            validator: _required,
          ),
          const SizedBox(height: 16),
          _label('Combat Sport'),
          _dropdown(AppConstants.sportTypes, _selectedSport, (v) {
            setState(() {
              _selectedSport = v;
              _selectedWeight = _weightClasses.first;
            });
          }),
          const SizedBox(height: 16),
          _label('Weight Class'),
          _dropdown(
            _weightClasses,
            _selectedWeight,
            (v) => setState(() => _selectedWeight = v),
          ),
          const SizedBox(height: 16),
          _label('Location'),
          _textField(
            _locationCtrl,
            'e.g. Brisbane Convention Centre, QLD',
            validator: _required,
          ),
          const SizedBox(height: 16),
          _label('Event Date'),
          _textField(_dateCtrl, 'e.g. 15 Apr 2026', validator: _required),
          const SizedBox(height: 16),
          _label('Details'),
          _textField(
            _detailsCtrl,
            'e.g. Need 77kg fighter with pro record, 3+ fights. Paid bout.',
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _label('Contact (email or DFC profile)'),
          _textField(
            _contactCtrl,
            'e.g. promoter@email.com',
            validator: _required,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonCyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitRequest,
              child: const Text(
                'POST FIGHTER REQUEST',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'ACTIVE CALLOUTS',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._demoCallouts.map(_buildCalloutCard),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: DesignTokens.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: DesignTokens.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: DesignTokens.textMuted),
        filled: true,
        fillColor: DesignTokens.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: DesignTokens.textDisabled.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DesignTokens.neonCyan),
        ),
      ),
    );
  }

  Widget _dropdown(
    List<String> items,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DesignTokens.textDisabled.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: DesignTokens.bgCard,
          style: const TextStyle(color: DesignTokens.textPrimary),
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _buildCalloutCard((String, String, String, String, String) c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c.$2,
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                c.$3,
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                c.$5,
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.$1,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            c.$4,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static const _demoCallouts = <(String, String, String, String, String)>[
    (
      'IBC III — Need 77kg MMA fighter, 3+ pro fights',
      'MMA',
      'Welterweight',
      'Brisbane, QLD — paid bout, full promotion through DFC.',
      '15 Apr',
    ),
    (
      'Boxing show — 2 x Heavyweight spots open',
      'Boxing',
      'Heavyweight',
      'Sydney, NSW — pro card, ESPN coverage. Contact: danny@ibc.com.au',
      '22 Apr',
    ),
    (
      'BKFC Brisbane — 66kg open slot',
      'BKFC',
      'Lightweight',
      'Brisbane, QLD — bare knuckle, must have 2+ fights. Kit provided.',
      '29 Apr',
    ),
    (
      'Muay Thai Super Series — 57kg title fight',
      'Muay Thai',
      'Bantamweight',
      'Melbourne, VIC — title on the line, live PPV on DFC.',
      '6 May',
    ),
    (
      'Amateur MMA card — all weight classes',
      'MMA',
      'Open Weight',
      'Gold Coast, QLD — amateur rules, great exposure. Free entry for fighters.',
      '10 May',
    ),
  ];
}
