// ignore_for_file: deprecated_member_use
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// DFC AstroHealth Monitor
// Tracks astronaut/deep-space crew physiological data in real time.
// Built on NASA Brahms / Ejenta framework + ISS telemetry research.
// Ref: Gupta & Ghosh (2025) â€” Advancements in health monitoring for
//      deep-space missions; NASA Spinoff 2020 (Ejenta / Brahms).
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// â”€â”€ Palette â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const Color _spaceBg = Color(0xFF030B18);
const Color _spaceCard = Color(0xFF091526);
const Color _nasaCyan = Color(0xFF00E5FF);
const Color _spaceBlue = Color(0xFF4FC3F7);
const Color _cosmicPurple = Color(0xFF9C6FFF);
const Color _marsOrange = Color(0xFFFF6D00);
const Color _alertRed = Color(0xFFFF1744);
const Color _okGreen = Color(0xFF00E676);
const Color _warnAmber = Color(0xFFFFD600);
const Color _textPrimary = Color(0xFFE8F4FD);
const Color _textSecondary = Color(0xFF8BAEC8);
const Color _textMuted = Color(0xFF4A6B85);

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AstroHealthMonitorScreen extends StatefulWidget {
  const AstroHealthMonitorScreen({super.key});
  @override
  State<AstroHealthMonitorScreen> createState() =>
      _AstroHealthMonitorScreenState();
}

