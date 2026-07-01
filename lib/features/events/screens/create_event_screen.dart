import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/event_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CREATE EVENT SCREEN — Admin / Promoter event creation form
/// ═══════════════════════════════════════════════════════════════════════════
/// Full-featured event creation with all EventModel fields.
/// Creates event in Firestore via EventService.createEvent().
/// ═══════════════════════════════════════════════════════════════════════════
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService();
  bool _isSubmitting = false;
  String? _error;

  void _goBackSafely() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'Australia');
  final _posterUrlCtrl = TextEditingController();
  final _ticketUrlCtrl = TextEditingController();
  final _broadcastCtrl = TextEditingController();

  String _sportType = 'mma';
  DateTime _eventDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _mainCardTime = const TimeOfDay(hour: 19, minute: 0);
  bool _isFeatured = false;

  String _defaultPosterUrlForSport() {
    switch (_sportType) {
      case 'boxing':
        return ImageAssets.boxingPlaceholder;
      case 'kickboxing':
        return ImageAssets.kickboxingPlaceholder;
      case 'muay_thai':
        return ImageAssets.muayThaiPlaceholder;
      case 'bkfc':
        return ImageAssets.bkfcPlaceholder;
      case 'mma':
        return ImageAssets.ufcPlaceholder;
      default:
        return ImageAssets.eventPlaceholder;
    }
  }

  static const _sportTypes = [
    'mma',
    'boxing',
    'kickboxing',
    'muay_thai',
    'bkfc',
    'wrestling',
    'pro_wrestling',
    'bjj',
    'karate',
    'taekwondo',
    'other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _venueCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _posterUrlCtrl.dispose();
    _ticketUrlCtrl.dispose();
    _broadcastCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.neonCyan),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _mainCardTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.neonCyan),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _mainCardTime = picked);
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    final mainCard = DateTime(
      _eventDate.year,
      _eventDate.month,
      _eventDate.day,
      _mainCardTime.hour,
      _mainCardTime.minute,
    );
    final selectedPosterUrl = _posterUrlCtrl.text.trim().isEmpty
        ? _defaultPosterUrlForSport()
        : _posterUrlCtrl.text.trim();

    final event = EventModel(
      id: '', // Firestore will auto-generate
      promoterId: uid,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      venue: _venueCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      eventDate: _eventDate,
      mainCardTime: mainCard,
      sportType: _sportType,
      posterUrl: selectedPosterUrl,
      thumbnailUrl: selectedPosterUrl,
      bannerUrl: selectedPosterUrl,
      posterAspectRatio: 2 / 3,
      ticketUrl: _ticketUrlCtrl.text.trim().isEmpty
          ? null
          : _ticketUrlCtrl.text.trim(),
      broadcastInfo: _broadcastCtrl.text.trim().isEmpty
          ? null
          : _broadcastCtrl.text.trim(),
      isFeatured: _isFeatured,
    );

    final docId = await _eventService.createEvent(event);

    if (!mounted) return;

    if (docId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event "${event.name}" created!'),
          backgroundColor: AppTheme.neonGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate to the new event detail
      context.push('/event/$docId');
    } else {
      setState(() {
        _isSubmitting = false;
        _error = 'Failed to create event. Check Firestore permissions.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        title: const Text(
          'CREATE EVENT',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: AppTheme.neonCyan),
          onPressed: _goBackSafely,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A1628), Color(0xFF162040)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      color: AppTheme.neonCyan,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Fight Event',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Create a new event and share it with the DFC community',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Event Name ─────────────────────────────────────
              _buildLabel('EVENT NAME *'),
              _buildTextField(
                _nameCtrl,
                'e.g. IBC International Brawling Championships',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Event name required'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Description ────────────────────────────────────
              _buildLabel('DESCRIPTION'),
              _buildTextField(
                _descCtrl,
                'Tell fans what to expect...',
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // ── Sport Type ─────────────────────────────────────
              _buildLabel('SPORT TYPE'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.2),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _sportType,
                  decoration: const InputDecoration(border: InputBorder.none),
                  dropdownColor: AppTheme.cardBackground,
                  style: const TextStyle(color: Colors.white),
                  items: _sportTypes
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _sportType = v);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── Venue ──────────────────────────────────────────
              _buildLabel('VENUE *'),
              _buildTextField(
                _venueCtrl,
                'e.g. Brisbane Convention Centre',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Venue required' : null,
              ),
              const SizedBox(height: 16),

              // ── City + State Row ───────────────────────────────
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('CITY *'),
                        _buildTextField(
                          _cityCtrl,
                          'e.g. Brisbane',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'City required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('STATE'),
                        _buildTextField(_stateCtrl, 'e.g. QLD'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Country ────────────────────────────────────────
              _buildLabel('COUNTRY *'),
              _buildTextField(
                _countryCtrl,
                'e.g. Australia',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Country required' : null,
              ),
              const SizedBox(height: 16),

              // ── Date & Time ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('EVENT DATE *'),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.neonCyan.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppTheme.neonCyan,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_eventDate.day}/${_eventDate.month}/${_eventDate.year}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('MAIN CARD TIME'),
                        GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.neonCyan.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: AppTheme.neonCyan,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _mainCardTime.format(context),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Poster URL ─────────────────────────────────────
              _buildLabel('POSTER IMAGE URL'),
              _buildTextField(_posterUrlCtrl, 'https://...'),
              const SizedBox(height: 16),

              // ── Ticket URL ─────────────────────────────────────
              _buildLabel('TICKET / BUY LINK'),
              _buildTextField(_ticketUrlCtrl, 'https://...'),
              const SizedBox(height: 16),

              // ── Broadcast Info ─────────────────────────────────
              _buildLabel('BROADCAST / STREAMING'),
              _buildTextField(_broadcastCtrl, 'e.g. DFC PPV, ESPN+ PPV, DAZN'),
              const SizedBox(height: 16),

              // ── Featured Toggle ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.2),
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'FEATURED EVENT',
                    style: TextStyle(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  subtitle: const Text(
                    'Show in featured carousel on homepage',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  value: _isFeatured,
                  activeThumbColor: AppTheme.neonCyan,
                  onChanged: (v) => setState(() => _isFeatured = v),
                ),
              ),
              const SizedBox(height: 24),

              // ── Error ──────────────────────────────────────────
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ),

              // ── Submit Button ──────────────────────────────────
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'CREATE EVENT',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.neonCyan,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: AppTheme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.neonCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
      ),
    );
  }
}
