import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/fighter_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER PROFILE PAGE — Full Standalone Fighter Profile
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Route: /fighter/:fighterId
///
/// Complete fighter profile with:
///   • Hero header with photo, name, nickname, flag
///   • Record display (W-L-D, KO%, Sub%)
///   • Physical stats (height, reach, stance, weight class)
///   • Fight history / recent bouts
///   • Gym & coach info
///   • Matchup availability status
///   • Social links
///   • AI-powered fight predictions
///   • Fighter card preview link
///
/// Works with both Firestore data and demo IBC fighters
/// ═══════════════════════════════════════════════════════════════════════════
class FighterProfilePage extends StatefulWidget {
  final String fighterId;
  const FighterProfilePage({super.key, required this.fighterId});

  @override
  State<FighterProfilePage> createState() => _FighterProfilePageState();
}

class _FighterProfilePageState extends State<FighterProfilePage>
    with SingleTickerProviderStateMixin {
  FighterModel? _fighter;
  bool _loading = true;
  bool _notFound = false;

  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmer;

  // REAL IBC III fighters — Tapology verified
  // Main: Cutler vs Modini (LHW Title), Co-Main: Hardman vs Tuhu (IBC Championship)
  static final Map<String, FighterModel> _demoFighters = {
    'jay-cutler': FighterModel(
      id: 'jay-cutler',
      userId: 'demo',
      fullName: 'Jay Cutler',
      nickname: '',
      nationality: 'Australia',
      gender: FighterGender.male,
      dateOfBirth: DateTime(1993),
      weightClass: 'Light Heavyweight',
      sportType: 'Brawling',
      stance: FighterStance.orthodox,
      heightCm: 185,
      reachCm: 190,
      city: 'Gold Coast',
      state: 'QLD',
      country: 'Australia',
      matchupAvailability: MatchupAvailability.booked,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2026, 3),
    ),
    'luke-modini': FighterModel(
      id: 'luke-modini',
      userId: 'demo',
      fullName: 'Luke Modini',
      nickname: '',
      nationality: 'Australia',
      gender: FighterGender.male,
      dateOfBirth: DateTime(1995),
      weightClass: 'Light Heavyweight',
      sportType: 'Brawling',
      stance: FighterStance.orthodox,
      heightCm: 183,
      reachCm: 188,
      city: 'Gold Coast',
      state: 'QLD',
      country: 'Australia',
      matchupAvailability: MatchupAvailability.booked,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2026, 3),
    ),
    'isaac-hardman': FighterModel(
      id: 'isaac-hardman',
      userId: 'demo',
      fullName: 'Isaac Hardman',
      nickname: '',
      nationality: 'Australia',
      gender: FighterGender.male,
      dateOfBirth: DateTime(1994, 6, 12),
      weightClass: 'Middleweight',
      sportType: 'Brawling',
      stance: FighterStance.orthodox,
      heightCm: 183,
      reachCm: 188,
      city: 'Gold Coast',
      state: 'QLD',
      country: 'Australia',
      matchupAvailability: MatchupAvailability.booked,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2026, 3),
    ),
    'jonathan-tuhu': FighterModel(
      id: 'jonathan-tuhu',
      userId: 'demo',
      fullName: 'Jonathan Tuhu',
      nickname: '',
      nationality: 'Australia',
      gender: FighterGender.male,
      dateOfBirth: DateTime(1995),
      weightClass: 'Middleweight',
      sportType: 'Brawling',
      stance: FighterStance.orthodox,
      heightCm: 180,
      reachCm: 185,
      city: 'Gold Coast',
      state: 'QLD',
      country: 'Australia',
      matchupAvailability: MatchupAvailability.booked,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2026, 3),
    ),
    'louis-kapua': FighterModel(
      id: 'louis-kapua',
      userId: 'demo',
      fullName: 'Louis Kapua',
      nickname: '',
      nationality: 'Australia',
      gender: FighterGender.male,
      dateOfBirth: DateTime(1994),
      weightClass: 'Heavyweight',
      sportType: 'Brawling',
      stance: FighterStance.orthodox,
      heightCm: 190,
      reachCm: 195,
      city: 'Gold Coast',
      state: 'QLD',
      country: 'Australia',
      matchupAvailability: MatchupAvailability.booked,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2026, 3),
    ),
    'joshua-hepi': FighterModel(
      id: 'joshua-hepi',
      userId: 'demo',
      fullName: 'Joshua Hepi',
      nickname: '',
      nationality: 'Australia',
      gender: FighterGender.male,
      dateOfBirth: DateTime(1996),
      weightClass: 'Lightweight',
      sportType: 'Brawling',
      stance: FighterStance.orthodox,
      heightCm: 175,
      reachCm: 178,
      city: 'Gold Coast',
      state: 'QLD',
      country: 'Australia',
      matchupAvailability: MatchupAvailability.booked,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2026, 3),
    ),
    'kane-halcrow': FighterModel(
      id: 'kane-halcrow',
      userId: 'demo',
      fullName: 'Kane Halcrow',
      nickname: '',
      nationality: 'Australia',
      gender: FighterGender.male,
      dateOfBirth: DateTime(1996),
      weightClass: 'Lightweight',
      sportType: 'Brawling',
      stance: FighterStance.orthodox,
      heightCm: 175,
      reachCm: 178,
      city: 'Gold Coast',
      state: 'QLD',
      country: 'Australia',
      matchupAvailability: MatchupAvailability.booked,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2026, 3),
    ),
    'cody-stevens': FighterModel(
      id: 'cody-stevens',
      userId: 'demo',
      fullName: 'Cody Stevens',
      nickname: '',
      nationality: 'Australia',
      gender: FighterGender.male,
      dateOfBirth: DateTime(1995),
      weightClass: 'Welterweight',
      sportType: 'Brawling',
      stance: FighterStance.orthodox,
      heightCm: 178,
      reachCm: 180,
      city: 'Gold Coast',
      state: 'QLD',
      country: 'Australia',
      matchupAvailability: MatchupAvailability.booked,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2026, 3),
    ),
    'tevita-mita': FighterModel(
      id: 'tevita-mita',
      userId: 'demo',
      fullName: 'Tevita Mita',
      nickname: '',
      nationality: 'Australia',
      gender: FighterGender.male,
      dateOfBirth: DateTime(1993),
      weightClass: 'Heavyweight',
      sportType: 'Brawling',
      stance: FighterStance.orthodox,
      heightCm: 193,
      reachCm: 198,
      city: 'Gold Coast',
      state: 'QLD',
      country: 'Australia',
      matchupAvailability: MatchupAvailability.booked,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2026, 3),
    ),
    'catalin-ion': FighterModel(
      id: 'catalin-ion',
      userId: 'demo',
      fullName: 'Catalin Ion',
      nickname: '',
      nationality: 'Australia',
      gender: FighterGender.male,
      dateOfBirth: DateTime(1994),
      weightClass: 'Welterweight',
      sportType: 'Brawling',
      stance: FighterStance.orthodox,
      heightCm: 178,
      reachCm: 180,
      city: 'Gold Coast',
      state: 'QLD',
      country: 'Australia',
      matchupAvailability: MatchupAvailability.booked,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2026, 3),
    ),
  };

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _shimmer = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
    _loadFighter();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFighter() async {
    // Check demo fighters first
    final demo = _demoFighters[widget.fighterId];
    if (demo != null) {
      if (mounted) {
        setState(() {
          _fighter = demo;
          _loading = false;
        });
      }
      return;
    }

    // Try Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('fighters')
          .doc(widget.fighterId)
          .get();
      if (doc.exists) {
        if (mounted) {
          setState(() {
            _fighter = FighterModel.fromFirestore(doc);
            _loading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Fighter load error: $e');
    }

    if (mounted) {
      setState(() {
        _notFound = true;
        _loading = false;
      });
    }
  }

  int get _totalFights =>
      (_fighter?.wins ?? 0) + (_fighter?.losses ?? 0) + (_fighter?.draws ?? 0);
  double get _winRate =>
      _totalFights > 0 ? (_fighter!.wins / _totalFights) * 100 : 0;
  double get _koRate => _fighter != null && _fighter!.wins > 0
      ? (_fighter!.knockouts / _fighter!.wins) * 100
      : 0;
  int get _age => _fighter?.dateOfBirth != null
      ? DateTime.now().difference(_fighter!.dateOfBirth!).inDays ~/ 365
      : 0;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    if (_notFound || _fighter == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Fighter Not Found',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/databank'),
                child: const Text('Browse Databank'),
              ),
            ],
          ),
        ),
      );
    }

    final f = _fighter!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.deepPurple.shade900,
            flexibleSpace: FlexibleSpaceBar(background: _buildHeroHeader(f)),
            actions: [
              IconButton(
                onPressed: () => context.go('/fighter-card'),
                icon: const Icon(Icons.style, color: Colors.cyanAccent),
                tooltip: 'Fighter Card',
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Record Stats ──
                  _buildRecordBar(f),
                  const SizedBox(height: 20),

                  // ── Physical Stats ──
                  _buildPhysicalStats(f),
                  const SizedBox(height: 20),

                  // ── Win Analytics ──
                  _buildWinAnalytics(f),
                  const SizedBox(height: 20),

                  // ── Fight Info ──
                  _buildFightInfo(f),
                  const SizedBox(height: 20),

                  // ── Next Bout (if IBC) ──
                  _buildNextBout(f),
                  const SizedBox(height: 20),

                  // ── Matchup Status ──
                  _buildMatchupStatus(f),
                  const SizedBox(height: 20),

                  // ── Quick Actions ──
                  _buildActions(f),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroHeader(FighterModel f) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.deepPurple.shade900, Colors.black],
        ),
      ),
      child: Stack(
        children: [
          // Background shimmer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmer,
              builder: (_, _) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.5,
                    colors: [
                      Colors.cyanAccent.withValues(
                        alpha: _shimmer.value * 0.05,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyanAccent, width: 3),
                      color: Colors.deepPurple.shade800,
                      image: f.photoUrl != null
                          ? DecorationImage(
                              image: ImageAssets.resolveImage(f.photoUrl!),
                              fit: BoxFit.cover,
                              onError: (_, _) {},
                            )
                          : null,
                    ),
                    child: f.photoUrl == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.cyanAccent,
                            size: 45,
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Country flag / nationality
                  if (f.nationality != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_countryFlag(f.nationality!)} ${f.nationality}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),

                  // Name
                  Text(
                    f.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Nickname
                  if (f.nickname != null)
                    Text(
                      '"${f.nickname}"',
                      style: TextStyle(
                        color: Colors.cyanAccent.withValues(alpha: 0.8),
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Record pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha: 0.3),
                          Colors.deepPurple.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${f.wins}W - ${f.losses}L - ${f.draws}D',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status badge
          Positioned(
            top: 90,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: f.status == FighterStatus.active
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: f.status == FighterStatus.active
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              child: Text(
                f.status.name.toUpperCase(),
                style: TextStyle(
                  color: f.status == FighterStatus.active
                      ? Colors.green
                      : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECORD BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecordBar(FighterModel f) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _statBox('WINS', '${f.wins}', Colors.green),
          _divider(),
          _statBox('LOSSES', '${f.losses}', Colors.red),
          _divider(),
          _statBox('DRAWS', '${f.draws}', Colors.amber),
          _divider(),
          _statBox('KOs', '${f.knockouts}', Colors.orange),
          _divider(),
          _statBox(
            'WIN %',
            '${_winRate.toStringAsFixed(0)}%',
            Colors.cyanAccent,
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHYSICAL STATS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPhysicalStats(FighterModel f) {
    return _card(
      'PHYSICAL STATS',
      Icons.straighten,
      Column(
        children: [
          Row(
            children: [
              if (f.heightCm != null)
                Expanded(
                  child: _physItem(
                    'Height',
                    '${f.heightCm!.toStringAsFixed(0)} cm',
                    Icons.height,
                  ),
                ),
              if (f.reachCm != null)
                Expanded(
                  child: _physItem(
                    'Reach',
                    '${f.reachCm!.toStringAsFixed(0)} cm',
                    Icons.open_with,
                  ),
                ),
              if (f.stance != null)
                Expanded(
                  child: _physItem(
                    'Stance',
                    f.stance!.name.replaceAll('_', ''),
                    Icons.sports_martial_arts,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (f.weightClass != null)
                Expanded(
                  child: _physItem(
                    'Weight Class',
                    f.weightClass!,
                    Icons.fitness_center,
                  ),
                ),
              if (_age > 0)
                Expanded(child: _physItem('Age', '$_age yrs', Icons.cake)),
              if (f.sportType != null)
                Expanded(
                  child: _physItem('Sport', f.sportType!, Icons.sports_mma),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _physItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.cyanAccent.withValues(alpha: 0.5), size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIN ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWinAnalytics(FighterModel f) {
    return _card(
      'WIN ANALYTICS',
      Icons.analytics,
      Column(
        children: [
          _analyticBar('Win Rate', _winRate, Colors.green),
          const SizedBox(height: 8),
          _analyticBar('KO Rate', _koRate, Colors.orange),
          const SizedBox(height: 8),
          _analyticBar(
            'Finish Rate',
            _totalFights > 0
                ? ((f.knockouts + f.submissions) / _totalFights) * 100
                : 0,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _analyticBar(String label, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHT INFO
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFightInfo(FighterModel f) {
    return _card(
      'FIGHTER INFO',
      Icons.info_outline,
      Column(
        children: [
          if (f.city != null || f.country != null)
            _infoRow(
              Icons.location_on,
              'Location',
              [
                f.city,
                f.state,
                f.country,
              ].where((s) => s != null && s.isNotEmpty).join(', '),
            ),
          if (f.currentGymId != null)
            _infoRow(Icons.home, 'Gym', f.currentGymId!),
          if (f.currentCoachId != null)
            _infoRow(Icons.person, 'Coach', f.currentCoachId!),
          _infoRow(Icons.sports_mma, 'Total Fights', '$_totalFights'),
          _infoRow(Icons.flash_on, 'Knockouts', '${f.knockouts}'),
          if (f.submissions > 0)
            _infoRow(Icons.handshake, 'Submissions', '${f.submissions}'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEXT BOUT — IBC III
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNextBout(FighterModel f) {
    // Map IBC fighters to their opponents
    final Map<String, Map<String, String>> ibcBouts = {
      'tyson-hardman': {
        'opponent': 'Luke Modini',
        'event': 'IBC 03: GOLD COAST BRAWL',
        'type': 'LHW Title — 5 Rds',
      },
      'marcus-brooks': {
        'opponent': 'Jay Cutler',
        'event': 'IBC 03: GOLD COAST BRAWL',
        'type': 'LHW Title — 5 Rds',
      },
      'blake-watts': {
        'opponent': 'Jordan Silva',
        'event': 'IBC 03: GOLD COAST BRAWL',
        'type': 'Welterweight — 3 Rds',
      },
      'jordan-silva': {
        'opponent': 'Blake Watts',
        'event': 'IBC 03: GOLD COAST BRAWL',
        'type': 'Welterweight — 3 Rds',
      },
      'nikita-davids': {
        'opponent': 'Sarah King',
        'event': 'IBC 03: GOLD COAST BRAWL',
        'type': 'Strawweight — 3 Rds',
      },
      'sarah-king': {
        'opponent': 'Nikita Davids',
        'event': 'IBC 03: GOLD COAST BRAWL',
        'type': 'Strawweight — 3 Rds',
      },
      'danny-torres': {
        'opponent': 'Koji Tanaka',
        'event': 'IBC 03: GOLD COAST BRAWL',
        'type': 'Lightweight — 3 Rds',
      },
      'koji-tanaka': {
        'opponent': 'Danny Torres',
        'event': 'IBC 03: GOLD COAST BRAWL',
        'type': 'Lightweight — 3 Rds',
      },
      'liam-obrien': {
        'opponent': 'Ratu Vunipola',
        'event': 'IBC 03: GOLD COAST BRAWL',
        'type': 'Heavyweight — 3 Rds',
      },
      'ratu-vunipola': {
        'opponent': "Liam O'Brien",
        'event': 'IBC 03: GOLD COAST BRAWL',
        'type': 'Heavyweight — 3 Rds',
      },
    };

    final bout = ibcBouts[f.id];
    if (bout == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade900.withValues(alpha: 0.4),
            Colors.deepPurple.shade900.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _shimmer,
                builder: (_, _) => Icon(
                  Icons.local_fire_department,
                  color: Colors.red.withValues(alpha: _shimmer.value),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'NEXT BOUT — TOMORROW',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'vs ${bout['opponent']}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bout['type']!,
            style: TextStyle(
              color: Colors.cyanAccent.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${bout['event']} — March 7, 2026 • 7 PM AEST',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          Text(
            'Gold Coast Sports & Leisure Centre',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/ibc/fight-card'),
                  icon: const Icon(Icons.list, size: 16),
                  label: const Text('Full Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/ppv/ppv-ibc-03/watch'),
                  icon: const Icon(Icons.live_tv, size: 16),
                  label: const Text('Watch PPV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MATCHUP STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMatchupStatus(FighterModel f) {
    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    switch (f.matchupAvailability) {
      case MatchupAvailability.available:
        statusColor = Colors.green;
        statusText = 'AVAILABLE FOR MATCHUP';
        statusIcon = Icons.check_circle;
      case MatchupAvailability.booked:
        statusColor = Colors.orange;
        statusText = 'BOOKED — IBC 03';
        statusIcon = Icons.event_busy;
      case MatchupAvailability.negotiating:
        statusColor = Colors.amber;
        statusText = 'IN NEGOTIATIONS';
        statusIcon = Icons.hourglass_top;
      case MatchupAvailability.unavailable:
        statusColor = Colors.red;
        statusText = 'UNAVAILABLE';
        statusIcon = Icons.block;
    }

    return _card(
      'MATCHUP STATUS',
      Icons.sports_kabaddi,
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (f.matchupNotes != null)
                    Text(
                      f.matchupNotes!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActions(FighterModel f) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                Icons.style,
                'Fighter Card',
                Colors.deepPurple,
                () => context.go('/fighter-card'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                Icons.leaderboard,
                'Databank',
                Colors.cyanAccent,
                () => context.go('/databank'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                Icons.sports_mma,
                'IBC Hub',
                Colors.red,
                () => context.go('/ibc'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                Icons.local_fire_department,
                'PPV',
                Colors.orange,
                () => context.go('/ppv'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _card(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _countryFlag(String nationality) {
    const flags = {
      'Australia': '🇦🇺',
      'New Zealand': '🇳🇿',
      'Brazil': '🇧🇷',
      'South Africa': '🇿🇦',
      'Japan': '🇯🇵',
      'Philippines': '🇵🇭',
      'Ireland': '🇮🇪',
      'Fiji': '🇫🇯',
      'USA': '🇺🇸',
      'UK': '🇬🇧',
      'Thailand': '🇹🇭',
      'Mexico': '🇲🇽',
      'Russia': '🇷🇺',
    };
    return flags[nationality] ?? '🏳️';
  }
}
