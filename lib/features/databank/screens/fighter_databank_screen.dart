import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_logos.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/databank_service.dart';
import '../../../shared/models/user_model.dart';

// =============================================================================
// FIGHTER RANKINGS v4.0 — Compact Professional Rankings Table
// =============================================================================
// Inspired by UFC.com / Tapology / Sherdog / BoxRec rankings.
// Compact rows with rank, flag, name, record, division, and tier.
// 13 ranked fighters from Champion (#1) through Prospects.
// =============================================================================

class FighterDatabankScreen extends StatefulWidget {
  const FighterDatabankScreen({super.key});

  @override
  State<FighterDatabankScreen> createState() => _FighterDatabankScreenState();
}

class _FighterDatabankScreenState extends State<FighterDatabankScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  String _viewFilter = 'All';
  String _sortBy = 'rank';
  bool _sortAsc = true;
  List<_RankedFighter> _firestoreFighters = [];

  // Country code → emoji flag
  static String _flag(String code) {
    return code
        .toUpperCase()
        .codeUnits
        .map((c) => String.fromCharCode(0x1F1E6 - 0x41 + c))
        .join();
  }

  // ── 13 Ranked Fighters ────────────────────────────────────────────────
  final List<_RankedFighter> _rankings = const [
    _RankedFighter(
      rank: 1,
      name: 'Robert Whittaker',
      nickname: 'The Reaper',
      weightClass: 'Middleweight',
      sport: 'MMA',
      record: '25-7-0',
      wins: 25,
      losses: 7,
      draws: 0,
      knockouts: 10,
      submissions: 5,
      winPct: 78.1,
      finishRate: 60.0,
      city: 'Sydney',
      countryCode: 'AU',
      stance: 'Orthodox',
      heightCm: 183,
      reachCm: 185,
      tier: _Tier.champion,
      striking: 0.93,
      grappling: 0.78,
      cardio: 0.88,
      power: 0.90,
      fightIQ: 0.95,
      chin: 0.88,
      bio:
          'Former UFC Middleweight Champion. One of Australia\'s greatest MMA exports with elite striking and granite chin.',
      streak: 'W3',
    ),
    _RankedFighter(
      rank: 2,
      name: 'Alexander Volkanovski',
      nickname: 'The Great',
      weightClass: 'Featherweight',
      sport: 'MMA',
      record: '26-4-0',
      wins: 26,
      losses: 4,
      draws: 0,
      knockouts: 13,
      submissions: 3,
      winPct: 86.7,
      finishRate: 61.5,
      city: 'Wollongong',
      countryCode: 'AU',
      stance: 'Orthodox',
      heightCm: 168,
      reachCm: 172,
      tier: _Tier.champion,
      striking: 0.92,
      grappling: 0.85,
      cardio: 0.96,
      power: 0.82,
      fightIQ: 0.96,
      chin: 0.90,
      bio:
          'Former UFC Featherweight Champion. Unmatched cardio and fight IQ. City Kickboxing trained.',
      streak: 'W1',
    ),
    _RankedFighter(
      rank: 3,
      name: 'Israel Adesanya',
      nickname: 'The Last Stylebender',
      weightClass: 'Middleweight',
      sport: 'MMA',
      record: '24-4-0',
      wins: 24,
      losses: 4,
      draws: 0,
      knockouts: 16,
      submissions: 0,
      winPct: 85.7,
      finishRate: 66.7,
      city: 'Auckland',
      countryCode: 'NZ',
      stance: 'Switch',
      heightCm: 193,
      reachCm: 203,
      tier: _Tier.elite,
      striking: 0.97,
      grappling: 0.55,
      cardio: 0.85,
      power: 0.88,
      fightIQ: 0.92,
      chin: 0.82,
      bio:
          'Former UFC Middleweight Champion. Kickboxing prodigy with pinpoint counter-striking accuracy. City Kickboxing, Auckland.',
      streak: 'W2',
    ),
    _RankedFighter(
      rank: 4,
      name: 'Casey O\'Neill',
      nickname: 'King Casey',
      weightClass: 'Flyweight',
      sport: 'MMA',
      record: '10-2-0',
      wins: 10,
      losses: 2,
      draws: 0,
      knockouts: 3,
      submissions: 4,
      winPct: 83.3,
      finishRate: 70.0,
      city: 'Gold Coast',
      countryCode: 'AU',
      stance: 'Southpaw',
      heightCm: 165,
      reachCm: 170,
      tier: _Tier.contender,
      striking: 0.82,
      grappling: 0.85,
      cardio: 0.88,
      power: 0.68,
      fightIQ: 0.80,
      chin: 0.78,
      bio:
          'Rising star in women\'s MMA. Scottish-born, Australian-raised. Dynamic finisher.',
      streak: 'W2',
    ),
    _RankedFighter(
      rank: 5,
      name: 'Tai Tuivasa',
      nickname: 'Bam Bam',
      weightClass: 'Heavyweight',
      sport: 'MMA',
      record: '15-8-0',
      wins: 15,
      losses: 8,
      draws: 0,
      knockouts: 12,
      submissions: 0,
      winPct: 65.2,
      finishRate: 80.0,
      city: 'Sydney',
      countryCode: 'AU',
      stance: 'Orthodox',
      heightCm: 188,
      reachCm: 190,
      tier: _Tier.contender,
      striking: 0.85,
      grappling: 0.45,
      cardio: 0.58,
      power: 0.97,
      fightIQ: 0.65,
      chin: 0.88,
      bio:
          'Fan-favourite heavyweight with explosive knockout power. Known for his Shoey celebrations after wins.',
      streak: 'W1',
    ),
    _RankedFighter(
      rank: 6,
      name: 'Stamp Fairtex',
      nickname: 'Stamp',
      weightClass: 'Atomweight',
      sport: 'Muay Thai',
      record: '73-19-5',
      wins: 73,
      losses: 19,
      draws: 5,
      knockouts: 28,
      submissions: 2,
      winPct: 75.3,
      finishRate: 41.1,
      city: 'Pattaya',
      countryCode: 'TH',
      stance: 'Orthodox',
      heightCm: 160,
      reachCm: 163,
      tier: _Tier.champion,
      striking: 0.94,
      grappling: 0.75,
      cardio: 0.90,
      power: 0.72,
      fightIQ: 0.88,
      chin: 0.80,
      bio:
          'ONE Championship triple-sport star. Muay Thai, kickboxing, and MMA champion.',
      streak: 'W5',
    ),
    _RankedFighter(
      rank: 7,
      name: 'John Wayne Parr',
      nickname: 'The Gunslinger',
      weightClass: 'Middleweight',
      sport: 'Kickboxing',
      record: '99-37-0',
      wins: 99,
      losses: 37,
      draws: 0,
      knockouts: 48,
      submissions: 0,
      winPct: 72.8,
      finishRate: 48.5,
      city: 'Gold Coast',
      countryCode: 'AU',
      stance: 'Orthodox',
      heightCm: 178,
      reachCm: 180,
      tier: _Tier.elite,
      striking: 0.93,
      grappling: 0.30,
      cardio: 0.82,
      power: 0.88,
      fightIQ: 0.90,
      chin: 0.85,
      bio:
          'Australian Muay Thai legend. 10x World Champion with 99 professional victories.',
      streak: 'W2',
    ),
    _RankedFighter(
      rank: 8,
      name: 'Jack Della Maddalena',
      nickname: 'JDM',
      weightClass: 'Welterweight',
      sport: 'MMA',
      record: '18-3-0',
      wins: 18,
      losses: 2,
      draws: 0,
      knockouts: 12,
      submissions: 1,
      winPct: 89.5,
      finishRate: 76.5,
      city: 'Perth',
      countryCode: 'AU',
      stance: 'Orthodox',
      heightCm: 183,
      reachCm: 188,
      tier: _Tier.contender,
      striking: 0.92,
      grappling: 0.72,
      cardio: 0.82,
      power: 0.90,
      fightIQ: 0.82,
      chin: 0.84,
      bio:
          'Australia\'s welterweight sensation. Elite boxing with devastating KO power. P4P ranked.',
      streak: 'W5',
    ),
    _RankedFighter(
      rank: 9,
      name: 'Dan Hooker',
      nickname: 'The Hangman',
      weightClass: 'Lightweight',
      sport: 'MMA',
      record: '24-12-0',
      wins: 24,
      losses: 12,
      draws: 0,
      knockouts: 11,
      submissions: 5,
      winPct: 66.7,
      finishRate: 66.7,
      city: 'Auckland',
      countryCode: 'NZ',
      stance: 'Orthodox',
      heightCm: 183,
      reachCm: 193,
      tier: _Tier.contender,
      striking: 0.88,
      grappling: 0.72,
      cardio: 0.82,
      power: 0.85,
      fightIQ: 0.80,
      chin: 0.72,
      bio:
          'City Kickboxing\'s warrior. Never ducks a fight, always brings violence. Comeback king of the lightweight division.',
      streak: 'W3',
    ),
    _RankedFighter(
      rank: 10,
      name: 'Tyson Pedro',
      nickname: 'Tyson',
      weightClass: 'Light Heavyweight',
      sport: 'MMA',
      record: '10-4-0',
      wins: 10,
      losses: 4,
      draws: 0,
      knockouts: 8,
      submissions: 1,
      winPct: 71.4,
      finishRate: 90.0,
      city: 'Sydney',
      countryCode: 'AU',
      stance: 'Orthodox',
      heightCm: 191,
      reachCm: 193,
      tier: _Tier.rising,
      striking: 0.85,
      grappling: 0.55,
      cardio: 0.65,
      power: 0.92,
      fightIQ: 0.68,
      chin: 0.78,
      bio:
          'Indigenous Australian fighter with impressive finishing ability. 8 KOs in 10 wins.',
      streak: 'W3',
    ),
    _RankedFighter(
      rank: 11,
      name: 'Molly McCann',
      nickname: 'Meatball',
      weightClass: 'Flyweight',
      sport: 'MMA',
      record: '14-5-0',
      wins: 14,
      losses: 5,
      draws: 0,
      knockouts: 5,
      submissions: 1,
      winPct: 73.7,
      finishRate: 42.9,
      city: 'Liverpool',
      countryCode: 'GB',
      stance: 'Orthodox',
      heightCm: 163,
      reachCm: 165,
      tier: _Tier.contender,
      striking: 0.82,
      grappling: 0.65,
      cardio: 0.85,
      power: 0.75,
      fightIQ: 0.78,
      chin: 0.80,
      bio:
          'Liverpool\'s spinning-elbow specialist. Fan favourite with infectious energy.',
      streak: 'W2',
    ),
    _RankedFighter(
      rank: 12,
      name: 'Kai Kara-France',
      nickname: 'Don\'t Blink',
      weightClass: 'Flyweight',
      sport: 'MMA',
      record: '24-11-0',
      wins: 24,
      losses: 11,
      draws: 0,
      knockouts: 11,
      submissions: 2,
      winPct: 68.6,
      finishRate: 54.2,
      city: 'Auckland',
      countryCode: 'NZ',
      stance: 'Orthodox',
      heightCm: 168,
      reachCm: 170,
      tier: _Tier.contender,
      striking: 0.87,
      grappling: 0.60,
      cardio: 0.80,
      power: 0.83,
      fightIQ: 0.75,
      chin: 0.76,
      bio:
          'City Kickboxing flyweight with legitimate one-punch power. Former UFC title challenger and fan favourite.',
      streak: 'L1',
    ),
    _RankedFighter(
      rank: 13,
      name: 'Jimmy Crute',
      nickname: 'The Brute',
      weightClass: 'Light Heavyweight',
      sport: 'MMA',
      record: '14-3-0',
      wins: 14,
      losses: 3,
      draws: 0,
      knockouts: 6,
      submissions: 6,
      winPct: 82.4,
      finishRate: 85.7,
      city: 'Melbourne',
      countryCode: 'AU',
      stance: 'Southpaw',
      heightCm: 185,
      reachCm: 188,
      tier: _Tier.rising,
      striking: 0.80,
      grappling: 0.82,
      cardio: 0.78,
      power: 0.85,
      fightIQ: 0.76,
      chin: 0.74,
      bio:
          'Melbourne\'s well-rounded finisher. Dangerous everywhere — 6 KOs and 6 submissions.',
      streak: 'W2',
    ),
  ];

  List<_RankedFighter> get _allFighters {
    // Firestore fighters take priority; seed data fills in when DB is empty
    if (_firestoreFighters.isNotEmpty) {
      // Merge: Firestore first, then seed data with re-ranked positions
      final merged = <_RankedFighter>[..._firestoreFighters];
      for (final seed in _rankings) {
        if (!merged.any((f) => f.name == seed.name)) {
          merged.add(seed);
        }
      }
      // Re-rank
      return merged
          .asMap()
          .entries
          .map(
            (e) => _RankedFighter(
              rank: e.key + 1,
              name: e.value.name,
              nickname: e.value.nickname,
              weightClass: e.value.weightClass,
              sport: e.value.sport,
              record: e.value.record,
              wins: e.value.wins,
              losses: e.value.losses,
              draws: e.value.draws,
              knockouts: e.value.knockouts,
              submissions: e.value.submissions,
              winPct: e.value.winPct,
              finishRate: e.value.finishRate,
              city: e.value.city,
              countryCode: e.value.countryCode,
              stance: e.value.stance,
              heightCm: e.value.heightCm,
              reachCm: e.value.reachCm,
              tier: e.value.tier,
              striking: e.value.striking,
              grappling: e.value.grappling,
              cardio: e.value.cardio,
              power: e.value.power,
              fightIQ: e.value.fightIQ,
              chin: e.value.chin,
              bio: e.value.bio,
              streak: e.value.streak,
            ),
          )
          .toList();
    }
    return _rankings;
  }

  List<_RankedFighter> get _filtered {
    final source = _allFighters;
    List<_RankedFighter> list;
    if (_viewFilter == 'All') {
      list = List.of(source);
    } else if (_viewFilter == 'Women') {
      list = source
          .where(
            (f) =>
                f.name.contains('Nina') ||
                f.name.contains('Elara') ||
                f.name.contains('Zara') ||
                f.name.contains('Aisha') ||
                f.name.contains('Sakura'),
          )
          .toList();
    } else {
      list = source.where((f) => f.tier.label == _viewFilter).toList();
    }

    // Sort
    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'name':
          cmp = a.name.compareTo(b.name);
        case 'record':
          cmp = b.wins.compareTo(a.wins);
        case 'winPct':
          cmp = b.winPct.compareTo(a.winPct);
        case 'ko':
          cmp = b.knockouts.compareTo(a.knockouts);
        default:
          cmp = a.rank.compareTo(b.rank);
      }
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _loadFirestoreFighters();
  }

  Future<void> _loadFirestoreFighters() async {
    try {
      final databankService = DatabankService();
      final pool = await databankService.getAvailablePool(limit: 100);
      if (pool.isNotEmpty && mounted) {
        setState(() {
          _firestoreFighters = pool.asMap().entries.map((e) {
            final d = e.value;
            final wins = (d['wins'] as num?)?.toInt() ?? 0;
            final losses = (d['losses'] as num?)?.toInt() ?? 0;
            final draws = (d['draws'] as num?)?.toInt() ?? 0;
            final kos = (d['knockouts'] as num?)?.toInt() ?? 0;
            final subs = (d['submissions'] as num?)?.toInt() ?? 0;
            final total = wins + losses + draws;
            return _RankedFighter(
              rank: e.key + 1,
              name: d['fullName'] as String? ?? 'Unknown',
              nickname: d['nickname'] as String?,
              weightClass: d['weightClass'] as String? ?? 'Open',
              sport: d['sportType'] as String? ?? 'MMA',
              record: '$wins-$losses-$draws',
              wins: wins,
              losses: losses,
              draws: draws,
              knockouts: kos,
              submissions: subs,
              winPct: total > 0 ? (wins / total * 100) : 0,
              finishRate: wins > 0 ? ((kos + subs) / wins * 100) : 0,
              city: d['city'] as String? ?? '',
              countryCode: _countryToCode(d['country'] as String? ?? 'AU'),
              stance: (d['stance'] as String?) ?? 'Orthodox',
              heightCm: (d['heightCm'] as num?)?.toDouble() ?? 175,
              reachCm: (d['reachCm'] as num?)?.toDouble() ?? 178,
              tier: _assignTier(wins, losses, total),
              striking: 0.70,
              grappling: 0.70,
              cardio: 0.70,
              power: 0.70,
              fightIQ: 0.70,
              chin: 0.70,
              bio:
                  d['matchupNotes'] as String? ??
                  'Registered DFC DataFightBank fighter.',
              streak: '',
            );
          }).toList();
        });
      }
    } catch (_) {
      // Silently fall back to seed data
    } finally {
      if (mounted) setState(() {});
    }
  }

  static _Tier _assignTier(int wins, int losses, int total) {
    if (total == 0) return _Tier.prospect;
    final winPct = wins / total;
    if (wins >= 20 && winPct >= 0.9) return _Tier.champion;
    if (wins >= 15 && winPct >= 0.8) return _Tier.elite;
    if (wins >= 10 && winPct >= 0.65) return _Tier.contender;
    if (wins >= 5) return _Tier.rising;
    return _Tier.prospect;
  }

  static String _countryToCode(String country) {
    const map = {
      'Australia': 'AU',
      'United States': 'US',
      'United Kingdom': 'GB',
      'Canada': 'CA',
      'New Zealand': 'NZ',
      'Ireland': 'IE',
      'South Africa': 'ZA',
      'Philippines': 'PH',
      'Thailand': 'TH',
      'Japan': 'JP',
      'Brazil': 'BR',
      'Germany': 'DE',
      'France': 'FR',
      'Mexico': 'MX',
      'India': 'IN',
      'Indonesia': 'ID',
      'Netherlands': 'NL',
      'Sweden': 'SE',
      'Singapore': 'SG',
      'South Korea': 'KR',
    };
    return map[country] ?? country.substring(0, 2).toUpperCase();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fighters = _filtered;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildRegisterBanner(),
            _buildTierSummary(),
            _buildFilterTabs(),
            _buildColumnHeaders(w),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: fighters.length,
                padding: const EdgeInsets.only(bottom: 80),
                itemBuilder: (ctx, i) => _buildRankRow(fighters[i], i, w),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => context.push('/ai-card-creator'),
        backgroundColor: AppColors.neonMagenta,
        child: const Icon(Icons.auto_awesome, size: 20),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white.withValues(alpha: 0.6),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // DFC Logo
          Image.asset(
            AppLogos.icon,
            width: 28,
            height: 28,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [
                      AppColors.neonAmber,
                      AppColors.neonRed,
                      AppColors.neonMagenta,
                    ],
                  ).createShader(b),
                  child: const Text(
                    'FIGHTER RANKINGS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                Text(
                  'POUND FOR POUND  \u2022  UPDATED FEB 2026',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/ai-card-creator'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    AppColors.neonMagenta.withValues(alpha: 0.15),
                    AppColors.neonPurple.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: AppColors.neonMagenta.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.neonMagenta,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'CARDS',
                    style: TextStyle(
                      color: AppColors.neonMagenta.withValues(alpha: 0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
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

  // ─── REGISTER BANNER ─────────────────────────────────────────────────
  Widget _buildRegisterBanner() {
    final authService = context.read<AuthService>();
    final user = authService.userModel;
    final isFighter = user?.role == UserRole.fighter;
    final city = user?.metadata?['city'] as String? ?? '';
    final country = user?.metadata?['country'] as String? ?? '';
    final registered = user?.metadata?['databankRegistered'] == true;

    // Only show for fighters who haven't registered yet
    if (!isFighter || registered) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            AppColors.neonGreen.withValues(alpha: 0.06),
            AppColors.neonCyan.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified,
                color: AppColors.neonGreen.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'REGISTER IN THE DFC DATAFIGHTBANK',
                  style: TextStyle(
                    color: AppColors.neonGreen.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            city.isNotEmpty
                ? 'Get found by promoters worldwide. Your location ($city, $country) will appear in the global fighter database.'
                : 'Get found by promoters worldwide. Add your location in your profile to appear in the global fighter database.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 9,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showRegisterSheet(user, city, country),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    AppColors.neonGreen.withValues(alpha: 0.2),
                    AppColors.neonCyan.withValues(alpha: 0.12),
                  ],
                ),
                border: Border.all(
                  color: AppColors.neonGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    color: AppColors.neonGreen.withValues(alpha: 0.8),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'REGISTER AS DFC FIGHTER',
                    style: TextStyle(
                      color: AppColors.neonGreen.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
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

  void _showRegisterSheet(UserModel? user, String city, String country) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Icon(Icons.verified, color: AppColors.neonGreen, size: 36),
            const SizedBox(height: 10),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [AppColors.neonGreen, AppColors.neonCyan],
              ).createShader(b),
              child: const Text(
                'DFC DATAFIGHTBANK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Join the global fighter database',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            // Profile preview card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.neonGreen.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          (user?.displayName ?? 'F')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.neonGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Fighter',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (city.isNotEmpty)
                              Text(
                                '$city, $country',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.neonGreen.withValues(alpha: 0.12),
                        ),
                        child: Text(
                          'FIGHTER',
                          style: TextStyle(
                            color: AppColors.neonGreen.withValues(alpha: 0.7),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Benefits
            ...[
              ('Visible to promoters & matchmakers worldwide', Icons.public),
              (
                'Ranked in DFC pound-for-pound leaderboards',
                Icons.emoji_events,
              ),
              ('Receive fight offers direct to your inbox', Icons.mail),
              ('Verified DFC fighter badge on your profile', Icons.verified),
            ].map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      b.$2,
                      color: AppColors.neonCyan.withValues(alpha: 0.5),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b.$1,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                // Mark as registered in metadata
                final authSvc = context.read<AuthService>();
                // Update metadata with databankRegistered flag
                if (authSvc.userModel != null) {
                  final meta = Map<String, dynamic>.from(
                    authSvc.userModel!.metadata ?? {},
                  );
                  meta['databankRegistered'] = true;
                  meta['databankRegisteredAt'] = DateTime.now()
                      .toIso8601String();
                  await authSvc.updateProfileMetadata(meta);
                }
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Welcome to the DFC DataFightBank! You\'re now visible to promoters worldwide.',
                      ),
                      backgroundColor: AppColors.neonGreen.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [AppColors.neonGreen, AppColors.neonCyan],
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.black, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'REGISTER NOW',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (city.isEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile-setup');
                },
                child: Text(
                  'Add your location first →',
                  style: TextStyle(
                    color: AppColors.neonCyan.withValues(alpha: 0.6),
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── TIER SUMMARY BAR ──────────────────────────────────────────────────
  Widget _buildTierSummary() {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, _) => Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              AppColors.neonAmber.withValues(
                alpha: 0.04 + _glowCtrl.value * 0.02,
              ),
              AppColors.neonRed.withValues(alpha: 0.02),
              AppColors.neonMagenta.withValues(alpha: 0.015),
            ],
          ),
          border: Border.all(
            color: AppColors.neonAmber.withValues(
              alpha: 0.06 + _glowCtrl.value * 0.03,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _tierBadge('\u{1F451}', '1', 'CHAMP', AppColors.neonAmber),
            _divider(),
            _tierBadge('\u{1F947}', '2', 'ELITE', AppColors.neonCyan),
            _divider(),
            _tierBadge('\u{1F94A}', '4', 'CONTEND', AppColors.neonOrange),
            _divider(),
            _tierBadge('\u{2B06}', '3', 'RISING', AppColors.neonGreen),
            _divider(),
            _tierBadge('\u{2B50}', '3', 'PROSPECT', AppColors.neonPurple),
          ],
        ),
      ),
    );
  }

  Widget _tierBadge(String emoji, String count, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 3),
            Text(
              count,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 6,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: color.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 24,
    color: Colors.white.withValues(alpha: 0.04),
  );

  // ─── FILTER TABS ───────────────────────────────────────────────────────
  Widget _buildFilterTabs() {
    const filters = [
      'All',
      'Women',
      'Champion',
      'Elite',
      'Contender',
      'Rising',
      'Prospect',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SizedBox(
        height: 28,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: filters.map((f) {
            final sel = _viewFilter == f;
            final color = _filterColor(f);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _viewFilter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: sel
                        ? color.withValues(alpha: 0.12)
                        : Colors.transparent,
                    border: Border.all(
                      color: sel
                          ? color.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Text(
                    f.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: sel ? color : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _filterColor(String f) {
    switch (f) {
      case 'Champion':
        return AppColors.neonAmber;
      case 'Elite':
        return AppColors.neonCyan;
      case 'Contender':
        return AppColors.neonOrange;
      case 'Rising':
        return AppColors.neonGreen;
      case 'Prospect':
        return AppColors.neonPurple;
      case 'Women':
        return AppColors.neonMagenta;
      default:
        return AppTheme.neonCyan;
    }
  }

  // ─── COLUMN HEADERS ────────────────────────────────────────────────────
  Widget _buildColumnHeaders(double screenW) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          _colHeader('#', 'rank', 28),
          const SizedBox(width: 8),
          Expanded(child: _colHeader('FIGHTER', 'name', 0)),
          _colHeader('REC', 'record', 52),
          if (screenW > 380) _colHeader('WIN%', 'winPct', 40),
          if (screenW > 440) _colHeader('KO', 'ko', 28),
          _colHeader('TIER', '', 48),
          const SizedBox(width: 6),
          _colHeader('STK', '', 30),
        ],
      ),
    );
  }

  Widget _colHeader(String label, String sortKey, double width) {
    final isSorted = _sortBy == sortKey && sortKey.isNotEmpty;
    return GestureDetector(
      onTap: sortKey.isEmpty
          ? null
          : () {
              setState(() {
                if (_sortBy == sortKey) {
                  _sortAsc = !_sortAsc;
                } else {
                  _sortBy = sortKey;
                  _sortAsc = true;
                }
              });
            },
      child: SizedBox(
        width: width == 0 ? null : width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: isSorted
                    ? AppColors.neonCyan
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
            if (isSorted)
              Icon(
                _sortAsc ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 12,
                color: AppColors.neonCyan,
              ),
          ],
        ),
      ),
    );
  }

  // ─── RANK ROW ──────────────────────────────────────────────────────────
  Widget _buildRankRow(_RankedFighter f, int index, double screenW) {
    final tierColor = f.tier.color;
    final isChamp = f.tier == _Tier.champion;

    return GestureDetector(
      onTap: () => _showFighterDetail(f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isChamp
              ? AppColors.neonAmber.withValues(alpha: 0.03)
              : index.isEven
              ? Colors.white.withValues(alpha: 0.012)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isChamp
                  ? AppColors.neonAmber.withValues(alpha: 0.6)
                  : Colors.transparent,
              width: isChamp ? 2 : 0,
            ),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
          ),
        ),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 28,
              child: isChamp
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\u{1F451}', style: TextStyle(fontSize: 12)),
                      ],
                    )
                  : Text(
                      '${f.rank}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: f.rank <= 3
                            ? tierColor
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
            ),

            const SizedBox(width: 8),

            // Flag + Name + Nickname + Division
            Expanded(
              child: Row(
                children: [
                  // Country flag
                  Text(
                    _flag(f.countryCode),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 8),

                  // Name block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                f.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isChamp
                                      ? AppColors.neonAmber
                                      : Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                            if (f.nickname != null) ...[
                              const SizedBox(width: 5),
                              Text(
                                '"${f.nickname}"',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontStyle: FontStyle.italic,
                                  color: tierColor.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Text(
                              f.weightClass,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 2,
                              height: 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            Text(
                              f.sport,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neonPurple.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 2,
                              height: 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            Text(
                              f.city,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.2),
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

            // Record
            SizedBox(
              width: 52,
              child: Text(
                f.record,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),

            // Win %
            if (screenW > 380)
              SizedBox(
                width: 40,
                child: Text(
                  '${f.winPct.toStringAsFixed(0)}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: f.winPct >= 85
                        ? AppColors.neonGreen
                        : f.winPct >= 75
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppColors.neonOrange.withValues(alpha: 0.7),
                  ),
                ),
              ),

            // KOs
            if (screenW > 440)
              SizedBox(
                width: 28,
                child: Text(
                  '${f.knockouts}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: f.knockouts >= 10
                        ? AppColors.neonRed.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),

            // Tier badge
            SizedBox(
              width: 48,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: tierColor.withValues(alpha: 0.08),
                  border: Border.all(color: tierColor.withValues(alpha: 0.15)),
                ),
                child: Text(
                  f.tier.short.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: tierColor,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Streak
            SizedBox(
              width: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: f.streak.startsWith('W')
                      ? AppColors.neonGreen.withValues(alpha: 0.08)
                      : AppColors.neonRed.withValues(alpha: 0.08),
                ),
                child: Text(
                  f.streak,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: f.streak.startsWith('W')
                        ? AppColors.neonGreen.withValues(alpha: 0.8)
                        : AppColors.neonRed.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FIGHTER DETAIL SHEET ─────────────────────────────────────────────
  void _showFighterDetail(_RankedFighter f) {
    final tc = f.tier.color;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1220),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: tc.withValues(alpha: 0.4), width: 2),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: tc.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Rank + Flag + Name header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [tc, tc.withValues(alpha: 0.6)],
                      ),
                    ),
                    child: Text(
                      '#${f.rank}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _flag(f.countryCode),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      f.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (f.nickname != null)
                Text(
                  '"${f.nickname}"',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: tc.withValues(alpha: 0.6),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                f.bio,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // Record + stats row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: tc.withValues(alpha: 0.04),
                  border: Border.all(color: tc.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Text(
                      f.record,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: tc,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat('KO', '${f.knockouts}', AppColors.neonRed),
                        _stat('SUB', '${f.submissions}', AppColors.neonPurple),
                        _stat(
                          'WIN%',
                          '${f.winPct.toStringAsFixed(1)}%',
                          AppColors.neonGreen,
                        ),
                        _stat(
                          'FIN%',
                          '${f.finishRate.toStringAsFixed(1)}%',
                          AppColors.neonAmber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Combat DNA bars
              _dnaBar('STRIKING', f.striking, AppColors.neonRed),
              _dnaBar('GRAPPLING', f.grappling, AppColors.neonGreen),
              _dnaBar('CARDIO', f.cardio, AppColors.neonCyan),
              _dnaBar('POWER', f.power, AppColors.neonOrange),
              _dnaBar('FIGHT IQ', f.fightIQ, AppColors.neonMagenta),
              _dnaBar('CHIN', f.chin, AppColors.neonPurple),

              const SizedBox(height: 14),

              // Info grid
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _infoPill(Icons.fitness_center, f.weightClass, tc),
                  _infoPill(Icons.sports_mma, f.sport, tc),
                  _infoPill(Icons.height, '${f.heightCm}cm', tc),
                  _infoPill(Icons.open_with, '${f.reachCm}cm reach', tc),
                  _infoPill(Icons.sports_martial_arts, f.stance, tc),
                  _infoPill(Icons.location_on, f.city, tc),
                ],
              ),

              const SizedBox(height: 18),

              // AI Card Creator button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/ai-card-creator', extra: f.rank);
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text(
                    'CREATE COLLECTIBLE CARD',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonMagenta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: color.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _dnaBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: color.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withValues(alpha: 0.03),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.4), color],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(value * 100).toInt()}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.04),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TIER SYSTEM
// =============================================================================
enum _Tier {
  champion('Champion', 'CHAMP', AppColors.neonAmber),
  elite('Elite', 'ELITE', AppColors.neonCyan),
  contender('Contender', 'CNTDR', AppColors.neonOrange),
  rising('Rising', 'RISE', AppColors.neonGreen),
  prospect('Prospect', 'PRSPCT', AppColors.neonPurple);

  final String label;
  final String short;
  final Color color;
  const _Tier(this.label, this.short, this.color);
}

// =============================================================================
// DATA MODEL
// =============================================================================
class _RankedFighter {
  final int rank;
  final String name;
  final String? nickname;
  final String weightClass;
  final String sport;
  final String record;
  final int wins, losses, draws;
  final int knockouts, submissions;
  final double winPct, finishRate;
  final String city, countryCode, stance;
  final double heightCm, reachCm;
  final _Tier tier;
  final double striking, grappling, cardio, power, fightIQ, chin;
  final String bio;
  final String streak;

  const _RankedFighter({
    required this.rank,
    required this.name,
    this.nickname,
    required this.weightClass,
    required this.sport,
    required this.record,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.knockouts,
    required this.submissions,
    required this.winPct,
    required this.finishRate,
    required this.city,
    required this.countryCode,
    required this.stance,
    required this.heightCm,
    required this.reachCm,
    required this.tier,
    required this.striking,
    required this.grappling,
    required this.cardio,
    required this.power,
    required this.fightIQ,
    required this.chin,
    required this.bio,
    required this.streak,
  });
}
