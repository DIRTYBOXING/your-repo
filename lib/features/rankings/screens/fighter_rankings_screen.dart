import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER RANKINGS v1.0
///
/// Weight class leaderboards. P4P lists. Regional rankings.
/// The backbone of legitimacy for a fight platform.
///
/// Built from pain. Forged in battles. Hardened by resilience.
/// ═══════════════════════════════════════════════════════════════════════════

class FighterRankingsScreen extends StatefulWidget {
  const FighterRankingsScreen({super.key});

  @override
  State<FighterRankingsScreen> createState() => _FighterRankingsScreenState();
}

class _FighterRankingsScreenState extends State<FighterRankingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  int _selectedDivision = 0;

  final _divisions = [
    'P4P',
    'HW',
    'LHW',
    'MW',
    'WW',
    'LW',
    'FW',
    'BW',
    'FLW',
    'SW',
  ];

  final _divisionNames = {
    'P4P': 'POUND FOR POUND',
    'HW': 'HEAVYWEIGHT (120 kg / 265 lbs)',
    'LHW': 'LIGHT HEAVYWEIGHT (93 kg / 205 lbs)',
    'MW': 'MIDDLEWEIGHT (84 kg / 185 lbs)',
    'WW': 'WELTERWEIGHT (77 kg / 170 lbs)',
    'LW': 'LIGHTWEIGHT (70 kg / 155 lbs)',
    'FW': 'FEATHERWEIGHT (66 kg / 145 lbs)',
    'BW': 'BANTAMWEIGHT (61 kg / 135 lbs)',
    'FLW': 'FLYWEIGHT (57 kg / 125 lbs)',
    'SW': 'STRAWWEIGHT (52 kg / 115 lbs)',
  };

  // Rankings data — real fighters, March 2026
  final Map<String, List<_RankedFighter>> _rankings = {
    'P4P': [
      const _RankedFighter(
        'Islam Makhachev',
        'islam-makhachev',
        '26-1-0',
        '🇷🇺',
        'LW',
        'AKA',
        1600,
        15,
        '▲',
      ),
      const _RankedFighter(
        'Jon Jones',
        'jon-jones',
        '28-1-0',
        '🇺🇸',
        'HW',
        'Jackson-Wink MMA',
        1580,
        1,
        '—',
      ),
      const _RankedFighter(
        'Alex Pereira',
        'alex-pereira',
        '12-2-0',
        '🇧🇷',
        'LHW',
        'Glover Teixeira MMA',
        1560,
        7,
        '▲',
      ),
      const _RankedFighter(
        'Ilia Topuria',
        'ilia-topuria',
        '16-0-0',
        '🇪🇸',
        'FW',
        'Infierno',
        1540,
        16,
        '▲',
      ),
      const _RankedFighter(
        'Dricus Du Plessis',
        'dricus-du-plessis',
        '22-2-0',
        '🇿🇦',
        'MW',
        'CIT Performance',
        1520,
        10,
        '▲',
      ),
      const _RankedFighter(
        'Merab Dvalishvili',
        'merab-dvalishvili',
        '18-4-0',
        '🇬🇪',
        'BW',
        'Serra-Longo',
        1500,
        11,
        '▲',
      ),
      const _RankedFighter(
        'Belal Muhammad',
        'belal-muhammad',
        '24-3-0',
        '🇺🇸',
        'WW',
        'Roufusport',
        1480,
        2,
        '▼',
      ),
      const _RankedFighter(
        'Leon Edwards',
        'leon-edwards',
        '22-4-0',
        '🇬🇧',
        'WW',
        'Team Edwards',
        1460,
        5,
        '▼',
      ),
      const _RankedFighter(
        'Tom Aspinall',
        'tom-aspinall',
        '15-3-0',
        '🇬🇧',
        'HW',
        'Team Kaobon',
        1440,
        5,
        '▲',
      ),
      const _RankedFighter(
        'Jack Della Maddalena',
        'jack-della-maddalena',
        '18-3-0',
        '🇦🇺',
        'WW',
        'Scrappy MMA',
        1420,
        5,
        '▲',
      ),
      const _RankedFighter(
        'Arman Tsarukyan',
        'arman-tsarukyan',
        '23-3-0',
        '🇦🇲',
        'LW',
        'Kings MMA',
        1400,
        3,
        '▲',
      ),
      const _RankedFighter(
        'Michael Morales',
        'michael-morales',
        '19-0-0',
        '🇪🇨',
        'WW',
        'Entram Gym',
        1380,
        19,
        '▲',
      ),
      const _RankedFighter(
        'Sean Strickland',
        'sean-strickland',
        '30-7-0',
        '🇺🇸',
        'MW',
        'Xtreme Couture',
        1360,
        3,
        '▼',
      ),
      const _RankedFighter(
        'Max Holloway',
        'max-holloway',
        '27-9-0',
        '🇺🇸',
        'FW',
        'Hawaii Elite MMA',
        1340,
        1,
        '▼',
      ),
      const _RankedFighter(
        'Charles Oliveira',
        'charles-oliveira',
        '37-11-0',
        '🇧🇷',
        'LW',
        'Chute Boxe Diego Lima',
        1320,
        2,
        '▲',
      ),
    ],
    'HW': [
      const _RankedFighter(
        'Jon Jones',
        'jon-jones',
        '28-1-0',
        '🇺🇸',
        'HW',
        'Jackson-Wink MMA',
        1500,
        1,
        '—',
      ),
      const _RankedFighter(
        'Tom Aspinall',
        'tom-aspinall',
        '15-3-0',
        '🇬🇧',
        'HW',
        'Team Kaobon',
        1460,
        5,
        '▲',
      ),
      const _RankedFighter(
        'Ciryl Gane',
        'ciryl-gane',
        '13-2-0',
        '🇫🇷',
        'HW',
        'MMA Factory Paris',
        1410,
        3,
        '▲',
      ),
      const _RankedFighter(
        'Alexander Volkov',
        'alexander-volkov',
        '38-10-0',
        '🇷🇺',
        'HW',
        'Team Volkov',
        1370,
        2,
        '—',
      ),
      const _RankedFighter(
        'Sergei Pavlovich',
        'sergei-pavlovich',
        '19-3-0',
        '🇷🇺',
        'HW',
        'Fedor Team',
        1340,
        1,
        '▼',
      ),
      const _RankedFighter(
        'Curtis Blaydes',
        'curtis-blaydes',
        '18-4-0',
        '🇺🇸',
        'HW',
        'Elevation Fight Team',
        1310,
        1,
        '▲',
      ),
      const _RankedFighter(
        'Tai Tuivasa',
        'tai-tuivasa',
        '15-8-0',
        '🇦🇺',
        'HW',
        'City Kickboxing',
        1280,
        1,
        '▼',
      ),
    ],
    'LHW': [
      const _RankedFighter(
        'Alex Pereira',
        'alex-pereira',
        '12-2-0',
        '🇧🇷',
        'LHW',
        'Glover Teixeira MMA',
        1500,
        7,
        '▲',
      ),
      const _RankedFighter(
        'Jiri Prochazka',
        'jiri-prochazka',
        '30-5-1',
        '🇨🇿',
        'LHW',
        'D&D Gym Brno',
        1440,
        1,
        '▲',
      ),
      const _RankedFighter(
        'Magomed Ankalaev',
        'magomed-ankalaev',
        '19-1-1',
        '🇷🇺',
        'LHW',
        'AKA',
        1400,
        13,
        '▲',
      ),
      const _RankedFighter(
        'Jamahal Hill',
        'jamahal-hill',
        '12-2-0',
        '🇺🇸',
        'LHW',
        'Xtreme Couture',
        1360,
        1,
        '▼',
      ),
      const _RankedFighter(
        'Aleksandar Rakic',
        'aleksandar-rakic',
        '14-4-0',
        '🇦🇹',
        'LHW',
        'Kingdom Sparring',
        1330,
        1,
        '▲',
      ),
      const _RankedFighter(
        'Carlos Ulberg',
        'carlos-ulberg',
        '11-1-0',
        '🇳🇿',
        'LHW',
        'City Kickboxing',
        1300,
        8,
        '▲',
      ),
      const _RankedFighter(
        'Tyson Pedro',
        'tyson-pedro',
        '10-4-0',
        '🇦🇺',
        'LHW',
        'Tiger Muay Thai',
        1270,
        3,
        '▲',
      ),
    ],
    'MW': [
      const _RankedFighter(
        'Dricus Du Plessis',
        'dricus-du-plessis',
        '22-2-0',
        '🇿🇦',
        'MW',
        'CIT Performance',
        1500,
        10,
        '▲',
      ),
      const _RankedFighter(
        'Israel Adesanya',
        'israel-adesanya',
        '24-4-0',
        '🇳🇿',
        'MW',
        'City Kickboxing',
        1450,
        1,
        '▼',
      ),
      const _RankedFighter(
        'Sean Strickland',
        'sean-strickland',
        '30-7-0',
        '🇺🇸',
        'MW',
        'Xtreme Couture',
        1410,
        3,
        '▲',
      ),
      const _RankedFighter(
        'Robert Whittaker',
        'robert-whittaker',
        '25-7-0',
        '🇦🇺',
        'MW',
        'Gracie Smeaton Grange',
        1380,
        3,
        '▲',
      ),
      const _RankedFighter(
        'Khamzat Chimaev',
        'khamzat-chimaev',
        '13-0-0',
        '🇸🇪',
        'MW',
        'Allstars Training',
        1350,
        13,
        '▲',
      ),
      const _RankedFighter(
        'Nassourdine Imavov',
        'nassourdine-imavov',
        '15-4-0',
        '🇫🇷',
        'MW',
        'MMA Factory Paris',
        1320,
        4,
        '▲',
      ),
      const _RankedFighter(
        'Jared Cannonier',
        'jared-cannonier',
        '17-7-0',
        '🇺🇸',
        'MW',
        'MMA Lab',
        1290,
        1,
        '▼',
      ),
    ],
    'WW': [
      const _RankedFighter(
        'Belal Muhammad',
        'belal-muhammad',
        '24-3-0',
        '🇺🇸',
        'WW',
        'Roufusport',
        1500,
        2,
        '—',
      ),
      const _RankedFighter(
        'Leon Edwards',
        'leon-edwards',
        '22-4-0',
        '🇬🇧',
        'WW',
        'Team Edwards',
        1460,
        5,
        '▼',
      ),
      const _RankedFighter(
        'Jack Della Maddalena',
        'jack-della-maddalena',
        '18-3-0',
        '🇦🇺',
        'WW',
        'Scrappy MMA',
        1420,
        5,
        '▲',
      ),
      const _RankedFighter(
        'Shavkat Rakhmonov',
        'shavkat-rakhmonov',
        '18-0-0',
        '🇰🇿',
        'WW',
        'Rakhmonov Team',
        1390,
        18,
        '▲',
      ),
      const _RankedFighter(
        'Kamaru Usman',
        'kamaru-usman',
        '20-4-0',
        '🇺🇸',
        'WW',
        'Sanford MMA',
        1360,
        1,
        '▼',
      ),
      const _RankedFighter(
        'Gilbert Burns',
        'gilbert-burns',
        '22-7-0',
        '🇧🇷',
        'WW',
        'Sanford MMA',
        1330,
        2,
        '▲',
      ),
      const _RankedFighter(
        'Michael Morales',
        'michael-morales',
        '19-0-0',
        '🇪🇨',
        'WW',
        'Entram Gym',
        1300,
        19,
        '▲',
      ),
    ],
    'LW': [
      const _RankedFighter(
        'Islam Makhachev',
        'islam-makhachev',
        '26-1-0',
        '🇷🇺',
        'LW',
        'AKA',
        1500,
        15,
        '▲',
      ),
      const _RankedFighter(
        'Arman Tsarukyan',
        'arman-tsarukyan',
        '23-3-0',
        '🇦🇲',
        'LW',
        'Kings MMA',
        1450,
        3,
        '▲',
      ),
      const _RankedFighter(
        'Charles Oliveira',
        'charles-oliveira',
        '37-11-0',
        '🇧🇷',
        'LW',
        'Chute Boxe Diego Lima',
        1410,
        2,
        '▲',
      ),
      const _RankedFighter(
        'Dustin Poirier',
        'dustin-poirier',
        '30-9-0',
        '🇺🇸',
        'LW',
        'American Top Team',
        1370,
        1,
        '▼',
      ),
      const _RankedFighter(
        'Justin Gaethje',
        'justin-gaethje',
        '25-5-0',
        '🇺🇸',
        'LW',
        'Elevation Fight Team',
        1340,
        1,
        '▼',
      ),
      const _RankedFighter(
        'Dan Hooker',
        'dan-hooker',
        '24-12-0',
        '🇳🇿',
        'LW',
        'City Kickboxing',
        1310,
        3,
        '▲',
      ),
      const _RankedFighter(
        'Renato Moicano',
        'renato-moicano',
        '20-5-1',
        '🇧🇷',
        'LW',
        'Fight Ready',
        1280,
        5,
        '▲',
      ),
    ],
    'FW': [
      const _RankedFighter(
        'Ilia Topuria',
        'ilia-topuria',
        '16-0-0',
        '🇪🇸',
        'FW',
        'Infierno',
        1500,
        16,
        '▲',
      ),
      const _RankedFighter(
        'Alexander Volkanovski',
        'alexander-volkanovski',
        '26-4-0',
        '🇦🇺',
        'FW',
        'City Kickboxing',
        1450,
        1,
        '▼',
      ),
      const _RankedFighter(
        'Max Holloway',
        'max-holloway',
        '27-9-0',
        '🇺🇸',
        'FW',
        'Hawaii Elite MMA',
        1410,
        1,
        '▼',
      ),
      const _RankedFighter(
        'Movsar Evloev',
        'movsar-evloev',
        '20-0-0',
        '🇷🇺',
        'FW',
        'Tiger Muay Thai',
        1380,
        20,
        '▲',
      ),
      const _RankedFighter(
        'Diego Lopes',
        'diego-lopes',
        '26-6-0',
        '🇧🇷',
        'FW',
        'Fight Ready',
        1350,
        5,
        '▲',
      ),
      const _RankedFighter(
        'Yair Rodriguez',
        'yair-rodriguez',
        '16-4-0',
        '🇲🇽',
        'FW',
        'Team Rivas',
        1320,
        1,
        '▲',
      ),
      const _RankedFighter(
        'Josh Emmett',
        'josh-emmett',
        '18-4-0',
        '🇺🇸',
        'FW',
        'Team Alpha Male',
        1290,
        1,
        '▼',
      ),
    ],
    'BW': [
      const _RankedFighter(
        'Merab Dvalishvili',
        'merab-dvalishvili',
        '18-4-0',
        '🇬🇪',
        'BW',
        'Serra-Longo',
        1500,
        11,
        '▲',
      ),
      const _RankedFighter(
        'Sean O\'Malley',
        'sean-omalley',
        '19-3-0',
        '🇺🇸',
        'BW',
        'The MMA Lab',
        1450,
        1,
        '▼',
      ),
      const _RankedFighter(
        'Umar Nurmagomedov',
        'umar-nurmagomedov',
        '18-0-0',
        '🇷🇺',
        'BW',
        'AKA',
        1420,
        18,
        '▲',
      ),
      const _RankedFighter(
        'Cory Sandhagen',
        'cory-sandhagen',
        '17-5-0',
        '🇺🇸',
        'BW',
        'Elevation Fight Team',
        1380,
        2,
        '▲',
      ),
      const _RankedFighter(
        'Petr Yan',
        'petr-yan',
        '17-5-0',
        '🇷🇺',
        'BW',
        'Tiger Muay Thai',
        1350,
        1,
        '▼',
      ),
      const _RankedFighter(
        'Song Yadong',
        'song-yadong',
        '22-8-1',
        '🇨🇳',
        'BW',
        'Team Alpha Male',
        1320,
        2,
        '▲',
      ),
      const _RankedFighter(
        'Marlon Vera',
        'marlon-vera',
        '23-9-1',
        '🇪🇨',
        'BW',
        'Chute Boxe San Diego',
        1290,
        1,
        '▼',
      ),
    ],
    'FLW': [
      const _RankedFighter(
        'Alexandre Pantoja',
        'alexandre-pantoja',
        '28-5-0',
        '🇧🇷',
        'FLW',
        'Nova União',
        1500,
        7,
        '▲',
      ),
      const _RankedFighter(
        'Brandon Royval',
        'brandon-royval',
        '16-7-0',
        '🇺🇸',
        'FLW',
        'Elevation Fight Team',
        1440,
        3,
        '▲',
      ),
      const _RankedFighter(
        'Amir Albazi',
        'amir-albazi',
        '17-1-0',
        '🇸🇪',
        'FLW',
        'Allstars Training',
        1400,
        9,
        '▲',
      ),
      const _RankedFighter(
        'Kai Kara-France',
        'kai-kara-france',
        '24-11-0',
        '🇳🇿',
        'FLW',
        'City Kickboxing',
        1360,
        2,
        '▼',
      ),
      const _RankedFighter(
        'Brandon Moreno',
        'brandon-moreno',
        '21-8-2',
        '🇲🇽',
        'FLW',
        'Team Bonebreakers',
        1330,
        1,
        '▼',
      ),
      const _RankedFighter(
        'Muhammad Mokaev',
        'muhammad-mokaev',
        '12-1-0',
        '🇬🇧',
        'FLW',
        'Team Kaobon',
        1300,
        2,
        '▲',
      ),
      const _RankedFighter(
        'Manel Kape',
        'manel-kape',
        '19-7-0',
        '🇵🇹',
        'FLW',
        'Tiger Muay Thai',
        1270,
        2,
        '▲',
      ),
    ],
    'SW': [
      const _RankedFighter(
        'Zhang Weili',
        'zhang-weili',
        '25-3-0',
        '🇨🇳',
        'SW',
        'CKA Beijing',
        1500,
        5,
        '▲',
      ),
      const _RankedFighter(
        'Rose Namajunas',
        'rose-namajunas',
        '13-6-0',
        '🇺🇸',
        'SW',
        'Roufusport',
        1440,
        2,
        '▲',
      ),
      const _RankedFighter(
        'Yan Xiaonan',
        'yan-xiaonan',
        '17-4-0',
        '🇨🇳',
        'SW',
        'CKA Beijing',
        1400,
        2,
        '▲',
      ),
      const _RankedFighter(
        'Tatiana Suarez',
        'tatiana-suarez',
        '10-0-0',
        '🇺🇸',
        'SW',
        'CSW MMA',
        1370,
        10,
        '▲',
      ),
      const _RankedFighter(
        'Amanda Lemos',
        'amanda-lemos',
        '15-3-1',
        '🇧🇷',
        'SW',
        'Marajo Brothers',
        1340,
        2,
        '—',
      ),
      const _RankedFighter(
        'Virna Jandiroba',
        'virna-jandiroba',
        '20-3-0',
        '🇧🇷',
        'SW',
        'Pitbull Bros BJJ',
        1310,
        4,
        '▲',
      ),
      const _RankedFighter(
        'Jessica Andrade',
        'jessica-andrade',
        '25-12-0',
        '🇧🇷',
        'SW',
        'Fight Ready',
        1280,
        1,
        '▼',
      ),
    ],
  };

  String get _currentDivision => _divisions[_selectedDivision];
  List<_RankedFighter> get _currentRankings =>
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
                Icons.emoji_events,
                color: Color.lerp(
                  const Color(0xFFFFD700),
                  const Color(0xFFFF6600),
                  _pulseCtrl.value,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIGHTER RANKINGS',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'DFC OFFICIAL LEADERBOARD',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDivisionSelector(),
          _buildDivisionHeader(),
          Expanded(child: _buildRankingsList()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildDivisionSelector() {
    return Container(
      height: 48,
      color: const Color(0xFF0A0A14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _divisions.length,
        itemBuilder: (context, i) {
          final sel = i == _selectedDivision;
          final div = _divisions[i];
          final isPfp = div == 'P4P';
          final color = isPfp
              ? const Color(0xFFFFD700)
              : const Color(0xFF00E5FF);

          return GestureDetector(
            onTap: () => setState(() => _selectedDivision = i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: sel ? color.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: sel ? color : Colors.white12,
                  width: sel ? 1.5 : 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                div,
                style: TextStyle(
                  color: sel ? color : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivisionHeader() {
    final divName = _divisionNames[_currentDivision] ?? _currentDivision;
    final isPfp = _currentDivision == 'P4P';
    final color = isPfp ? const Color(0xFFFFD700) : const Color(0xFF00E5FF);

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1 + _pulseCtrl.value * 0.03),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPfp ? Icons.emoji_events : Icons.fitness_center,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    divName,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '${_currentRankings.length} RANKED FIGHTERS • UPDATED MARCH 6, 2026',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            if (_currentDivision == 'MW')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0040),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TITLE FIGHT\nTOMORROW',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _currentRankings.length,
      itemBuilder: (context, i) {
        final fighter = _currentRankings[i];
        final rank = i + 1;
        final isChamp = rank == 1;
        final isIbc = _ibcFighters.contains(fighter.id);

        return GestureDetector(
          onTap: () => context.push('/fighter/${fighter.id}'),
          child: AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (_, _) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isChamp
                    ? LinearGradient(
                        colors: [
                          const Color(
                            0xFFFFD700,
                          ).withValues(alpha: 0.1 + _shimmerCtrl.value * 0.05),
                          const Color(0xFFFF6600).withValues(alpha: 0.05),
                        ],
                      )
                    : null,
                color: isChamp ? null : Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isChamp
                      ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                      : isIbc
                      ? const Color(0xFFFF0040).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.04),
                  width: isChamp ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        Text(
                          isChamp ? '👑' : '#$rank',
                          style: TextStyle(
                            color: isChamp
                                ? const Color(0xFFFFD700)
                                : Colors.white.withValues(alpha: 0.5),
                            fontSize: isChamp ? 18 : 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          fighter.trend,
                          style: TextStyle(
                            color: fighter.trend == '▲'
                                ? const Color(0xFF00FF88)
                                : fighter.trend == '▼'
                                ? const Color(0xFFFF0040)
                                : Colors.white24,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Flag
                  Text(fighter.flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                fighter.name.toUpperCase(),
                                style: TextStyle(
                                  color: isChamp
                                      ? const Color(0xFFFFD700)
                                      : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isIbc) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF0040),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'IBC III',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fighter.record} • ${fighter.gym}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // ELO + Streak
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${fighter.elo}',
                        style: TextStyle(
                          color: isChamp
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF00E5FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (fighter.winStreak > 0)
                        Text(
                          '🔥 ${fighter.winStreak}W',
                          style: const TextStyle(
                            color: Color(0xFFFF6600),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF0A0A14),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events,
            color: Colors.white.withValues(alpha: 0.15),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'DFC ELO RANKINGS • UPDATED AFTER EVERY EVENT',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/ibc/live'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0040).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'IBC III TOMORROW →',
                style: TextStyle(
                  color: Color(0xFFFF0040),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // IBC III fighters for badge tagging
  static const _ibcFighters = {
    'robert-whittaker',
    'tai-tuivasa',
    'jack-della-maddalena',
    'dan-hooker',
    'tyson-pedro',
    'jimmy-crute',
    'kai-kara-france',
    'carlos-ulberg',
    'casey-oneill',
    'alexander-volkanovski',
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA
// ═══════════════════════════════════════════════════════════════════════════

class _RankedFighter {
  final String name;
  final String id;
  final String record;
  final String flag;
  final String division;
  final String gym;
  final int elo;
  final int winStreak;
  final String trend; // ▲ ▼ —

  const _RankedFighter(
    this.name,
    this.id,
    this.record,
    this.flag,
    this.division,
    this.gym,
    this.elo,
    this.winStreak,
    this.trend,
  );
}