class _AstroHealthMonitorScreenState extends State<AstroHealthMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedCrew = 0;

  static const _crewMembers = [
    _CrewMember('CDR Williams', 'Commander', 'ðŸš€', Color(0xFF00E5FF)),
    _CrewMember('PLT Chen', 'Pilot/FE', 'ðŸ›¸', Color(0xFF9C6FFF)),
    _CrewMember('MS Okafor', 'Mission Spec.', 'ðŸ”¬', Color(0xFF00E676)),
    _CrewMember('MS Volkov', 'Mission Spec.', 'âš—ï¸', Color(0xFFFF6D00)),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _spaceBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(innerBoxIsScrolled),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildLiveVitalsTab(),
            _buildDevicesTab(),
            _buildCMODATab(),
            _buildAIDiagnosticsTab(),
            _buildMissionLogTab(),
            _buildAlertsTab(),
            _buildHumanFactorsTab(),
          ],
        ),
      ),
    );
  }

  // â”€â”€ App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  SliverAppBar _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 220,
      backgroundColor: _spaceBg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _nasaCyan, size: 20),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF040F22), _spaceBg],
            ),
          ),
          child: Stack(
            children: [
              // Stars
              for (int i = 0; i < 40; i++)
                Positioned(
                  left: (i * 37.3) % MediaQuery.of(context).size.width,
                  top: (i * 19.7) % 200,
                  child: Container(
                    width: i % 3 == 0 ? 2 : 1,
                    height: i % 3 == 0 ? 2 : 1,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.3 + (i % 4) * 0.15,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _okGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _okGreen.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: _okGreen, size: 8),
                              SizedBox(width: 5),
                              Text(
                                'ISS UPLINK LIVE',
                                style: TextStyle(
                                  color: _okGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _nasaCyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _nasaCyan.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'ðŸ›°ï¸ ISS â€” 408 km ALT',
                            style: TextStyle(
                              color: _nasaCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'AstroHealth\nMonitor',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'NASA Â· Google Cloud Â· Ejenta AI Â· CMO-DA Â· ISS Telemetry',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Crew selector
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _crewMembers.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final m = _crewMembers[i];
                          final sel = i == _selectedCrew;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCrew = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? m.color.withValues(alpha: 0.22)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel
                                      ? m.color.withValues(alpha: 0.7)
                                      : Colors.white12,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    m.icon,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    m.name,
                                    style: TextStyle(
                                      color: sel ? m.color : _textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        indicatorColor: _nasaCyan,
        indicatorWeight: 2.5,
        labelColor: _nasaCyan,
        unselectedLabelColor: _textMuted,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
        tabs: const [
          Tab(text: '⚡ LIVE'),
          Tab(text: '🔌 DEVICES'),
          Tab(text: '🩺 CMO-DA'),
          Tab(text: '🤖 AI DIAG'),
          Tab(text: '📋 LOG'),
          Tab(text: '🚨 ALERTS'),
          Tab(text: '🌍 HUMAN'),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TAB 1 â€” LIVE VITALS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildLiveVitalsTab() {
    final crew = _crewMembers[_selectedCrew];
    return CustomScrollView(
      slivers: [
        // Mission status bar
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  crew.color.withValues(alpha: 0.15),
                  _spaceCard.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: crew.color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Text(crew.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crew.name,
                        style: TextStyle(
                          color: crew.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        crew.role,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _okGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _okGreen.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        'NOMINAL',
                        style: TextStyle(
                          color: _okGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'MET: 142:17:33',
                      style: TextStyle(color: _textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Vital signs grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverGrid(
            delegate: SliverChildListDelegate([
              _vitalCard(
                'â¤ï¸',
                'HEART RATE',
                '72',
                'bpm',
                _okGreen,
                '60â€“100 bpm',
                'ECG + PPG',
                progress: 0.72,
              ),
              _vitalCard(
                'ðŸ«',
                'RESPIRATION',
                '14',
                '/min',
                _okGreen,
                '12â€“20 /min',
                'Astroskin',
                progress: 0.7,
              ),
              _vitalCard(
                'ðŸ’‰',
                'SpOâ‚‚',
                '98',
                '%',
                _okGreen,
                '>95%',
                'BioHarness',
                progress: 0.98,
              ),
              _vitalCard(
                'ðŸŒ¡ï¸',
                'SKIN TEMP',
                '36.6',
                'Â°C',
                _okGreen,
                '36.4â€“37.2Â°C',
                'Surface IR',
                progress: 0.73,
              ),
              _vitalCard(
                'ðŸ©¸',
                'BLOOD PRESSURE',
                '118/76',
                'mmHg',
                _okGreen,
                '<130/85',
                'CBOSS',
                progress: 0.68,
              ),
              _vitalCard(
                'ðŸ§ ',
                'COGNITIVE LOAD',
                'MOD',
                '',
                _warnAmber,
                'Normal',
                'EEG Headband',
                progress: 0.55,
              ),
              _vitalCard(
                'â˜¢ï¸',
                'RAD DOSE (DAY)',
                '0.48',
                'mGy',
                _warnAmber,
                '<1.0 mGy/day',
                'Dosimeter',
                progress: 0.48,
              ),
              _vitalCard(
                'ðŸ’§',
                'HYDRATION',
                '84',
                '%',
                _okGreen,
                '>80%',
                'Sweat Sensor',
                progress: 0.84,
              ),
              _vitalCard(
                'ðŸ¦´',
                'BONE DENSITY Î”',
                '-0.3',
                '%/mo',
                _warnAmber,
                '<0.5%/mo',
                'DXA Module',
                progress: 0.3,
              ),
              _vitalCard(
                'ðŸ‹ï¸',
                'MUSCLE TONE',
                '91',
                '%',
                _okGreen,
                '>85%',
                'EMG Sleeve',
                progress: 0.91,
              ),
              _vitalCard(
                'ðŸ˜´',
                'SLEEP QUALITY',
                '76',
                '%',
                _okGreen,
                '>70%',
                'Actigraph',
                progress: 0.76,
              ),
              _vitalCard(
                'ðŸŒ¬ï¸',
                'COâ‚‚ CABIN',
                '3.8',
                'mmHg',
                _okGreen,
                '<5.3 mmHg',
                'Air Analyzer',
                progress: 0.38,
              ),
            ]),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
          ),
        ),

        // Astroskin vest visual readout
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _spaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _nasaCyan.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _nasaCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('ðŸ¦º', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Astroskin Smart Vest',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Canadian Space Agency Â· Multiparameter',
                          style: TextStyle(color: _textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _statusPill('ACTIVE', _okGreen),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Highest-rated multiparameter wearable. Tracks ECG, PPG, respiration rate, blood volume pulse, SpOâ‚‚, skin temperature, and blood pressure continuously. Currently transmitting at 250 Hz sample rate.',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _microStatPill('ECG', '250 Hz', _nasaCyan),
                    const SizedBox(width: 6),
                    _microStatPill('PPG', 'Active', _spaceBlue),
                    const SizedBox(width: 6),
                    _microStatPill('SpOâ‚‚', '98%', _okGreen),
                    const SizedBox(width: 6),
                    _microStatPill('Respiration', '14/m', _cosmicPurple),
                  ],
                ),
              ],
            ),
          ),
        ),

        // EVA spacesuit sensors
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _spaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _marsOrange.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _marsOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ðŸ‘¨â€ðŸš€',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACES Spacesuit Sensors',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'EVA Mode Â· Extravehicular Activity',
                          style: TextStyle(color: _textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _statusPill('STANDBY', _warnAmber),
                  ],
                ),
                const SizedBox(height: 12),
                _evaRow('Core Temp', '37.1Â°C', _okGreen),
                _evaRow('Suit Oâ‚‚ Level', '21.0%', _okGreen),
                _evaRow('Heart Rate', '72 bpm', _okGreen),
                _evaRow('Sweat Rate', 'Low', _okGreen),
                _evaRow('COâ‚‚ Rebreather', 'Normal', _okGreen),
                _evaRow('Suit Pressure', '29.6 kPa', _okGreen),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TAB 2 â€” DEVICES
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildDevicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('ðŸ›°ï¸ WEARABLE MONITORING SYSTEMS'),
        const SizedBox(height: 10),
        _deviceCard(
          emoji: 'ðŸ¦º',
          name: 'Astroskin Smart Vest',
          maker: 'Canadian Space Agency / Hexoskin',
          version: 'v3.1 â€” ISS Flight-Rated',
          status: DeviceStatus.active,
          specs: [
            'ECG â€” continuous 250 Hz 3-lead',
            'PPG â€” blood volume pulse',
            'SpOâ‚‚ â€” arterial oxygen saturation',
            'Respiratory inductive plethysmography',
            'Skin temperature â€” infrared + contact',
            'Accelerometer â€” 3-axis movement/posture',
            'Blood pressure â€” cuffless estimation',
          ],
          note:
              'Highest scoring system across all 8 NASA evaluation metrics. '
              'Used on ISS since 2018.',
          accentColor: _nasaCyan,
        ),
        _deviceCard(
          emoji: 'ðŸ«€',
          name: 'BioHarness 3.1',
          maker: 'Zephyr Technology / Medtronic',
          version: 'BH-3.1 EVA',
          status: DeviceStatus.active,
          specs: [
            'Heart rate â€” continuous ECG',
            'Breathing rate â€” chest expansion',
            'Posture & activity â€” 3-axis accelerometer',
            'Peak acceleration â€” fall/impact detection',
            'Bluetooth 5.0 + ANT+ dual telemetry',
            'Battery: 26h continuous use',
          ],
          note: 'Primary cardiovascular monitor during EVA prep and recovery.',
          accentColor: _spaceBlue,
        ),
        _deviceCard(
          emoji: 'ðŸ§ ',
          name: 'EEG Smart Headband',
          maker: 'DFC NeuroLab / Interaxon Muse',
          version: 'Muse 2 â€” Space Mod',
          status: DeviceStatus.active,
          specs: [
            '7-electrode EEG â€” gamma, alpha, theta, delta',
            'Cognitive load index',
            'Stress & focus scoring',
            'Sleep staging â€” REM/NREM detection',
            'Motion artifact rejection',
            'Alertness decay prediction',
          ],
          note:
              'Critical for long-duration missions â€” monitors isolation-induced '
              'cognitive decline and circadian disruption.',
          accentColor: _cosmicPurple,
        ),
        _deviceCard(
          emoji: 'ðŸ’ª',
          name: 'EMG Compression Sleeve',
          maker: 'DFC BioTech / Noraxon',
          version: 'DFC-EMG-X2',
          status: DeviceStatus.active,
          specs: [
            '8-channel surface EMG',
            'Muscle activation amplitude',
            'Fatigue index â€” median frequency shift',
            'Bilateral asymmetry detection',
            'Real-time muscle atrophy trend',
            'Integrated force estimation',
          ],
          note:
              'Microgravity causes up to 20% muscle loss in 6 months. '
              'EMG sleeve quantifies atrophy in real time.',
          accentColor: _marsOrange,
        ),

        const SizedBox(height: 20),
        _sectionHeader('â˜¢ï¸ RADIATION & ENVIRONMENT'),
        const SizedBox(height: 10),

        _deviceCard(
          emoji: 'â˜¢ï¸',
          name: 'RADPaq Personal Dosimeter',
          maker: 'Leidos / NASA JSC',
          version: 'PDM-II',
          status: DeviceStatus.active,
          specs: [
            'Galactic cosmic ray (GCR) measurement',
            'Solar particle event (SPE) alert',
            'Cumulative dose tracking â€” mGy/day',
            'Tissue-equivalent dose weighting',
            'Real-time dose rate spike alerts',
            'Career dose limit tracking',
          ],
          note:
              'Deep space missions exceed 600 mGy over 6 months. '
              'Career limit: 600 mSv for males, 400 mSv for females (NASA).',
          accentColor: _warnAmber,
        ),
        _deviceCard(
          emoji: 'ðŸŒ¬ï¸',
          name: 'COâ‚‚ / Oâ‚‚ Cabin Analyzer',
          maker: 'Hamilton Sundstrand / NASA ECLSS',
          version: 'CDRA-Mod',
          status: DeviceStatus.active,
          specs: [
            'COâ‚‚ partial pressure â€” continuous',
            'Oâ‚‚ partial pressure monitoring',
            'Cabin air quality index',
            'Toxic gas trace detection',
            'Humidity & pressure logging',
            'ECLSS integration â€” automatic scrubbing alert',
          ],
          note:
              'Elevated COâ‚‚ above 5.3 mmHg causes headaches, impaired cognition '
              'and hypercapnia. Linked to "astronaut headache syndrome".',
          accentColor: _okGreen,
        ),

        const SizedBox(height: 20),
        _sectionHeader('ðŸ©º DIAGNOSTIC & IMAGING DEVICES'),
        const SizedBox(height: 10),

        _deviceCard(
          emoji: 'ðŸ“¡',
          name: 'CBOSS Cardiovascular Monitor',
          maker: 'NASA JSC / DLR Germany',
          version: 'CBOSS-3',
          status: DeviceStatus.active,
          specs: [
            'Holter ECG â€” 24h continuous 12-lead',
            'Blood pressure ambulatory cuff',
            'Cardiac output estimation',
            'Orthostatic intolerance detection',
            'Fluid shift tracking (headward)',
            'Real-time arrhythmia detection',
          ],
          note:
              'Microgravity causes 1â€“2L of blood to shift headward, '
              'stressing the cardiovascular system from day one.',
          accentColor: _alertRed,
        ),
        _deviceCard(
          emoji: 'ðŸ¦´',
          name: 'Portable DXA Bone Scanner',
          maker: 'Hologic / NASA Ames',
          version: 'pDXA-M1',
          status: DeviceStatus.standby,
          specs: [
            'Dual-energy X-ray absorptiometry',
            'Lumbar spine & femoral neck BMD',
            'Monthly bone mineral density delta',
            'Trabecular bone quality index',
            'Fracture risk estimation (FRAX)',
            'Vitamin D + calcium correlation',
          ],
          note:
              'Astronauts lose 1â€“1.5% bone density per month in microgravity. '
              'pDXA enables onboard monitoring without Earth-side imaging.',
          accentColor: _spaceBlue,
        ),
        _deviceCard(
          emoji: 'ðŸ‘ï¸',
          name: 'SANS Ocular Monitor',
          maker: 'Heidelberg Engineering / NASA',
          version: 'HRT-S ISS',
          status: DeviceStatus.active,
          specs: [
            'Optic disc scanning â€” OCT retinal imaging',
            'Intracranial pressure estimation',
            'Choroidal thickness measurement',
            'Globe flattening detection',
            'Visual acuity auto-test',
            'Cotton wool spot / lesion detection',
          ],
          note:
              'SANS (Spaceflight-Associated Neuro-ocular Syndrome) affects '
              '~70% of long-duration astronauts â€” ICP elevation from fluid shift.',
          accentColor: _cosmicPurple,
        ),

        const SizedBox(height: 20),
        _sectionHeader('ðŸ’Š BIOCHEMISTRY & METABOLIC'),
        const SizedBox(height: 10),

        _deviceCard(
          emoji: 'ðŸ’§',
          name: 'Sweat Cortisol Patch',
          maker: 'MC10 BioStamp / GSK BioElec',
          version: 'CortPatch v2',
          status: DeviceStatus.active,
          specs: [
            'Cortisol (stress hormone) via sweat',
            'Electrolyte panel â€” Naâº, Kâº, Clâ»',
            'Lactate (exertion metabolite)',
            'Hydration state estimation',
            'Glucose approximation (Type 2 risk)',
            'Wireless NFC read-out',
          ],
          note:
              'Isolation and confinement elevate cortisol chronically. '
              'Combined with EEG â€” predicts burnout and mental health decline.',
          accentColor: _warnAmber,
        ),
        _deviceCard(
          emoji: 'ðŸ”¬',
          name: 'ISS PCR / Lab-On-Chip',
          maker: 'BioMÃ©rieux / MinION Nanopore',
          version: 'miniPCR Oxford Nano',
          status: DeviceStatus.standby,
          specs: [
            'Complete blood count (CBC) â€” point-of-care',
            'RNA pathogen sequencing â€” MinION',
            'Immune cell profiling (flow cytometry)',
            'CRP inflammation marker',
            'Microbiome sample analysis',
            'Gene expression: radiation damage markers',
          ],
          note:
              'NASA\'s BEST study showed 89 known immune pathways dysregulate '
              'in space. On-board PCR enables near-real-time immune surveillance.',
          accentColor: _okGreen,
        ),

        const SizedBox(height: 20),
        _sectionHeader('ðŸ–¥ï¸ GROUND SYSTEMS & AI'),
        const SizedBox(height: 10),

        _deviceCard(
          emoji: 'ðŸ¤–',
          name: 'Ejenta AI Health Agent',
          maker: 'Ejenta Inc. / NASA Ames',
          version: 'Brahms v4.2 â€” Exclusive License',
          status: DeviceStatus.active,
          specs: [
            'Machine learning â€” multi-parameter anomaly detection',
            'Personalized health baseline per astronaut',
            'Predictive alert: flagging 6â€“12h before critical event',
            'NASA OCA Monitoring System integration',
            'Encrypted telemetry to ISS + Mission Control',
            'Voice-activated patient queries (HIPAA-compliant)',
            'Care team distribution â€” automatic triage reports',
          ],
          note:
              'Based on NASA Brahms software (2000â€“2012), exclusively licensed to '
              'Ejenta. Powers both ISS Mission Control and DFC AstroHealth.',
          accentColor: _nasaCyan,
        ),
        _deviceCard(
          emoji: 'ðŸ“¡',
          name: 'OCA Monitoring System',
          maker: 'NASA JSC / Maarten Sierhuis',
          version: 'OCAMS 2026',
          status: DeviceStatus.active,
          specs: [
            'Real-time ISS data uplink & distribution',
            'All medical telemetry routing to flight surgeon',
            'Bandwidth-compressed deep-space packets',
            'Time-delay compensation (up to 22 min for Mars)',
            'Autonomous alert escalation when Earth link down',
            'Data redundancy across 3 satellite links',
          ],
          note:
              'In service since 2008. Automatically sorts and distributes all ISS '
              'medical data to the right flight controllers in real time.',
          accentColor: _spaceBlue,
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TAB 3 â€” CMO-DA  (NASA Ã— Google Cloud Crew Medical Officer Digital Asst)
  // Ref: TechCrunch Aug 2025 Â· Google Cloud Blog Â· WashingtonExec Aug 2025
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  // Simulated CMO-DA conversation state
  final List<_CmoMessage> _cmoMessages = [
    const _CmoMessage(
      role: 'cmoda',
      text:
          'CMO-DA online. I\'m monitoring all crew vitals in real time. '
          'Ask me anything about crew health, symptoms, medications, or '
          'emergency procedures. I\'m trained on NASA spaceflight medical '
          'literature and ISS mission data.',
      timestamp: '142:16:00',
    ),
  ];
  final _cmoInput = TextEditingController();
  bool _cmoTyping = false;

  // Simulated intelligent responses for common queries
  static const _cmoResponses = {
    'headache': '''**Headache Assessment â€” Crew Context**

**Probable cause:** Elevated cabin COâ‚‚ partial pressure. Current reading: 3.8 mmHg â€” borderline. Also consider fluid shift headache (headward fluid shifts increase intracranial pressure in microgravity).

**Immediate steps:**
1. Check COâ‚‚ scrubber status â€” verify CDRA nominal
2. Administer ibuprofen 400mg if pain >4/10
3. Increase fluid intake â€” target 2.5L/day
4. Rest in sleeping quarters for 1 hour

**SANS concern:** CDR Williams had Grade 1 optic edema at MET 120. If headache persists >6h with visual symptoms, perform immediate OCT scan.

**Communication delay:** Currently 0.4 sec (LEO). Earth-side consult available.''',

    'chest pain': '''**âš ï¸ URGENT â€” Cardiac Event Protocol**

**Immediate actions:**
1. Stop all EVA/exercise activity NOW
2. Administer aspirin 325mg (chew, do not swallow whole)
3. Apply 12-lead ECG via CBOSS â€” transmit to Flight Surgeon
4. Prepare AED â€” Module 6, Locker D4
5. Establish IV access if trained

**AI Assessment:** CBOSS Holter shows normal sinus rhythm for this crew member in last 4h. No prior cardiac history flagged. Pain may be musculoskeletal (microgravity postural strain) â€” but DO NOT assume until ECG clear.

**Contact Mission Control immediately via uplink.**''',

    'radiation': '''**Radiation Exposure Assessment**

**Current crew status:**
- CDR Williams: 22.1 mGy (142 days)
- PLT Chen: 21.8 mGy
- MS Okafor: 21.4 mGy  
- MS Volkov: 23.0 mGy â† highest, closest to advisory threshold

**NOAA solar watch:** M-class flare probability 35% next 14 days. Solar maximum window active.

**Protocol if SPE detected:**
1. All crew to Node 2 within 10 minutes
2. Shelter minimum 4 hours
3. Log additional dose in RADPaq
4. Conduct bloodwork within 48h post-event (CBC + radiation biomarkers)

**Career limit tracking:** All crew >300 mGy below NASA 600 mSv career limit. No immediate concern.''',

    'sleep': '''**Sleep Disruption Analysis â€” AI Assessment**

**Flagged crew member:** PLT Chen â€” 72h pattern detected.

**Data sources:** Actigraph + EEG headband + cortisol patch

**Findings:**
- Sleep efficiency: 68% (3-day average) â€” below 75% threshold
- REM: 14% (target >20%)
- EEG theta/alpha ratio: 1.42 (threshold: 1.30) â† elevated
- Cortisol: morning peak blunted â€” HPA axis dysregulation starting

**Interventions:**
1. Melatonin 0.5mg, 60 min before sleep â€” module med kit Alpha-3
2. Blue-light blocking goggles from MET âˆ’2h
3. Adjust sleep schedule: consolidated 8h block, 22:00â€“06:00 MET
4. Reduce caffeine after 14:00

**Prediction:** If untreated, 78% probability of significant performance impairment within 5 days.''',

    'muscle': '''**Muscle Atrophy Assessment**

Microgravity causes up to 20% muscle mass loss per 6 months without countermeasures.

**Current status (EMG Sleeve + DXA):**
- MS Okafor: Left quad fatigue index elevated 18% above baseline
- MS Volkov: Bilateral symmetry nominal
- CDR Williams: Nominal â€” adherent to ARED protocol
- PLT Chen: Minor right calf EMG amplitude decline (-8%)

**ARED Exercise Prescription (Advanced Resistive Exercise Device):**
- Frequency: 6Ã—/week minimum
- Load: 85% 1-rep max for compound movements
- Emphasis: Squat, deadlift, heel raise â€” anti-atrophy priority

**Supplementation:** Protein 1.8g/kg/day, leucine-enriched, BCAA post-workout.

**Bone note:** MS Okafor BMD trending toward upper threshold. Increase resistance training immediately.''',

    'mars': '''**Mars Mission Health Projection**

**Communication delay to Mars:** 3â€“22 minutes one-way (orbital dependent).

**CMO-DA role during blackout:**
Once beyond lunar distance, Earth-side medical consultation becomes impractical. CMO-DA operates **fully autonomously** â€” no uplink required.

**Key health risks on 2-year Mars mission:**
| Risk | Probability | Mitigation |
|---|---|---|
| Bone loss >25% | High | ARED + bisphosphonates |
| Muscle atrophy | High | Resistance exercise 6Ã—/wk |
| Cognitive decline | Moderate | Psych support, AI check-ins |
| Radiation >600 mGy | Moderate | Shielding, shelter protocols |
| SANS vision loss | Moderate | ICP monitoring, COâ‚‚ control |
| Immune supression | Moderate | Microbiome monitoring, vaccines |
| Decompression injury | Low | Pre-EVA Nâ‚‚ washout |

**CMO-DA readiness for Mars:** 94% â€” currently training on novel microgravity scenarios with Google DeepMind partnership.''',
  };

  Widget _buildCMODATab() {
    return Column(
      children: [
        // Header banner â€” NASA Ã— Google
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D2137), Color(0xFF030B18)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _nasaCyan.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // NASA badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      'ðŸ”µ  NASA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1A73E8).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'G  Google Cloud',
                      style: TextStyle(
                        color: Color(0xFF4FC3F7),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _statusPill('CMO-DA v1.0', _nasaCyan),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Crew Medical Officer Digital Assistant',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'AI medical assistant trained on NASA spaceflight literature, '
                'ISS mission data, and Google DeepMind models. Operates fully '
                'autonomously â€” no Earth uplink required.',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              // Mars delay indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _marsOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _marsOrange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Text('ðŸ”´', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT COMMS DELAY',
                            style: TextStyle(
                              color: _marsOrange,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '0.4 sec (ISS/LEO)  Â·  Moon: ~1.3 sec  Â·  Mars: 3â€“22 min',
                            style: TextStyle(color: _textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quick query chips
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final chip in [
                ('ðŸ¤• Headache', 'headache'),
                ('â¤ï¸ Chest Pain', 'chest pain'),
                ('â˜¢ï¸ Radiation', 'radiation'),
                ('ðŸ˜´ Sleep', 'sleep'),
                ('ðŸ’ª Muscle', 'muscle'),
                ('ðŸ”´ Mars Ready?', 'mars'),
              ])
                GestureDetector(
                  onTap: () => _simulateCMOQuery(chip.$1, chip.$2),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _nasaCyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _nasaCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      chip.$1,
                      style: const TextStyle(
                        color: _nasaCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Chat messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _cmoMessages.length + (_cmoTyping ? 1 : 0),
            itemBuilder: (context, i) {
              if (_cmoTyping && i == _cmoMessages.length) {
                return _typingIndicator();
              }
              final msg = _cmoMessages[i];
              return _cmoChatBubble(msg);
            },
          ),
        ),

        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: _spaceCard,
            border: Border(
              top: BorderSide(color: _nasaCyan.withValues(alpha: 0.12)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1D30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _nasaCyan.withValues(alpha: 0.2)),
                  ),
                  child: TextField(
                    controller: _cmoInput,
                    style: const TextStyle(color: _textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText:
                          'Ask CMO-DA about symptoms, medications, risks...',
                      hintStyle: TextStyle(color: _textMuted, fontSize: 12),
                    ),
                    onSubmitted: _sendCMOMessage,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _sendCMOMessage(_cmoInput.text),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _nasaCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _nasaCyan.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: _nasaCyan,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _simulateCMOQuery(String label, String key) {
    setState(() {
      _cmoMessages.add(
        _CmoMessage(
          role: 'crew',
          text: label,
          timestamp: 'MET 142:${_cmoMessages.length + 10}',
        ),
      );
      _cmoTyping = true;
    });
    _fetchCMOResponse(key, label);
  }

  Future<void> _fetchCMOResponse(String key, String context) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'australia-southeast1',
      ).httpsCallable('generateSocialPost');
      final result = await callable.call<Map<String, dynamic>>({
        'topic': 'Space crew medical query: $context',
        'tone': 'nasa_medical_officer',
        'platform': 'astrohealth_cmo',
      });
      final post = (result.data['post'] as String?) ?? '';
      if (post.isNotEmpty && mounted) {
        setState(() {
          _cmoTyping = false;
          _cmoMessages.add(
            _CmoMessage(
              role: 'cmoda',
              text: post,
              timestamp: 'MET 142:${_cmoMessages.length + 11}',
            ),
          );
        });
        return;
      }
    } catch (_) {
      // Fall through to local fallback
    }
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _cmoTyping = false;
      _cmoMessages.add(
        _CmoMessage(
          role: 'cmoda',
          text:
              _cmoResponses[key] ??
              'Processing query against spaceflight medical database...',
          timestamp: 'MET 142:${_cmoMessages.length + 11}',
        ),
      );
    });
  }

  void _sendCMOMessage(String text) {
    if (text.trim().isEmpty) return;
    _cmoInput.clear();
    final lower = text.toLowerCase();
    String responseKey = 'general';
    for (final k in _cmoResponses.keys) {
      if (lower.contains(k)) {
        responseKey = k;
        break;
      }
    }
    setState(() {
      _cmoMessages.add(
        _CmoMessage(
          role: 'crew',
          text: text,
          timestamp: 'MET 142:${_cmoMessages.length + 10}',
        ),
      );
      _cmoTyping = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _cmoTyping = false;
        _cmoMessages.add(
          _CmoMessage(
            role: 'cmoda',
            text:
                _cmoResponses[responseKey] ??
                'I have analyzed your query against NASA spaceflight medical '
                    'literature and current crew biometric data. All vitals remain '
                    'nominal. No immediate action required â€” continue standard '
                    'monitoring protocol and report any changes.',
            timestamp: 'MET 142:${_cmoMessages.length + 11}',
          ),
        );
      });
    });
  }

  Widget _cmoChatBubble(_CmoMessage msg) {
    final isAI = msg.role == 'cmoda';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAI
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _nasaCyan.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: _nasaCyan.withValues(alpha: 0.4)),
              ),
              child: const Center(
                child: Text('ðŸ¤–', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAI ? _spaceCard : _nasaCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isAI ? 4 : 12),
                  bottomRight: Radius.circular(isAI ? 12 : 4),
                ),
                border: Border.all(
                  color: isAI
                      ? _nasaCyan.withValues(alpha: 0.12)
                      : _nasaCyan.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAI)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Text(
                            'CMO-DA',
                            style: TextStyle(
                              color: _nasaCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            msg.timestamp,
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _okGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NASA Ã— Google',
                              style: TextStyle(color: _okGreen, fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isAI ? _textSecondary : _textPrimary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isAI) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _marsOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('ðŸ‘¨â€ðŸš€', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _nasaCyan.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _nasaCyan.withValues(alpha: 0.4)),
            ),
            child: const Center(
              child: Text('ðŸ¤–', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _spaceCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _nasaCyan.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _nasaCyan.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 4),
                ],
                const SizedBox(width: 8),
                const Text(
                  'CMO-DA analyzing medical database...',
                  style: TextStyle(color: _textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TAB 4 â€” AI DIAGNOSTICS (Brahms / Ejenta Framework)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildAIDiagnosticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI system header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _nasaCyan.withValues(alpha: 0.13),
                _cosmicPurple.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _nasaCyan.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _nasaCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('ðŸ¤–', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ejenta Â· Brahms AI Engine',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'NASA Technology Â· Exclusive License',
                          style: TextStyle(color: _nasaCyan, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _statusPill('LEARNING', _nasaCyan),
                      const SizedBox(height: 4),
                      const Text(
                        '47 models active',
                        style: TextStyle(color: _textMuted, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'The same AI that powers ISS Mission Control â€” now monitoring your crew. '
                'Ejenta\'s intelligent agents build a unique health baseline for each astronaut, '
                'learn their patterns over time, and predict anomalies 6â€“12 hours before they '
                'become critical events.',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _sectionHeader('ðŸ§¬ CURRENT AI ASSESSMENTS'),
        const SizedBox(height: 12),

        _aiAssessmentCard(
          crew: 'CDR Williams',
          category: 'Cardiovascular',
          status: 'NOMINAL',
          statusColor: _okGreen,
          finding:
              'Resting HR trending 3 bpm below personal baseline â€” consistent '
              'with improved cardiovascular fitness from daily ergometer protocol.',
          confidence: 94,
          recommendation:
              'Continue current CEVIS ergometer program. '
              'No intervention required.',
          sources: ['Astroskin ECG', 'CBOSS Holter', 'Activity Log'],
        ),
        _aiAssessmentCard(
          crew: 'PLT Chen',
          category: 'Cognitive Performance',
          status: 'WATCH',
          statusColor: _warnAmber,
          finding:
              'EEG theta/alpha ratio elevated over last 72h. '
              'Pattern consistent with early sleep deprivation + isolation fatigue '
              'observed in analog environment studies (6-day onset).',
          confidence: 81,
          recommendation:
              'Schedule cognitive offload session. '
              'Increase Vitamin D supplement. Review sleep schedule â€” '
              'recommend consolidated 8h block.',
          sources: [
            'EEG Headband',
            'Actigraph',
            'Cortisol Patch',
            'DFC Psych Log',
          ],
        ),
        _aiAssessmentCard(
          crew: 'MS Okafor',
          category: 'Bone & Muscle',
          status: 'WATCH',
          statusColor: _warnAmber,
          finding:
              'Monthly DXA scan shows -0.48% lumbar BMD (within limits but '
              'trending toward upper threshold). EMG fatigue index slightly elevated '
              'in left quadriceps â€” possible asymmetric loading in exercise protocol.',
          confidence: 88,
          recommendation:
              'Increase ARED resistance training frequency to 6Ã—/week. '
              'Add unilateral loading correction. '
              'Bisphosphonate prophylaxis review with Flight Surgeon.',
          sources: ['pDXA Scanner', 'EMG Sleeve', 'ARED Exercise Log'],
        ),
        _aiAssessmentCard(
          crew: 'MS Volkov',
          category: 'Radiation Exposure',
          status: 'MONITOR',
          statusColor: _marsOrange,
          finding:
              'Cumulative mission dose: 87.3 mGy (Day 142). Extrapolated '
              '6-month total: 220 mGy. Within NASA career limits but SPE season '
              'approaching solar maximum â€” proactive shielding protocols recommended.',
          confidence: 77,
          recommendation:
              'Move to Node 2 shelter during next proton storm window. '
              'Begin mission-day log for career dose planning. '
              'Schedule full blood panel for radiation biomarker panel in 7 days.',
          sources: ['RADPaq Dosimeter', 'NOAA Solar Watch', 'NASA HERA Model'],
        ),

        const SizedBox(height: 20),
        _sectionHeader('ðŸ”® PREDICTIVE MODELS'),
        const SizedBox(height: 12),

        _predictionCard(
          'Decompression Risk',
          'LOW',
          0.04,
          _okGreen,
          'Pre-EVA Nâ‚‚ washout complete. DCS probability: <4%.',
        ),
        _predictionCard(
          'SANS Progression',
          'MODERATE',
          0.31,
          _warnAmber,
          'Optic disc edema unchanged. ICP estimated 18 cmHâ‚‚O. Continue monitoring.',
        ),
        _predictionCard(
          'Immune Dysregulation',
          'LOW-MOD',
          0.22,
          _spaceBlue,
          'NK cell activity 15% below baseline. Standard latent virus reactivation risk.',
        ),
        _predictionCard(
          'Fatigue Event (48h)',
          'LOW',
          0.11,
          _okGreen,
          'Sleep efficiency 76%. Cognitive reserve adequate for mission timeline.',
        ),
        _predictionCard(
          'Orthostatic Intolerance',
          'MODERATE',
          0.35,
          _warnAmber,
          'Fluid loss 1.1L detected. Pre-landing reconditioning protocol flagged.',
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TAB 4 â€” MISSION LOG
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildMissionLogTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mission timeline
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _spaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _spaceBlue.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ðŸ“…  MISSION ELAPSED TIME',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '142 Days Â· 17 Hours Â· 33 Min',
                style: TextStyle(
                  color: _nasaCyan,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _metPill('Launch', 'Sep 3, 2025'),
                  const SizedBox(width: 8),
                  _metPill('Return (est)', 'Apr 4, 2026'),
                  const SizedBox(width: 8),
                  _metPill('EVAs', '7 completed'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionHeader('ðŸ“‹ HEALTH LOG ENTRIES'),
        const SizedBox(height: 10),
        _logEntry(
          'MET 142:10',
          'CDR Williams',
          'NOMINAL',
          _okGreen,
          'Routine vitals check. All metrics within limits. '
              'Astroskin battery at 89%. Data transmission nominal.',
        ),
        _logEntry(
          'MET 140:00',
          'PLT Chen',
          'ADVISORY',
          _warnAmber,
          'Sleep efficiency dropped to 68% (48h average). '
              'EEG shows theta elevation. Prescribed melatonin 0.5mg + light therapy.',
        ),
        _logEntry(
          'MET 138:30',
          'MS Okafor',
          'NOMINAL',
          _okGreen,
          'Monthly DXA scan completed. BMD: -0.48%/mo â€” within protocol. '
              'ARED resistance session 6/6 this week.',
        ),
        _logEntry(
          'MET 136:15',
          'MS Volkov',
          'ADVISORY',
          _marsOrange,
          'Elevated radiation reading during SPE M-class flare. '
              'Crew moved to Node 2 for 4.2 hours. Cumulative dose within limits.',
        ),
        _logEntry(
          'MET 130:00',
          'ALL CREW',
          'NOMINAL',
          _okGreen,
          'Monthly comprehensive health assessment. Lab-on-chip CBC, '
              'cortisol, CRP, immune panel. No abnormalities flagged.',
        ),
        _logEntry(
          'MET 120:00',
          'CDR Williams',
          'RESOLVED',
          _spaceBlue,
          'Mild SANS Grade 1 optic disc edema detected at Day 120. '
              'ICP: 19.2 cmHâ‚‚O. Tilted head-of-bed to 15Â° â€” resolved within 72h.',
        ),
        _logEntry(
          'MET 090:00',
          'ALL CREW',
          'NOMINAL',
          _okGreen,
          'Quarterly cardiovascular stress test. VOâ‚‚max maintained. '
              'LBNP session completed for orthostatic reconditioning.',
        ),
        _logEntry(
          'MET 001:00',
          'ALL CREW',
          'BASELINE',
          _nasaCyan,
          'Baseline health establishment. All sensors activated and '
              'calibrated. Ejenta AI generating individual health models.',
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TAB 5 â€” ALERTS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildAlertsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active alerts summary
        Row(
          children: [
            Expanded(child: _alertSummaryCard('CRITICAL', '0', _alertRed)),
            const SizedBox(width: 10),
            Expanded(child: _alertSummaryCard('WARNING', '2', _warnAmber)),
            const SizedBox(width: 10),
            Expanded(child: _alertSummaryCard('ADVISORY', '3', _marsOrange)),
          ],
        ),
        const SizedBox(height: 20),
        _sectionHeader('âš ï¸ ACTIVE WARNINGS'),
        const SizedBox(height: 12),
        _alertCard(
          level: 'WARNING',
          levelColor: _warnAmber,
          emoji: 'ðŸ§ ',
          title: 'PLT Chen â€” Cognitive Fatigue Pattern',
          time: 'MET 142:10 Â· Ongoing 72h',
          description:
              'EEG cognitive load elevated. Theta/alpha ratio: 1.42 '
              '(threshold: 1.3). Associated with 72h of sub-optimal sleep. '
              'Performance impairment risk: MODERATE.',
          action:
              'Schedule mandatory 8h rest block. Reduce EVA assignment for '
              'next 48h. Administer melatonin 0.5mg tonight.',
        ),
        _alertCard(
          level: 'WARNING',
          levelColor: _warnAmber,
          emoji: 'ðŸ¦´',
          title: 'MS Okafor â€” Bone Loss Trending High',
          time: 'MET 140:00 Â· Review Required',
          description:
              'Monthly BMD delta: -0.48%/mo. Upper safe threshold: '
              '0.5%/mo. At current trajectory, limit breached by MET 160.',
          action:
              'Increase ARED resistance training to 6Ã—/wk. '
              'Review calcium/Vitamin D supplementation. '
              'Consult with Flight Surgeon re: bisphosphonate protocol.',
        ),

        const SizedBox(height: 20),
        _sectionHeader('ðŸ“£ ADVISORIES'),
        const SizedBox(height: 12),
        _alertCard(
          level: 'ADVISORY',
          levelColor: _marsOrange,
          emoji: 'â˜¢ï¸',
          title: 'Elevated SPE Activity â€” Solar Maximum Window',
          time: 'MET 142:00 Â· 14-day watch period',
          description:
              'NOAA forecasts M-class flare probability at 35% over '
              'next 14 days. ISS shielding is adequate but proactive shelter-in-place '
              'protocol should be pre-briefed.',
          action:
              'Brief crew on Node 2 radiation shelter protocol. '
              'Verify RADPaq devices charged. Monitor NOAA daily.',
        ),
        _alertCard(
          level: 'ADVISORY',
          levelColor: _marsOrange,
          emoji: 'ðŸ‘ï¸',
          title: 'Periodic SANS Screening Due',
          time: 'MET 142:00 Â· Scheduled',
          description:
              'Monthly ocular health scan due for all crew. '
              'CDR Williams had Grade 1 edema at MET 120 â€” resolved. '
              'Ongoing monitoring required.',
          action: 'Schedule OCT scans for all 4 crew within 48h.',
        ),
        _alertCard(
          level: 'ADVISORY',
          levelColor: _marsOrange,
          emoji: 'ðŸ¦ ',
          title: 'Immune Surveillance â€” 30-Day Check Due',
          time: 'MET 142:00 Â· 8 days overdue',
          description:
              'Lab-on-chip CBC and immune panel last run MET 130. '
              'NASA protocol requires monthly immune surveillance for '
              'long-duration missions.',
          action: 'Schedule MinION PCR and CBC panel within 24h.',
        ),

        const SizedBox(height: 20),
        _sectionHeader('âœ… RECENT RESOLVED'),
        const SizedBox(height: 12),
        _alertCard(
          level: 'RESOLVED',
          levelColor: _okGreen,
          emoji: 'ðŸ«€',
          title: 'CDR Williams â€” SPE Dose Spike',
          time: 'MET 136:15 Â· RESOLVED',
          description:
              'M3.2 class solar flare. Crew sheltered in Node 2 for 4.2h. '
              'Extra dose: 0.12 mGy. Total career dose unaffected.',
          action: 'No further action. Log filed.',
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 7 — HUMAN HEALTH FACTORS (NASA ISS + Smart Devices)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHumanFactorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _hmLiveBanner(),
        const SizedBox(height: 20),
        _hmSectionLabel('5 CRITICAL HEALTH DOMAINS', _nasaCyan),
        const SizedBox(height: 12),
        _hmDomainCard(
          emoji: '🦴',
          title: 'Bone Density Loss',
          color: _warnAmber,
          rate: '-0.48% / month',
          device: 'pDXA + Astroskin',
          liveValue: '−2.4%',
          liveLabel: '5-month mission',
          why:
              'Microgravity unloads the skeleton. Without gravity stress, '
              'osteoblasts slow down and bone resorption outpaces formation. '
              'Lower-body density drops fastest (hip, lumbar spine).',
          countermeasures: [
            'ARED resistance exercise 6 days/week',
            'Vibration platform therapy',
            'Bisphosphonate pharmaceuticals',
            'Vitamin D + calcium supplementation',
          ],
          fighterLink:
              'Fighters on prolonged rest see similar unloading. '
              'Impact training, plyometrics, and weight-bearing drills '
              'are your countermeasures.',
        ),
        const SizedBox(height: 10),
        _hmDomainCard(
          emoji: '💪',
          title: 'Muscle Atrophy',
          color: _marsOrange,
          rate: '-3.2% vs baseline',
          device: 'EMG + HoloLens',
          liveValue: '−8.1%',
          liveLabel: 'leg mass',
          why:
              'Without gravity, lower-body musculature loses roughly 20% of '
              'its mass on long missions. Protein turnover decreases and fast-twitch '
              'fibers convert to slow-twitch.',
          countermeasures: [
            'CEVIS cycle ergometer cardio daily',
            'ARED advanced resistive exercise device',
            'Protein intake: 1.6–2.2 g/kg/day',
            'Neuromuscular electrical stimulation (NMES)',
          ],
          fighterLink:
              'Deload weeks and injury layoffs cause the same atrophy '
              'cascade. Maintain neural drive with isometric holds and band work.',
        ),
        const SizedBox(height: 10),
        _hmDomainCard(
          emoji: '🫀',
          title: 'Cardiovascular Deconditioning',
          color: _alertRed,
          rate: '↑ resting HR',
          device: 'ECG + BioHarness',
          liveValue: '58 bpm',
          liveLabel: 'resting HR (+4)',
          why:
              'Fluid shifts to the upper body, reducing venous return and cardiac '
              'output. Plasma volume decreases and orthostatic intolerance develops, '
              'causing dizziness upon standing post-mission.',
          countermeasures: [
            'Cardio 6 days/week (cycle + treadmill harness)',
            'Lower body negative pressure (LBNP) device',
            'Compression garments for fluid redistribution',
            'Post-landing reconditioning: 45-day protocol',
          ],
          fighterLink:
              'Overtraining syndrome mirrors cardiovascular fatigue. '
              'Track HRV daily — below baseline means reduce intensity immediately.',
        ),
        const SizedBox(height: 10),
        _hmDomainCard(
          emoji: '☢️',
          title: 'Radiation Exposure',
          color: _cosmicPurple,
          rate: '0.87 mSv / today',
          device: 'RADPaq + Canary',
          liveValue: '210 mSv',
          liveLabel: '6-month total',
          why:
              'Outside Earth\'s magnetosphere, galactic cosmic rays (GCR) and solar '
              'particle events (SPE) deliver 200× the annual surface dose. Ionising '
              'radiation damages DNA and raises long-term cancer risk.',
          countermeasures: [
            'Storm shelter shielding during SPE events',
            'Antioxidant supplementation (Vit C, E, astaxanthin)',
            'Mission duration limits (48 career months)',
            'Real-time dosimetry via RADPaq sensors',
          ],
          fighterLink:
              'Combat sports face head trauma rather than radiation, but '
              'cumulative CTE risk mirrors cumulative radiation — both are dose-dependent '
              'and need career-long monitoring.',
        ),
        const SizedBox(height: 10),
        _hmDomainCard(
          emoji: '🧠',
          title: 'Isolation & Psychological Stress',
          color: _spaceBlue,
          rate: 'Wellbeing 6.8/10',
          device: 'EEG + Ejenta AI',
          liveValue: '6.8/10',
          liveLabel: 'crew wellbeing',
          why:
              'Confinement, communication delays (up to 24 min to Mars), crew conflict, '
              'and the overview effect create unique psychological stressors. Sleep '
              'disruption compounds all other health risks.',
          countermeasures: [
            'Ejenta AI monitors behavioral health indicators',
            'Scheduled Earth contact windows and family calls',
            'Behavioral health countermeasure programs',
            'LED lighting cycles to maintain circadian rhythm',
          ],
          fighterLink:
              'Camp isolation, weight cuts, and performance anxiety are '
              'structural stressors. HRV, sleep quality, and mood tracking '
              'should be daily fight-camp metrics.',
        ),
        const SizedBox(height: 24),
        _hmSmartDevicesBanner(),
        const SizedBox(height: 20),
        _hmSectionLabel('GARMIN FENIX 8 AMOLED — LIVE BIOMETRICS', _nasaCyan),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _fenixMetric('❤️', 'Heart Rate', '58 bpm', _alertRed, 'Resting'),
            _fenixMetric('🩸', 'SpO₂', '98%', _nasaCyan, 'Blood Oxygen'),
            _fenixMetric(
              '😴',
              'Sleep Score',
              '76/100',
              _spaceBlue,
              'Last Night',
            ),
            _fenixMetric(
              '⚡',
              'Body Battery',
              '82/100',
              _warnAmber,
              'Energy Reserve',
            ),
            _fenixMetric('😓', 'Stress', '28/100', _okGreen, 'Low Stress'),
            _fenixMetric('🏃', 'VO₂ Max', '54 mL/kg', _okGreen, 'Excellent'),
            _fenixMetric('🏋️', 'Training Load', '312', _marsOrange, 'Optimal'),
            _fenixMetric(
              '💓',
              'HRV Status',
              '68 ms',
              _cosmicPurple,
              'Balanced',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _hmSectionLabel('LIVE DEVICE ECOSYSTEM', _nasaCyan),
        const SizedBox(height: 12),
        _hmDeviceRow(
          '⌚',
          'Garmin Fenix 8 AMOLED',
          'HR, SpO₂, HRV, Body Battery, Sleep, VO₂Max, Training Load',
          _nasaCyan,
          true,
        ),
        _hmDeviceRow(
          '🧬',
          'Astroskin Smart Shirt',
          'Continuous ECG, respiratory rate, SpO₂, activity, skin temp',
          _okGreen,
          true,
        ),
        _hmDeviceRow(
          '🫀',
          'Zephyr BioHarness',
          'Heart rate zone, breathing rate, posture, acceleration',
          _spaceBlue,
          true,
        ),
        _hmDeviceRow(
          '🧠',
          'Muse 2 EEG Headband',
          'Real-time brainwave activity, meditation quality, focus score',
          _cosmicPurple,
          true,
        ),
        _hmDeviceRow(
          '🌡️',
          'CORE Body Temp Sensor',
          'Continuous core temperature without rectal probe',
          _marsOrange,
          true,
        ),
        _hmDeviceRow(
          '💊',
          'RADPaq Dosimeter',
          'Cumulative radiation dose, daily mSv, SPE alerts',
          _cosmicPurple,
          false,
        ),
        _hmDeviceRow(
          '🤖',
          'Ejenta AI Health Agent',
          'Behavioral health monitoring via wearable pattern analysis',
          _warnAmber,
          false,
        ),
        const SizedBox(height: 24),
        _hmFighterCard(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _hmLiveBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF001A2E), Color(0xFF00151F)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _nasaCyan.withAlpha(100)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: _okGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ISS EXPEDITION LIVE',
                  style: TextStyle(
                    color: _nasaCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Altitude: 408 km  •  Speed: 27,600 km/h  •  Crew: 7',
                  style: TextStyle(color: Color(0xFF8BADB8), fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'MET',
                style: TextStyle(color: Color(0xFF8BADB8), fontSize: 9),
              ),
              Text(
                'D+${((DateTime.now().millisecondsSinceEpoch - 1704067200000) / 86400000).floor()}',
                style: const TextStyle(
                  color: _nasaCyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hmSectionLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }

  Widget _hmDomainCard({
    required String emoji,
    required String title,
    required Color color,
    required String rate,
    required String device,
    required String liveValue,
    required String liveLabel,
    required String why,
    required List<String> countermeasures,
    required String fighterLink,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF091526),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      rate,
                      style: TextStyle(
                        color: color.withAlpha(180),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    liveValue,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    liveLabel,
                    style: const TextStyle(
                      color: Color(0xFF8BADB8),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            why,
            style: const TextStyle(
              color: Color(0xFF8BADB8),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: countermeasures
                .map(
                  (c) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: color.withAlpha(60),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: color.withAlpha(200),
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withAlpha(15),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: const Color(0xFF4FC3F7).withAlpha(60),
              ),
            ),
            child: Row(
              children: [
                const Text('🥊', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fighterLink,
                    style: const TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.sensors, color: Color(0xFF8BADB8), size: 12),
              const SizedBox(width: 5),
              Text(
                'Device: $device',
                style: const TextStyle(color: Color(0xFF8BADB8), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hmSmartDevicesBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001830), Color(0xFF0A0A1A)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _nasaCyan.withAlpha(80)),
      ),
      child: Column(
        children: [
          const Text(
            'SMART DEVICES ARE THE FUTURE',
            style: TextStyle(
              color: _nasaCyan,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'NASA astronauts wear continuous biometric monitors 24/7. '
            'These same technologies — from wrist wearables to smart shirts — '
            'are now available to every combat athlete. Real-time data transforms '
            'training, recovery, and fight-camp management.',
            style: TextStyle(
              color: Color(0xFF8BADB8),
              fontSize: 12,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statPill('Real-Time HR', _alertRed),
              _statPill('Sleep Science', _spaceBlue),
              _statPill('HRV Guided', _okGreen),
              _statPill('AI Analysis', _cosmicPurple),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/smart-devices'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF4FC3F7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CONNECT ALL DEVICES TO DFC',
                    style: TextStyle(
                      color: Color(0xFF030B18),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Color(0xFF030B18), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _fenixMetric(
    String emoji,
    String label,
    String value,
    Color color,
    String sub,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF091526),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8BADB8),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(sub, style: TextStyle(color: color.withAlpha(150), fontSize: 9)),
        ],
      ),
    );
  }

  Widget _hmDeviceRow(
    String emoji,
    String name,
    String desc,
    Color color,
    bool connected,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF091526),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFFF0F6FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF8BADB8),
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: (connected ? _okGreen : const Color(0xFF8BADB8)).withAlpha(
                25,
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: (connected ? _okGreen : const Color(0xFF8BADB8))
                    .withAlpha(80),
              ),
            ),
            child: Text(
              connected ? 'LIVE' : 'OFF',
              style: TextStyle(
                color: connected ? _okGreen : const Color(0xFF8BADB8),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hmFighterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1520), Color(0xFF070E18)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _warnAmber.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🚀', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'SPACE ↔ FIGHTER PARALLELS',
                style: TextStyle(
                  color: _warnAmber,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _parallelRow('Bone unloading', '=', 'Extended rest/layoff'),
          _parallelRow('Muscle atrophy', '=', 'Post-surgery deload'),
          _parallelRow('Fluid shifts', '=', 'Water cut dehydration'),
          _parallelRow('Cumulative radiation', '=', 'Cumulative head trauma'),
          _parallelRow('Isolation stress', '=', 'Fight camp confinement'),
          const SizedBox(height: 12),
          const Text(
            'Both astronauts and fighters operate at the edge of human performance. '
            'NASA\'s 60 years of human factors research directly informs modern '
            'combat sports medicine.',
            style: TextStyle(
              color: Color(0xFF8BADB8),
              fontSize: 11,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _parallelRow(String left, String eq, String right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: const TextStyle(
                color: _nasaCyan,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _warnAmber.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              eq,
              style: const TextStyle(
                color: _warnAmber,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              right,
              style: const TextStyle(
                color: Color(0xFFFF6D00),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _vitalCard(
    String emoji,
    String label,
    String value,
    String unit,
    Color color,
    String range,
    String sensor, {
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _spaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$sensor Â· $range',
            style: const TextStyle(color: _textMuted, fontSize: 9),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _deviceCard({
    required String emoji,
    required String name,
    required String maker,
    required String version,
    required DeviceStatus status,
    required List<String> specs,
    required String note,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _spaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      maker,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      version,
                      style: const TextStyle(color: _textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              _statusPill(
                status == DeviceStatus.active
                    ? 'ACTIVE'
                    : status == DeviceStatus.standby
                    ? 'STANDBY'
                    : 'OFFLINE',
                status == DeviceStatus.active
                    ? _okGreen
                    : status == DeviceStatus.standby
                    ? _warnAmber
                    : _alertRed,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...specs.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'â–¸ ',
                    style: TextStyle(color: accentColor, fontSize: 10),
                  ),
                  Expanded(
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.15)),
            ),
            child: Text(
              'ðŸ’¡ $note',
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiAssessmentCard({
    required String crew,
    required String category,
    required String status,
    required Color statusColor,
    required String finding,
    required int confidence,
    required String recommendation,
    required List<String> sources,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _spaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crew,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      category,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _statusPill(status, statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            finding,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          // Confidence bar
          Row(
            children: [
              const Text(
                'AI Confidence: ',
                style: TextStyle(color: _textMuted, fontSize: 11),
              ),
              Text(
                '$confidence%',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: confidence / 100,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _okGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _okGreen.withValues(alpha: 0.15)),
            ),
            child: Text(
              'âš•ï¸ $recommendation',
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: sources
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _nasaCyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _nasaCyan.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(color: _nasaCyan, fontSize: 9.5),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _predictionCard(
    String label,
    String risk,
    double value,
    Color color,
    String note,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _spaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                risk,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logEntry(
    String met,
    String crew,
    String status,
    Color statusColor,
    String detail,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _spaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                met,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              _statusPill(status, statusColor),
              const Spacer(),
              Text(
                crew,
                style: const TextStyle(color: _textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard({
    required String level,
    required Color levelColor,
    required String emoji,
    required String title,
    required String time,
    required String description,
    required String action,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _spaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: levelColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(color: _textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              _statusPill(level, levelColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: levelColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              'ðŸŽ¯ $action',
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertSummaryCard(String level, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            level,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _evaRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _textSecondary, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _microStatPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _metPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 9)),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// DATA CLASSES
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

enum DeviceStatus { active, standby, offline }

class _CrewMember {
  final String name, role, icon;
  final Color color;
  const _CrewMember(this.name, this.role, this.icon, this.color);
}

class _CmoMessage {
  final String role; // 'cmoda' | 'crew'
  final String text;
  final String timestamp;
  const _CmoMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}
