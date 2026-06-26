import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_card.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC SMART DEVICES HUB
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Beats: Apple Health · Fitbit · Garmin Connect · WHOOP · Oura
///
/// Fighter-grade biometrics dashboard:
///  DEVICES  •  VITALS  •  TRENDS  •  FIGHTER METRICS  •  MARKETPLACE
/// ═══════════════════════════════════════════════════════════════════════════

class SmartDevicesHubScreen extends StatefulWidget {
  const SmartDevicesHubScreen({super.key});

  @override
  State<SmartDevicesHubScreen> createState() => _SmartDevicesHubScreenState();
}

class _SmartDevicesHubScreenState extends State<SmartDevicesHubScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  int _selectedDevice = 0;

  // ── simulated live vitals ──────────────────────────────────────────────
  final _rng = math.Random();
  late int _bpm;
  late int _hrv;
  late int _steps;
  late double _spo2;
  late double _recovery;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _refreshVitals();
  }

  void _refreshVitals() {
    setState(() {
      _bpm = 62 + _rng.nextInt(20);
      _hrv = 45 + _rng.nextInt(30);
      _steps = 6800 + _rng.nextInt(5000);
      _spo2 = 96 + _rng.nextDouble() * 3;
      _recovery = 60 + _rng.nextDouble() * 38;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── devices data ─────────────────────────────────────────────────────
  static const _devices = [
    _Device(
      '⌚',
      'Apple Watch Ultra 2',
      'Connected',
      Color(0xFF1E90FF),
      [
        'Heart Rate',
        'SpO2',
        'ECG',
        'Sleep',
        'Steps',
        'Calories',
        'HRV',
        'Hypertension Alerts (TGA)',
      ],
      'OAuth via Apple HealthKit',
    ),
    _Device(
      '🏃',
      'Garmin Fenix 8',
      'Connected',
      Color(0xFF00C2FF),
      ['Running Dynamics', 'HRV', 'Body Battery', 'Stress', 'Sleep'],
      'OAuth via Garmin Health API',
    ),
    _Device('💪', 'WHOOP 5.0', 'Connected', Color(0xFF00FF87), [
      'Strain Score',
      'Recovery %',
      'HRV',
      'Skin Temp',
      'SpO2',
    ], 'OAuth via WHOOP API'),
    _Device('💍', 'Oura Ring 4', 'Paired', Color(0xFF9D4EDD), [
      'Readiness',
      'Sleep Stages',
      'HRV',
      'Temperature',
      'Activity',
    ], 'OAuth via Oura API'),
    _Device('📱', 'Fitbit Charge 6', 'Paired', Color(0xFF4ECDC4), [
      'Steps',
      'Heart Rate',
      'Active Zone',
      'Sleep',
      'SpO2',
    ], 'OAuth via Fitbit Web API'),
    _Device('❤️', 'Polar H10', 'Bluetooth', Color(0xFFFF4757), [
      'ECG (medical-grade)',
      'HRV',
      'Heart Rate',
      'VO2 Max estimate',
    ], 'Bluetooth BLE 5.0'),
    _Device('🔵', 'COROS PACE 3', 'Paired', Color(0xFF5352ED), [
      'Training Load',
      'VO2 Max',
      'Race Predictor',
      'GPS',
      'HRV',
    ], 'OAuth via COROS API'),
    _Device('🟢', 'Google Fit', 'Synced', Color(0xFF2ED573), [
      'Steps',
      'Heart Points',
      'Sleep',
      'Weight',
      'Move Minutes',
    ], 'OAuth via Google Fit API'),
    _Device('⚖️', 'Wyze Scale X', 'Bluetooth', Color(0xFFFFD700), [
      'Weight',
      'BMI',
      'Body Fat %',
      'Muscle Mass',
      'Bone Mass',
    ], 'Bluetooth + Wyze App'),
    _Device(
      '🥊',
      'Corner 3 Smart Gloves',
      'Bluetooth',
      Color(0xFFFF6B00),
      ['Punch Speed (m/s)', 'Power (Newtons)', 'Combo Count', 'Fatigue Index'],
      'BLE + DFC AirBridge',
    ),
    _Device(
      '🦷',
      'FightSense Mouthguard',
      'Bluetooth',
      Color(0xFFFF4757),
      ['Head Impact G-force', 'Concussion Risk', 'Jaw Pressure', 'Bite Force'],
      'BLE + DFC AirBridge',
    ),
    _Device('🫀', 'Wahoo TICKR X', 'Bluetooth', Color(0xFFFF6B00), [
      'HR Zone',
      'Running Cadence',
      'Vertical Oscillation',
      'HRV',
    ], 'Bluetooth BLE + ANT+'),
    _Device(
      '🧬',
      'Astroskin Smart Shirt',
      'Bluetooth',
      Color(0xFF00E5FF),
      ['Continuous ECG', 'Respiratory Rate', 'SpO2', 'Skin Temp', 'Activity'],
      'BLE + DFC AirBridge',
    ),
    _Device('🫁', 'Zephyr BioHarness', 'Bluetooth', Color(0xFF4FC3F7), [
      'HR Zone',
      'Breathing Rate',
      'Posture',
      'Acceleration',
      'Peak HR',
    ], 'BLE + DFC AirBridge'),
    _Device(
      '🧠',
      'Muse 2 EEG Headband',
      'Bluetooth',
      Color(0xFF9C6FFF),
      ['Brainwave Activity', 'Meditation Score', 'Focus Index', 'Calm %'],
      'BLE + DFC Mind Center',
    ),
    _Device(
      '🌡️',
      'CORE Body Temp Sensor',
      'Bluetooth',
      Color(0xFFFF6D00),
      ['Core Temperature', 'Temp Trend', 'Heat Stress Index', 'Recovery Temp'],
      'BLE + DFC AirBridge',
    ),
    _Device(
      '🏋️',
      'Zephyr BioModule 3',
      'Bluetooth',
      Color(0xFF00E676),
      ['Muscle Readiness', 'EMG Signal', 'Fatigue Level', 'Power Output'],
      'BLE + DFC Performance',
    ),
    _Device('💉', 'Abbott Libre 3 CGM', 'Bluetooth', Color(0xFFFFD600), [
      'Blood Glucose',
      'Glucose Trend',
      'Time in Range',
      'Alert Thresholds',
    ], 'BLE + LibreLink API'),
  ];

  // ── marketplace smart devices ──────────────────────────────────────────
  static const _marketItems = [
    _MarketDevice(
      'Apple Watch Ultra 2',
      '⌚',
      '\$799',
      '★ 4.9',
      'GPS/Cell, Titanium, 60hr battery. TGA-approved hypertension monitoring + crash detection + ECG.',
      Color(0xFF1E90FF),
      'NEW',
    ),
    _MarketDevice(
      'WHOOP 5.0',
      '💪',
      '\$239/yr',
      '★ 4.8',
      'No screen, all data. HRV + strain tracking purpose-built for combat athletes.',
      Color(0xFF00FF87),
      'HOT',
    ),
    _MarketDevice(
      'Oura Ring 4',
      '💍',
      '\$349',
      '★ 4.7',
      'Sleep & readiness scoring. Tiny titanium ring tracks HRV, temp & SpO2 overnight.',
      Color(0xFF9D4EDD),
      'TRENDING',
    ),
    _MarketDevice(
      'Garmin Fenix 8 Solar',
      '🏃',
      '\$899',
      '★ 4.8',
      'Solar charging, 29-day battery, military-spec toughness. Full fighter analytics suite.',
      Color(0xFF00C2FF),
      'PRO',
    ),
    _MarketDevice(
      'Polar H10 Chest Strap',
      '❤️',
      '\$89',
      '★ 4.9',
      'Most accurate HR sensor on the planet. Medical-grade ECG. Pairs with any app.',
      Color(0xFFFF4757),
      'BEST BUY',
    ),
    _MarketDevice(
      'Fitbit Charge 6',
      '📱',
      '\$159',
      '★ 4.5',
      'Google Pixel Watch integration, ECG app, 7-day battery. Best value wearable 2026.',
      Color(0xFF4ECDC4),
      'VALUE',
    ),
    _MarketDevice(
      'Corner 3 Smart Gloves',
      '🥊',
      '\$299',
      '★ 4.6',
      'Real-time punch speed, power & combo analytics. Pairs directly with DFC Body Monitor.',
      Color(0xFFFF6B00),
      'DFC PICK',
    ),
    _MarketDevice(
      'FightSense Mouthguard',
      '🦷',
      '\$449',
      '★ 4.4',
      'Detects head impacts in real time. Concussion risk scoring. Approved for sparring.',
      Color(0xFFFF4757),
      'FIGHTER',
    ),
    _MarketDevice(
      'Wyze Scale X',
      '⚖️',
      '\$39',
      '★ 4.7',
      'Body fat, muscle mass, bone density. Syncs with DFC Body Monitor + Google Fit.',
      Color(0xFFFFD700),
      'BUDGET',
    ),
    _MarketDevice(
      'COROS PACE 3',
      '🔵',
      '\$229',
      '★ 4.8',
      '17-day battery, GPS, VO2 Max, Training Load. Lightest GPS watch in the world.',
      Color(0xFF5352ED),
      'RUNNER',
    ),
    _MarketDevice(
      'Wahoo TICKR X',
      '🫀',
      '\$79',
      '★ 4.6',
      'ANT+ and Bluetooth HR strap with running efficiency metrics. Gym & ring ready.',
      Color(0xFFFF6B00),
      'GYM',
    ),
    _MarketDevice(
      'Xiaomi Mi Band 9 Pro',
      '💚',
      '\$49',
      '★ 4.3',
      'Best budget tracker. 24hr HR, SpO2, sleep, 14-day battery. Great for daily fighters.',
      Color(0xFF2ED573),
      'ENTRY',
    ),
    _MarketDevice(
      'Astroskin Smart Shirt',
      '🧬',
      '\$499',
      '★ 4.7',
      'NASA-grade continuous ECG, SpO2 & respiration worn 24/7. Used on the ISS. Now for fighters.',
      Color(0xFF00E5FF),
      'NASA TECH',
    ),
    _MarketDevice(
      'Zephyr BioHarness',
      '🫁',
      '\$349',
      '★ 4.6',
      'Military & elite sports HR monitoring. Posture, breathing, acceleration. DFC compatible.',
      Color(0xFF4FC3F7),
      'ELITE',
    ),
    _MarketDevice(
      'Muse 2 EEG Headband',
      '🧠',
      '\$249',
      '★ 4.5',
      'Real-time brainwave focus training. Pre-fight mental prep. Stress & calm scoring.',
      Color(0xFF9C6FFF),
      'MINDSET',
    ),
    _MarketDevice(
      'CORE Body Temp Sensor',
      '🌡️',
      '\$139',
      '★ 4.6',
      'First continuous core temperature without rectal probe. Stick to chest, fight smart.',
      Color(0xFFFF6D00),
      'HEAT SAFE',
    ),
    _MarketDevice(
      'Abbott Libre 3 CGM',
      '💉',
      '\$89/mo',
      '★ 4.8',
      'Continuous blood glucose monitoring. Understand fuelling & recovery at the cellular level.',
      Color(0xFFFFD600),
      'FUEL INTEL',
    ),
    _MarketDevice(
      'Garmin Fenix 8 AMOLED',
      '⌚',
      '\$1,099',
      '★ 4.9',
      '47mm AMOLED, Body Battery, HRV, SpO2, Training Load, Stress. The pro fighter watch.',
      Color(0xFF00C2FF),
      'FIGHTER PRO',
    ),
  ];

  // ── 7-day chart data ───────────────────────────────────────────────────
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _hrData = [72, 68, 74, 71, 66, 69, 65];
  static const _stepsData = [6200, 8400, 7100, 9300, 7800, 11200, 8900];
  static const _sleepData = [6.5, 7.2, 6.8, 7.5, 8.0, 7.8, 7.1];
  static const _hrvData = [48, 52, 45, 55, 58, 61, 57];
  static const _recoveryData = [71, 78, 65, 82, 85, 90, 83];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildDevicesTab(),
                  _buildVitalsTab(),
                  _buildTrendsTab(),
                  _buildFighterMetricsTab(),
                  _buildMarketplaceTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E90FF).withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          const Text('📡', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DFC SMART DEVICES HUB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'All your wearables. One fighter dashboard.',
                  style: TextStyle(
                    color: Color(0xFF1E90FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _refreshVitals,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF1E90FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1E90FF).withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sync, color: Color(0xFF1E90FF), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'SYNC',
                    style: TextStyle(
                      color: Color(0xFF1E90FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB BAR ────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: TabBar(
        controller: _tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: const Color(0xFF1E90FF).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF1E90FF),
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '📡 DEVICES'),
          Tab(text: '❤️ VITALS'),
          Tab(text: '📊 TRENDS'),
          Tab(text: '🥊 FIGHTER'),
          Tab(text: '🛒 SHOP'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 1 — DEVICES
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildDevicesTab() {
    return CustomScrollView(
      slivers: [
        // Live status banner
        SliverToBoxAdapter(child: _statusBanner()),
        // Device grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.55,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _devices.length,
            itemBuilder: (ctx, i) => _DeviceCard(
              device: _devices[i],
              selected: _selectedDevice == i,
              onTap: () => setState(() => _selectedDevice = i),
            ),
          ),
        ),
        // Selected device detail
        SliverToBoxAdapter(
          child: _DeviceDetailPanel(device: _devices[_selectedDevice]),
        ),
        // AstroHealth entry banner
        SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () => context.push('/astro-health'),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00E5FF).withValues(alpha: 0.14),
                    const Color(0xFF030B18).withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🚀', style: TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AstroHealth Monitor',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'NASA · ISS · Ejenta AI · Deep Space Crew Health',
                          style: TextStyle(
                            color: Color(0xFF8BAEC8),
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Monitor astronaut vitals — ECG, SpO₂, radiation dose, '
                          'bone density, SANS, cognitive load, and more.',
                          style: TextStyle(
                            color: Color(0xFF4A6B85),
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF00E5FF),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Add device CTA
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: OutlinedButton.icon(
              icon: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF1E90FF),
                size: 18,
              ),
              label: const Text(
                'CONNECT NEW DEVICE',
                style: TextStyle(
                  color: Color(0xFF1E90FF),
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1E90FF), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showConnectSheet(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B38), Color(0xFF0A0E18)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1E90FF).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          _statusDot(const Color(0xFF00FF87)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '${0 + 4} devices active  •  Last synced just now',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF87).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ALL SYSTEMS GO',
              style: TextStyle(
                color: Color(0xFF00FF87),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(Color c) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      color: c,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)],
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 2 — VITALS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildVitalsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Big live HR
        _LiveVitalCard(
          label: 'HEART RATE',
          value: '$_bpm',
          unit: 'bpm',
          icon: '❤️',
          color: const Color(0xFFFF4757),
          status: _bpm < 70 ? 'Resting Zone' : 'Active Zone',
          statusColor: _bpm < 70
              ? const Color(0xFF2ED573)
              : const Color(0xFFFFD700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _LiveVitalCard(
                label: 'HRV',
                value: '$_hrv',
                unit: 'ms',
                icon: '🫀',
                color: const Color(0xFF9D4EDD),
                status: _hrv > 55 ? 'Excellent' : 'Good',
                statusColor: _hrv > 55
                    ? const Color(0xFF2ED573)
                    : const Color(0xFF1E90FF),
                compact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LiveVitalCard(
                label: 'SpO2',
                value: _spo2.toStringAsFixed(1),
                unit: '%',
                icon: '🩸',
                color: const Color(0xFF4ECDC4),
                status: _spo2 > 97 ? 'Normal' : 'Monitor',
                statusColor: _spo2 > 97
                    ? const Color(0xFF2ED573)
                    : const Color(0xFFFFD700),
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _LiveVitalCard(
                label: 'STEPS TODAY',
                value: _steps > 999
                    ? '${(_steps / 1000).toStringAsFixed(1)}k'
                    : '$_steps',
                unit: 'steps',
                icon: '👟',
                color: const Color(0xFF00C2FF),
                status: _steps > 10000 ? 'Goal Reached!' : 'In Progress',
                statusColor: _steps > 10000
                    ? const Color(0xFF2ED573)
                    : const Color(0xFFFFD700),
                compact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LiveVitalCard(
                label: 'RECOVERY',
                value: _recovery.toStringAsFixed(0),
                unit: '%',
                icon: '⚡',
                color: const Color(0xFF00FF87),
                status: _recovery > 80
                    ? 'Ready to Train'
                    : _recovery > 60
                    ? 'Light Training'
                    : 'Rest Day',
                statusColor: _recovery > 80
                    ? const Color(0xFF2ED573)
                    : _recovery > 60
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFFF4757),
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Sleep last night
        DFCCard(
          accent: const Color(0xFF9D4EDD),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🌙  SLEEP LAST NIGHT',
                  style: TextStyle(
                    color: Color(0xFF9D4EDD),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _sleepStage('Deep', '1h 42m', const Color(0xFF5352ED)),
                    _sleepStage('REM', '2h 08m', const Color(0xFF9D4EDD)),
                    _sleepStage('Light', '3h 15m', const Color(0xFF4ECDC4)),
                    _sleepStage('Awake', '12m', const Color(0xFFFF4757)),
                  ],
                ),
                const SizedBox(height: 12),
                // Sleep bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 20,
                          child: Container(color: const Color(0xFF5352ED)),
                        ),
                        Expanded(
                          flex: 25,
                          child: Container(color: const Color(0xFF9D4EDD)),
                        ),
                        Expanded(
                          flex: 38,
                          child: Container(color: const Color(0xFF4ECDC4)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(color: const Color(0xFFFF4757)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: 7h 17m',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Score: 84/100',
                      style: TextStyle(
                        color: Color(0xFF2ED573),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Stress & Body Battery
        const Row(
          children: [
            Expanded(
              child: _GaugeMini(
                label: 'Stress',
                value: 28,
                max: 100,
                color: Color(0xFFFFD700),
                unit: '/100',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _GaugeMini(
                label: 'Body Battery',
                value: 74,
                max: 100,
                color: Color(0xFF00C2FF),
                unit: '/100',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _GaugeMini(
                label: 'VO₂ Max',
                value: 52,
                max: 80,
                color: Color(0xFF00FF87),
                unit: ' ml/kg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // ── Apple Watch Hypertension Monitoring Card ──────────────────
        const _AppleWatchHypertensionCard(),
      ],
    );
  }

  Widget _sleepStage(String label, String time, Color c) => Expanded(
    child: Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w700),
        ),
        Text(time, style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 3 — TRENDS (bar / line charts using CustomPaint)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildTrendsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TrendChart(
          title: '❤️  HEART RATE — 7 Day Average',
          data: _hrData.map((v) => v.toDouble()).toList(),
          labels: _days,
          color: const Color(0xFFFF4757),
          unit: 'bpm',
          minY: 55,
          maxY: 90,
        ),
        const SizedBox(height: 14),
        _TrendChart(
          title: '🫀  HRV — 7 Day',
          data: _hrvData.map((v) => v.toDouble()).toList(),
          labels: _days,
          color: const Color(0xFF9D4EDD),
          unit: 'ms',
          minY: 30,
          maxY: 80,
        ),
        const SizedBox(height: 14),
        _TrendChart(
          title: '👟  STEPS — 7 Day',
          data: _stepsData.map((v) => v.toDouble()).toList(),
          labels: _days,
          color: const Color(0xFF00C2FF),
          unit: 'k steps',
          minY: 0,
          maxY: 15000,
          divideBy: 1000,
        ),
        const SizedBox(height: 14),
        const _TrendChart(
          title: '🌙  SLEEP — 7 Day',
          data: _sleepData,
          labels: _days,
          color: Color(0xFF9D4EDD),
          unit: 'hrs',
          minY: 4,
          maxY: 10,
        ),
        const SizedBox(height: 14),
        _TrendChart(
          title: '⚡  RECOVERY SCORE — 7 Day',
          data: _recoveryData.map((v) => v.toDouble()).toList(),
          labels: _days,
          color: const Color(0xFF00FF87),
          unit: '%',
          minY: 40,
          maxY: 100,
        ),
        const SizedBox(height: 16),
        // Weekly summary card
        DFCCard(
          accent: const Color(0xFF1E90FF),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📈  WEEKLY SUMMARY',
                  style: TextStyle(
                    color: Color(0xFF1E90FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                _summaryRow(
                  'Avg Heart Rate',
                  '69 bpm',
                  const Color(0xFFFF4757),
                ),
                _summaryRow('Avg HRV', '53 ms', const Color(0xFF9D4EDD)),
                _summaryRow('Total Steps', '59,900', const Color(0xFF00C2FF)),
                _summaryRow('Avg Sleep', '7.3 hrs', const Color(0xFF5352ED)),
                _summaryRow('Avg Recovery', '79%', const Color(0xFF00FF87)),
                _summaryRow(
                  'Active Minutes',
                  '312 min',
                  const Color(0xFFFFD700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 16,
          color: c,
          margin: const EdgeInsets.only(right: 10),
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 4 — FIGHTER METRICS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildFighterMetricsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI Readiness Score
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D2137), Color(0xFF0A0E18)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00FF87).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              const Text(
                '⚡ FIGHT READINESS SCORE',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _recovery.toStringAsFixed(0),
                style: TextStyle(
                  color: _recovery > 80
                      ? const Color(0xFF00FF87)
                      : _recovery > 60
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFFF4757),
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Text(
                _recovery > 80
                    ? 'READY TO FIGHT'
                    : _recovery > 60
                    ? 'LIGHT TRAINING ONLY'
                    : 'REST & RECOVER',
                style: TextStyle(
                  color: _recovery > 80
                      ? const Color(0xFF00FF87)
                      : _recovery > 60
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFFF4757),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Calculated from HRV + Sleep + Recovery + Stress index',
                style: TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Combat metrics grid
        const Text(
          '🥊  COMBAT PERFORMANCE METRICS',
          style: TextStyle(
            color: DesignTokens.neonRed,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: const [
            _FighterMetricCard(
              label: 'Punch Speed',
              value: '9.4',
              unit: 'm/s',
              icon: '🥊',
              color: Color(0xFFFF6B00),
            ),
            _FighterMetricCard(
              label: 'Punch Power',
              value: '847',
              unit: 'N',
              icon: '💥',
              color: Color(0xFFFF4757),
            ),
            _FighterMetricCard(
              label: 'Reaction Time',
              value: '182',
              unit: 'ms',
              icon: '⚡',
              color: Color(0xFFFFD700),
            ),
            _FighterMetricCard(
              label: 'Kick Force',
              value: '1,240',
              unit: 'N',
              icon: '🦵',
              color: Color(0xFF9D4EDD),
            ),
            _FighterMetricCard(
              label: 'Combo Count',
              value: '47',
              unit: 'today',
              icon: '🔄',
              color: Color(0xFF00C2FF),
            ),
            _FighterMetricCard(
              label: 'Fatigue Index',
              value: '22',
              unit: '/100',
              icon: '🔋',
              color: Color(0xFF2ED573),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Head impact monitoring
        DFCCard(
          accent: const Color(0xFFFF4757),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🪖  HEAD IMPACT MONITORING',
                  style: TextStyle(
                    color: Color(0xFFFF4757),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Via FightSense Mouthguard  •  Last session: sparring',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _impactStat(
                      'Max G-Force',
                      '14.2 g',
                      const Color(0xFFFFD700),
                    ),
                    _impactStat(
                      'Avg G-Force',
                      '8.1 g',
                      const Color(0xFF2ED573),
                    ),
                    _impactStat('Impacts', '23', const Color(0xFF1E90FF)),
                    _impactStat('Risk', 'LOW', const Color(0xFF2ED573)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2ED573).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text('✅ ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          'No concerning impact patterns detected. Concussion risk: LOW.',
                          style: TextStyle(
                            color: Color(0xFF2ED573),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Training load analysis
        DFCCard(
          accent: const Color(0xFFFFD700),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊  TRAINING LOAD ANALYSIS',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                _loadBar('Acute Load (7d)', 0.78, const Color(0xFFFF6B00)),
                const SizedBox(height: 8),
                _loadBar('Chronic Load (28d)', 0.62, const Color(0xFF00C2FF)),
                const SizedBox(height: 8),
                _loadBar('Monotony Index', 0.35, const Color(0xFF2ED573)),
                const SizedBox(height: 12),
                const Text(
                  'ATL/CTL Ratio: 1.26  •  Strain: Moderate  •  Recommendation: 1 rest day before next hard session.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _impactStat(String label, String value, Color c) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    ),
  );

  Widget _loadBar(String label, double pct, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          Text(
            '${(pct * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          valueColor: AlwaysStoppedAnimation(c),
          minHeight: 7,
        ),
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 5 — MARKETPLACE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildMarketplaceTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B00).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🛒  DFC SMART DEVICE STORE',
                  style: TextStyle(
                    color: Color(0xFFFF6B00),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Buy, sell & trade wearables, smart gloves, mouthguards & health tech — all synced with your DFC athlete profile.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: _marketItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _MarketDeviceCard(item: _marketItems[i]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // ─── CONNECT SHEET ──────────────────────────────────────────────────────
  void _showConnectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111827),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'CONNECT A DEVICE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'All connections use OAuth 2.0 or Bluetooth — your data stays private.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 16),
              for (final d in _devices)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: d.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: d.color.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        d.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  title: Text(
                    d.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    d.api,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: d.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      d.status == 'Connected' ? 'CONNECTED' : 'CONNECT',
                      style: TextStyle(
                        color: d.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${d.emoji} Connecting to ${d.name}...'),
                        backgroundColor: d.color,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APPLE WATCH HYPERTENSION MONITORING CARD
// ─────────────────────────────────────────────────────────────────────────────
class _AppleWatchHypertensionCard extends StatelessWidget {
  const _AppleWatchHypertensionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1E90FF).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E90FF).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E90FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF1E90FF).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.watch,
                  color: Color(0xFF1E90FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APPLE WATCH HYPERTENSION MONITORING',
                      style: TextStyle(
                        color: Color(0xFF1E90FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'TGA Approved · Australia · Feb 2026',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'TGA ✓',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Accuracy stats
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD600).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFD600).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '41%',
                        style: TextStyle(
                          color: Color(0xFFFFD600),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'SENSITIVITY',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Finds 41% of cases',
                        style: TextStyle(color: Colors.white24, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00E676).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '95%',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'SPECIFICITY',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Correct on normal BP',
                        style: TextStyle(color: Colors.white24, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E90FF).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF1E90FF).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '30d',
                        style: TextStyle(
                          color: Color(0xFF1E90FF),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'MONITORING',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Background scan',
                        style: TextStyle(color: Colors.white24, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // How it works
          const Text(
            'HOW IT WORKS',
            style: TextStyle(
              color: Color(0xFF1E90FF),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Apple Watch Series 9+ / Ultra 2+ uses its optical heart sensor to analyse blood vessel patterns over a 30-day period in the background. NOT a real-time BP reading — it screens for hypertension patterns and prompts you to check further.',
            style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 10),
          // Fighter warning
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1744).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF1744).withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: Color(0xFFFF1744),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'FIGHTER ALERT — Weight cuts, dehydration and overtraining all elevate '
                    'blood pressure risk. Monitor your BP before and after every cut.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Requirements chips
          const Text(
            'REQUIREMENTS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children:
                [
                      'Series 9+ / Ultra 2+',
                      'Age 22+',
                      'No prior diagnosis',
                      'Not pregnant',
                      'Latest watchOS',
                    ]
                    .map(
                      (r) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          r,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 10),
          // If triggered action
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00E676).withValues(alpha: 0.2),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IF ALERT TRIGGERS:',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '1. Log blood pressure 7 days with a cuff\n'
                  '2. Book a GP appointment\n'
                  '3. Do NOT start a weight cut until cleared',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // How to enable
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E90FF).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF1E90FF).withValues(alpha: 0.15),
              ),
            ),
            child: const Text(
              'Enable: Health app → Profile → Health Checklist → Hypertension Notifications',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _Device {
  final String emoji, name, status, api;
  final Color color;
  final List<String> metrics;
  const _Device(
    this.emoji,
    this.name,
    this.status,
    this.color,
    this.metrics,
    this.api,
  );
}

class _MarketDevice {
  final String name, emoji, price, rating, desc, badge;
  final Color color;
  const _MarketDevice(
    this.name,
    this.emoji,
    this.price,
    this.rating,
    this.desc,
    this.color,
    this.badge,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DEVICE CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  final _Device device;
  final bool selected;
  final VoidCallback onTap;
  const _DeviceCard({
    required this.device,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? device.color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? device.color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(device.emoji, style: const TextStyle(fontSize: 20)),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: device.status == 'Connected'
                        ? const Color(0xFF2ED573)
                        : device.status == 'Paired'
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF1E90FF),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  device.status,
                  style: TextStyle(
                    color: device.status == 'Connected'
                        ? const Color(0xFF2ED573)
                        : const Color(0xFFFFD700),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEVICE DETAIL PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceDetailPanel extends StatelessWidget {
  final _Device device;
  const _DeviceDetailPanel({required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [device.color.withValues(alpha: 0.10), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: device.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(device.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: device.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  device.status.toUpperCase(),
                  style: TextStyle(
                    color: device.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            device.api,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 12),
          const Text(
            'TRACKED METRICS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: device.metrics
                .map(
                  (m) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: device.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: device.color.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      m,
                      style: TextStyle(
                        color: device.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIVE VITAL CARD
// ─────────────────────────────────────────────────────────────────────────────

class _LiveVitalCard extends StatelessWidget {
  final String label, value, unit, icon, status;
  final Color color, statusColor;
  final bool compact;
  const _LiveVitalCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.status,
    required this.statusColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: TextStyle(fontSize: compact ? 16 : 20)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 22 : 36,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.6),
                    fontSize: compact ? 10 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GAUGE MINI
// ─────────────────────────────────────────────────────────────────────────────

class _GaugeMini extends StatelessWidget {
  final String label, unit;
  final double value, max;
  final Color color;
  const _GaugeMini({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(0)}$unit',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TREND CHART  (custom paint — no external dependency)
// ─────────────────────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final String title;
  final List<double> data;
  final List<String> labels;
  final Color color;
  final String unit;
  final double minY, maxY;
  final double divideBy;

  const _TrendChart({
    required this.title,
    required this.data,
    required this.labels,
    required this.color,
    required this.unit,
    required this.minY,
    required this.maxY,
    this.divideBy = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: CustomPaint(
              size: const Size(double.infinity, 90),
              painter: _LinePainter(
                data: data,
                color: color,
                minY: minY,
                maxY: maxY,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (l) => Text(
                    l,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Min: ${(data.reduce(math.min) / divideBy).toStringAsFixed(divideBy > 1 ? 1 : 0)} $unit',
                style: TextStyle(
                  color: color.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Max: ${(data.reduce(math.max) / divideBy).toStringAsFixed(divideBy > 1 ? 1 : 0)} $unit',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Avg: ${(data.reduce((a, b) => a + b) / data.length / divideBy).toStringAsFixed(divideBy > 1 ? 1 : 0)} $unit',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minY, maxY;

  const _LinePainter({
    required this.data,
    required this.color,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final range = maxY - minY;
    final stepX = size.width / (data.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minY) / range * size.height);
      points.add(Offset(x, y.clamp(0.0, size.height)));
    }

    // Fill
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = color);
      canvas.drawCircle(p, 2.5, Paint()..color = const Color(0xFF0A0E18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// FIGHTER METRIC CARD
// ─────────────────────────────────────────────────────────────────────────────

class _FighterMetricCard extends StatelessWidget {
  final String label, value, unit, icon;
  final Color color;
  const _FighterMetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              Text(
                unit,
                style: TextStyle(
                  color: color.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARKET DEVICE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MarketDeviceCard extends StatelessWidget {
  final _MarketDevice item;
  const _MarketDeviceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: item.color.withValues(alpha: 0.25)),
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.badge,
                          style: TextStyle(
                            color: item.color,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.rating,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.desc,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        item.price,
                        style: TextStyle(
                          color: item.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Adding ${item.name} to cart...'),
                            backgroundColor: item.color,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ADD TO CART',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
