import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// WOMEN OF COMBAT v1.0
///
/// Dedicated showcase for women's combat sports — rankings, champions,
/// rising stars, and history makers across every discipline.
///
/// Built from pain. Forged in battles. Hardened by resilience.
/// ═══════════════════════════════════════════════════════════════════════════

class WomenOfCombatScreen extends StatefulWidget {
  const WomenOfCombatScreen({super.key});

  @override
  State<WomenOfCombatScreen> createState() => _WomenOfCombatScreenState();
}

class _WomenOfCombatScreenState extends State<WomenOfCombatScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  int _selectedDivision = 0;

  final _divisions = ['P4P', 'SW', 'FLW', 'BW', 'FW', 'BKB', 'MT', 'BOX'];

  final _divisionNames = {
    'P4P': 'POUND FOR POUND',
    'SW': 'STRAWWEIGHT (52 kg / 115 lbs)',
    'FLW': 'FLYWEIGHT (57 kg / 125 lbs)',
    'BW': 'BANTAMWEIGHT (61 kg / 135 lbs)',
    'FW': 'FEATHERWEIGHT (66 kg / 145 lbs)',
    'BKB': 'BARE KNUCKLE / BKFC',
    'MT': 'MUAY THAI / KICKBOXING',
    'BOX': 'BOXING',
  };

  // Women's rankings — real fighters, March 2026
  final Map<String, List<_WocFighter>> _rankings = {
    'P4P': [
      const _WocFighter(
        'Zhang Weili',
        'zhang-weili',
        '25-3-0',
        '🇨🇳',
        'SW',
        'CKA Beijing',
        1600,
        5,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Valentina Shevchenko',
        'valentina-shevchenko',
        '24-4-1',
        '🇰🇬',
        'FLW',
        'Tiger Muay Thai',
        1580,
        2,
        '—',
        'MMA',
      ),
      const _WocFighter(
        'Amanda Nunes',
        'amanda-nunes',
        '22-5-0',
        '🇧🇷',
        'BW',
        'American Top Team',
        1560,
        0,
        '—',
        'MMA (Ret.)',
      ),
      const _WocFighter(
        'Tatiana Suarez',
        'tatiana-suarez',
        '10-0-0',
        '🇺🇸',
        'SW',
        'CSW MMA',
        1540,
        10,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Rose Namajunas',
        'rose-namajunas',
        '13-6-0',
        '🇺🇸',
        'FLW',
        'Roufusport',
        1520,
        2,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Katie Taylor',
        'katie-taylor',
        '23-1-0',
        '🇮🇪',
        'LW',
        'Matchroom Boxing',
        1510,
        0,
        '—',
        'Boxing',
      ),
      const _WocFighter(
        'Claressa Shields',
        'claressa-shields',
        '15-0-0',
        '🇺🇸',
        'MW',
        'SugarHill Steward',
        1500,
        4,
        '▲',
        'Boxing / MMA',
      ),
      const _WocFighter(
        'Alexa Grasso',
        'alexa-grasso',
        '16-4-1',
        '🇲🇽',
        'FLW',
        'Lobo Gym',
        1480,
        3,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Amanda Serrano',
        'amanda-serrano',
        '47-2-1',
        '🇵🇷',
        'FW',
        'Most Valuable Promotions',
        1470,
        1,
        '—',
        'Boxing',
      ),
      const _WocFighter(
        'Manon Fiorot',
        'manon-fiorot',
        '13-1-0',
        '🇫🇷',
        'FLW',
        'MMA Factory Paris',
        1460,
        4,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Savannah Marshall',
        'savannah-marshall',
        '13-1-0',
        '🇬🇧',
        'SMW',
        'Peter Fury',
        1450,
        6,
        '▲',
        'Boxing',
      ),
      const _WocFighter(
        'Alyse Anderson',
        'alyse-anderson',
        '7-1-0',
        '🇺🇸',
        'FLW',
        'BKFC',
        1440,
        8,
        '▲',
        'Bare Knuckle',
      ),
      const _WocFighter(
        'Stamp Fairtex',
        'stamp-fairtex',
        '70-22-5',
        '🇹🇭',
        'AW',
        'Fairtex Training Center',
        1430,
        2,
        '▲',
        'Muay Thai / MMA',
      ),
      const _WocFighter(
        'Julianna Peña',
        'julianna-pena',
        '12-5-0',
        '🇺🇸',
        'BW',
        'SikJitsu',
        1420,
        1,
        '▼',
        'MMA',
      ),
      const _WocFighter(
        'Yan Xiaonan',
        'yan-xiaonan',
        '17-4-0',
        '🇨🇳',
        'SW',
        'CKA Beijing',
        1410,
        2,
        '▲',
        'MMA',
      ),
    ],
    'SW': [
      const _WocFighter(
        'Zhang Weili',
        'zhang-weili',
        '25-3-0',
        '🇨🇳',
        'SW',
        'CKA Beijing',
        1500,
        5,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Tatiana Suarez',
        'tatiana-suarez',
        '10-0-0',
        '🇺🇸',
        'SW',
        'CSW MMA',
        1460,
        10,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Yan Xiaonan',
        'yan-xiaonan',
        '17-4-0',
        '🇨🇳',
        'SW',
        'CKA Beijing',
        1420,
        2,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Amanda Lemos',
        'amanda-lemos',
        '15-3-1',
        '🇧🇷',
        'SW',
        'Marajo Brothers',
        1380,
        2,
        '—',
        'MMA',
      ),
      const _WocFighter(
        'Virna Jandiroba',
        'virna-jandiroba',
        '20-3-0',
        '🇧🇷',
        'SW',
        'Pitbull Bros BJJ',
        1340,
        4,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Jessica Andrade',
        'jessica-andrade',
        '25-12-0',
        '🇧🇷',
        'SW',
        'Fight Ready',
        1310,
        1,
        '▼',
        'MMA',
      ),
      const _WocFighter(
        'Marina Rodriguez',
        'marina-rodriguez',
        '18-4-2',
        '🇧🇷',
        'SW',
        'Almeida JJ',
        1280,
        2,
        '▼',
        'MMA',
      ),
      const _WocFighter(
        'Mackenzie Dern',
        'mackenzie-dern',
        '14-5-0',
        '🇺🇸',
        'SW',
        'Dern BJJ',
        1250,
        1,
        '▲',
        'MMA',
      ),
    ],
    'FLW': [
      const _WocFighter(
        'Valentina Shevchenko',
        'valentina-shevchenko',
        '24-4-1',
        '🇰🇬',
        'FLW',
        'Tiger Muay Thai',
        1500,
        2,
        '—',
        'MMA',
      ),
      const _WocFighter(
        'Alexa Grasso',
        'alexa-grasso',
        '16-4-1',
        '🇲🇽',
        'FLW',
        'Lobo Gym',
        1460,
        3,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Manon Fiorot',
        'manon-fiorot',
        '13-1-0',
        '🇫🇷',
        'FLW',
        'MMA Factory Paris',
        1420,
        4,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Rose Namajunas',
        'rose-namajunas',
        '13-6-0',
        '🇺🇸',
        'FLW',
        'Roufusport',
        1380,
        2,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Erin Blanchfield',
        'erin-blanchfield',
        '12-2-0',
        '🇺🇸',
        'FLW',
        'Miller Brothers MMA',
        1350,
        5,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Maycee Barber',
        'maycee-barber',
        '14-3-0',
        '🇺🇸',
        'FLW',
        'Elevation Fight Team',
        1320,
        2,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Natalia Silva',
        'natalia-silva',
        '17-5-1',
        '🇧🇷',
        'FLW',
        'Evolucao Thai',
        1290,
        3,
        '▲',
        'MMA',
      ),
    ],
    'BW': [
      const _WocFighter(
        'Julianna Peña',
        'julianna-pena',
        '12-5-0',
        '🇺🇸',
        'BW',
        'SikJitsu',
        1500,
        1,
        '—',
        'MMA',
      ),
      const _WocFighter(
        'Raquel Pennington',
        'raquel-pennington',
        '16-9-0',
        '🇺🇸',
        'BW',
        'Grudge Training Center',
        1450,
        2,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Norma Dumont',
        'norma-dumont',
        '12-2-0',
        '🇧🇷',
        'BW',
        'Alpha Fight Team',
        1410,
        3,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Holly Holm',
        'holly-holm',
        '15-7-0',
        '🇺🇸',
        'BW',
        'Jackson-Wink MMA',
        1370,
        1,
        '▼',
        'MMA',
      ),
      const _WocFighter(
        'Ketlen Vieira',
        'ketlen-vieira',
        '14-3-0',
        '🇧🇷',
        'BW',
        'Nova União',
        1340,
        1,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Macy Chiasson',
        'macy-chiasson',
        '10-3-0',
        '🇺🇸',
        'BW',
        'Fortis MMA',
        1310,
        2,
        '▲',
        'MMA',
      ),
      const _WocFighter(
        'Kayla Harrison',
        'kayla-harrison',
        '18-1-0',
        '🇺🇸',
        'BW',
        'American Top Team',
        1290,
        3,
        '▲',
        'MMA',
      ),
    ],
    'FW': [
      const _WocFighter(
        'Amanda Nunes',
        'amanda-nunes',
        '22-5-0',
        '🇧🇷',
        'FW',
        'American Top Team',
        1500,
        0,
        '—',
        'MMA (Ret.)',
      ),
      const _WocFighter(
        'Cris Cyborg',
        'cris-cyborg',
        '27-2-0',
        '🇧🇷',
        'FW',
        'Tata Fight Team',
        1460,
        1,
        '—',
        'MMA (Bellator)',
      ),
      const _WocFighter(
        'Amanda Serrano',
        'amanda-serrano',
        '47-2-1',
        '🇵🇷',
        'FW',
        'Most Valuable Promotions',
        1430,
        1,
        '—',
        'Boxing',
      ),
      const _WocFighter(
        'Larissa Pacheco',
        'larissa-pacheco',
        '23-4-0',
        '🇧🇷',
        'FW',
        'Evolucao Thai',
        1400,
        2,
        '▲',
        'MMA (PFL)',
      ),
      const _WocFighter(
        'PFL Champ TBD',
        '',
        'TBD',
        '🌍',
        'FW',
        'PFL',
        1370,
        0,
        '—',
        'MMA',
      ),
    ],
    'BKB': [
      const _WocFighter(
        'Alyse Anderson',
        'alyse-anderson',
        '7-1-0',
        '🇺🇸',
        'FLW',
        'BKFC',
        1500,
        8,
        '▲',
        'Bare Knuckle',
      ),
      const _WocFighter(
        'Christine Ferea',
        'christine-ferea',
        '6-1-0',
        '🇺🇸',
        'FLW',
        'BKFC',
        1440,
        5,
        '▲',
        'Bare Knuckle',
      ),
      const _WocFighter(
        'Bec Rawlings',
        'bec-rawlings',
        '5-3-0',
        '🇦🇺',
        'SW',
        'BKFC / Independent',
        1380,
        1,
        '—',
        'Bare Knuckle',
      ),
      const _WocFighter(
        'Pearl Gonzalez',
        'pearl-gonzalez',
        '3-2-0',
        '🇺🇸',
        'SW',
        'BKFC',
        1320,
        2,
        '▲',
        'Bare Knuckle',
      ),
      const _WocFighter(
        'Britain Hart',
        'britain-hart',
        '6-5-3',
        '🇺🇸',
        'FW',
        'BKFC',
        1280,
        1,
        '—',
        'Bare Knuckle',
      ),
    ],
    'MT': [
      const _WocFighter(
        'Stamp Fairtex',
        'stamp-fairtex',
        '70-22-5',
        '🇹🇭',
        'AW',
        'Fairtex Training Center',
        1500,
        2,
        '▲',
        'Muay Thai / MMA',
      ),
      const _WocFighter(
        'Smilla Sundell',
        'smilla-sundell',
        '8-1-0',
        '🇸🇪',
        'SW',
        'Fairtex Training Center',
        1450,
        6,
        '▲',
        'Muay Thai',
      ),
      const _WocFighter(
        'Anissa Meksen',
        'anissa-meksen',
        '105-4-0',
        '🇫🇷',
        'AW',
        'Team Meksen',
        1420,
        0,
        '—',
        'Kickboxing',
      ),
      const _WocFighter(
        'Jackie Buntan',
        'jackie-buntan',
        '11-3-0',
        '🇺🇸',
        'AW',
        'Boxing Works',
        1380,
        3,
        '▲',
        'Muay Thai',
      ),
      const _WocFighter(
        'Supergirl Jaroonsak',
        'supergirl-jaroonsak',
        '45-9-1',
        '🇹🇭',
        'SW',
        'JR Muay Thai',
        1340,
        1,
        '▲',
        'Muay Thai',
      ),
      const _WocFighter(
        'Janet Todd',
        'janet-todd',
        '7-2-0',
        '🇺🇸',
        'AW',
        'Sor Dechapan',
        1300,
        1,
        '—',
        'Muay Thai / Kickboxing',
      ),
    ],
    'BOX': [
      const _WocFighter(
        'Katie Taylor',
        'katie-taylor',
        '23-1-0',
        '🇮🇪',
        'LW',
        'Matchroom Boxing',
        1500,
        0,
        '—',
        'Boxing',
      ),
      const _WocFighter(
        'Claressa Shields',
        'claressa-shields',
        '15-0-0',
        '🇺🇸',
        'MW',
        'SugarHill Steward',
        1470,
        4,
        '▲',
        'Boxing',
      ),
      const _WocFighter(
        'Savannah Marshall',
        'savannah-marshall',
        '13-1-0',
        '🇬🇧',
        'SMW',
        'Peter Fury',
        1440,
        6,
        '▲',
        'Boxing',
      ),
      const _WocFighter(
        'Amanda Serrano',
        'amanda-serrano',
        '47-2-1',
        '🇵🇷',
        'FW',
        'Most Valuable Promotions',
        1410,
        1,
        '—',
        'Boxing',
      ),
      const _WocFighter(
        'Alycia Baumgardner',
        'alycia-baumgardner',
        '14-1-0',
        '🇺🇸',
        'SFW',
        'Independent',
        1380,
        2,
        '▲',
        'Boxing',
      ),
      const _WocFighter(
        'Chantelle Cameron',
        'chantelle-cameron',
        '18-2-0',
        '🇬🇧',
        'SLW',
        'Jamie Moore',
        1350,
        1,
        '▼',
        'Boxing',
      ),
      const _WocFighter(
        'Seniesa Estrada',
        'seniesa-estrada',
        '24-0-0',
        '🇺🇸',
        'MFW',
        'Joe Goossen',
        1320,
        3,
        '▲',
        'Boxing',
      ),
    ],
  };

  // Stats for the hero card
  final _heroStats = {
    'totalFighters': '120+',
    'disciplines': '8',
    'countries': '35+',
    'activeChampions': '22',
  };

  String get _currentDivision => _divisions[_selectedDivision];
  List<_WocFighter> get _currentRankings =>
      _rankings[_currentDivision] ?? _rankings['P4P']!;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) => Icon(
                Icons.local_fire_department,
                color: Color.lerp(
                  const Color(0xFFFF6B9D),
                  const Color(0xFFFFD700),
                  _pulseCtrl.value,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WOMEN OF COMBAT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Champions • Rising Stars • Legends',
                  style: TextStyle(fontSize: 10, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeroCard(),
          _buildDivisionSelector(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  _divisionNames[_currentDivision] ?? _currentDivision,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentRankings.length} fighters',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Expanded(child: _buildRankingsList()),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A2E), Color(0xFF16213E), Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _heroStat(_heroStats['totalFighters']!, 'Fighters'),
              _heroStat(_heroStats['disciplines']!, 'Disciplines'),
              _heroStat(_heroStats['countries']!, 'Countries'),
              _heroStat(_heroStats['activeChampions']!, 'Champions'),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'MMA • Boxing • Muay Thai • Bare Knuckle • Kickboxing • BJJ • Wrestling • Judo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFF6B9D),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDivisionSelector() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _divisions.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDivision;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedDivision = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF6B9D).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF6B9D)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  _divisions[index],
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFF6B9D)
                        : Colors.white60,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankingsList() {
    final fighters = _currentRankings;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: fighters.length,
      itemBuilder: (context, index) {
        final f = fighters[index];
        final rank = index + 1;
        return _buildFighterCard(f, rank);
      },
    );
  }

  Widget _buildFighterCard(_WocFighter fighter, int rank) {
    final isChamp = rank == 1;
    final trendColor = fighter.trend == '▲'
        ? const Color(0xFF00FF88)
        : fighter.trend == '▼'
        ? const Color(0xFFFF3366)
        : Colors.white38;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isChamp
              ? [
                  const Color(0xFF1A0A2E).withValues(alpha: 0.9),
                  const Color(0xFF2D1B69).withValues(alpha: 0.6),
                ]
              : [
                  const Color(0xFF0D1B2A).withValues(alpha: 0.8),
                  const Color(0xFF0A1628).withValues(alpha: 0.6),
                ],
        ),
        border: Border.all(
          color: isChamp
              ? const Color(0xFFFFD700).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: fighter.id.isNotEmpty
            ? () => context.push('/fighter/${fighter.id}')
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 28,
                child: Text(
                  isChamp ? '👑' : '#$rank',
                  style: TextStyle(
                    color: isChamp ? const Color(0xFFFFD700) : Colors.white54,
                    fontSize: isChamp ? 18 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Avatar placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isChamp
                        ? [const Color(0xFFFFD700), const Color(0xFFFF6B9D)]
                        : [const Color(0xFF1E3A5F), const Color(0xFF0D1B2A)],
                  ),
                  border: Border.all(
                    color: isChamp
                        ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.1),
                    width: isChamp ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    fighter.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name + gym
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fighter.name,
                      style: TextStyle(
                        color: isChamp ? const Color(0xFFFFD700) : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fighter.gym} • ${fighter.sport}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Record
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fighter.record,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fighter.division,
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${fighter.trend} ${fighter.ratingDelta}',
                        style: TextStyle(
                          color: trendColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final allFighters = <_WocFighter>[];
        final seen = <String>{};
        for (final list in _rankings.values) {
          for (final f in list) {
            if (f.id.isNotEmpty && seen.add(f.id)) {
              allFighters.add(f);
            }
          }
        }
        allFighters.sort((a, b) => a.name.compareTo(b.name));

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'All Women of Combat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: allFighters.length,
                    itemBuilder: (_, i) {
                      final f = allFighters[i];
                      return ListTile(
                        dense: true,
                        leading: Text(
                          f.flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          f.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${f.record} • ${f.sport} • ${f.division}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                        trailing: Text(
                          '${f.rating}',
                          style: const TextStyle(
                            color: Color(0xFFFF6B9D),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: f.id.isNotEmpty
                            ? () {
                                Navigator.pop(ctx);
                                context.push('/fighter/${f.id}');
                              }
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WocFighter {
  final String name;
  final String id;
  final String record;
  final String flag;
  final String division;
  final String gym;
  final int rating;
  final int ratingDelta;
  final String trend;
  final String sport;

  const _WocFighter(
    this.name,
    this.id,
    this.record,
    this.flag,
    this.division,
    this.gym,
    this.rating,
    this.ratingDelta,
    this.trend,
    this.sport,
  );
}
