import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER ONBOARDING WIZARD — AI-enhanced fighter registration.
/// Steps: Identity → Stats → Health → Brand → Goals → Activate
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);
const _kCyan = Color(0xFF00E5FF);
const _kGreen = Color(0xFF00E676);
const _kMagenta = Color(0xFFE040FB);

class FighterOnboardingScreen extends StatefulWidget {
  const FighterOnboardingScreen({super.key});

  @override
  State<FighterOnboardingScreen> createState() =>
      _FighterOnboardingScreenState();
}

class _FighterOnboardingScreenState extends State<FighterOnboardingScreen> {
  int _step = 0;
  String _selectedDiscipline = 'MMA';

  final _disciplines = [
    'MMA',
    'Boxing',
    'Muay Thai',
    'BJJ',
    'Wrestling',
    'Kickboxing',
    'Bare Knuckle',
    'BKFC',
    'Brawling',
    'Judo',
    'Karate',
    'Taekwondo',
  ];

  final _steps = const <_FighterStep>[
    _FighterStep(
      title: 'FIGHTER IDENTITY',
      subtitle: 'Your fighting persona',
      icon: Icons.person,
      description:
          'Create your fighter profile on DFC. This is how promoters, fans, '
          'and AI matchmaking will find you.',
      fields: [
        'Full Name',
        'Fight Name / Nickname',
        'Weight Class',
        'Date of Birth',
      ],
    ),
    _FighterStep(
      title: 'COMBAT STATS',
      subtitle: 'Your record and abilities',
      icon: Icons.sports_mma,
      description:
          'Enter your professional/amateur record. Our AI will use this to '
          'calibrate matchmaking, simulations, and career predictions.',
      fields: [
        'Pro Record (W-L-D)',
        'Amateur Record',
        'Reach (cm)',
        'Height (cm)',
      ],
    ),
    _FighterStep(
      title: 'HEALTH PASSPORT',
      subtitle: 'Safety first',
      icon: Icons.medical_services,
      description:
          'Create your DFC Health Passport. This protects you by tracking '
          'medical clearance, concussion history, and weight management.',
      fields: ['Last Medical Exam Date', 'Known Injuries', 'Blood Type'],
    ),
    _FighterStep(
      title: 'FIGHTER BRAND',
      subtitle: 'AI-powered branding',
      icon: Icons.palette,
      description:
          'Let our AI Brand Engine suggest your fighter brand identity. '
          'Custom logos, fight card designs, and walkout themes.',
      fields: [
        'Preferred Colors',
        'Fighting Style Description',
        'Social Media Handles',
      ],
    ),
    _FighterStep(
      title: 'CAREER GOALS',
      subtitle: 'Where do you want to go?',
      icon: Icons.trending_up,
      description:
          'Set your career targets. Our Career Engine will map optimal paths '
          'and match you with the right opportunities.',
      fields: ['Short-term Goal', 'Dream Fight', 'Target Championship'],
    ),
    _FighterStep(
      title: 'ACTIVATE',
      subtitle: 'Join the global network',
      icon: Icons.flash_on,
      description:
          'Your profile will be visible to promoters worldwide. AI matchmaking '
          'will start finding opportunities based on your profile.',
      fields: ['Review & Confirm'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('FIGHTER ONBOARDING'),
        backgroundColor: _kBg,
        foregroundColor: _kCyan,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressDots(),
          Expanded(child: _buildContent()),
          _buildNavigation(),
        ],
      ),
    );
  }

  Widget _buildProgressDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_steps.length, (i) {
          final active = i == _step;
          final done = i < _step;
          return Container(
            width: active ? 32 : 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: done
                  ? _kGreen
                  : active
                  ? _kCyan
                  : _kBorder,
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    final step = _steps[_step];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(step.icon, color: _kCyan, size: 48),
        const SizedBox(height: 12),
        Text(
          step.title,
          style: const TextStyle(
            color: _kCyan,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          step.subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
          textAlign: TextAlign.center,
        ),

        if (_step == 0) ...[
          const SizedBox(height: 20),
          const Text(
            'Primary Discipline',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _disciplines.map((d) {
              final selected = d == _selectedDiscipline;
              return GestureDetector(
                onTap: () => setState(() => _selectedDiscipline = d),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _kCyan.withValues(alpha: 0.2) : _kPanel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? _kCyan : _kBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    d,
                    style: TextStyle(
                      color: selected ? _kCyan : Colors.white54,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Text(
            step.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...step.fields.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: f,
                labelStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _kPanel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kCyan),
                ),
              ),
            ),
          ),
        ),

        if (_step == 3) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('GENERATE AI BRAND CONCEPT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kMagenta,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: _kPanel,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            TextButton.icon(
              onPressed: () => setState(() => _step--),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('BACK'),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
            ),
          const Spacer(),
          Text(
            '${_step + 1} / ${_steps.length}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              if (_step < _steps.length - 1) {
                setState(() => _step++);
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: Icon(
              _step == _steps.length - 1 ? Icons.flash_on : Icons.arrow_forward,
              size: 16,
            ),
            label: Text(_step == _steps.length - 1 ? 'ACTIVATE' : 'NEXT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _step == _steps.length - 1 ? _kGreen : _kCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FighterStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final String description;
  final List<String> fields;

  const _FighterStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.description,
    required this.fields,
  });
}
