import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DFC ROLE SELECTION — The first choice that shapes your entire DFC journey
// Futuristic holographic selector with animated 3-D glow cards
// ─────────────────────────────────────────────────────────────────────────────
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;
  int _selected = -1;

  static const _cyan = Color(0xFF00E5FF);
  static const _bg = Color(0xFF030810);

  final _roles = const [
    _DfcRole(
      '🥊',
      'FIGHTER',
      'The Heart of DFC',
      'Track fights, training, health, nutrition. Build your fight record. Connect with coaches & gyms. Get sponsored. Change your life.',
      [
        ' Fight Record',
        ' Training Planner',
        ' Health Monitor',
        ' Nutrition AI',
        ' Sponsorship',
      ],
      Color(0xFFFF1744),
      '/register',
    ),
    _DfcRole(
      '🏆',
      'PROMOTER',
      'Run Your Fight Show',
      'Create events, manage fight cards, sell tickets, pay fighters, market globally. DFC gives you the tools a world-class promoter needs.',
      [
        ' Event Builder',
        ' Fight Cards',
        ' Ticket Sales',
        ' Fighter Payments',
        ' Global Marketing',
      ],
      Color(0xFFFFAB00),
      '/register',
    ),
    _DfcRole(
      '🧠',
      'COACH / TRAINER',
      'Build Champions',
      'Manage camps, plan fighter development, track athlete health, run online coaching, build your brand and monetise your expertise.',
      [
        ' Camp Manager',
        ' Athlete Tracker',
        ' Online Coaching',
        ' AI Assistant',
        ' Revenue Tools',
      ],
      Color(0xFF00E676),
      '/register',
    ),
    _DfcRole(
      '🎟️',
      'FAN',
      'Live the Fight Life',
      'Follow fighters, buy tickets, vote on fights, collect fighter cards, bet on outcomes, watch live streams. Be part of the action.',
      [
        ' Live Events',
        ' Fighter Cards',
        ' Predictions',
        ' Community',
        ' Exclusive Access',
      ],
      Color(0xFF00E5FF),
      '/register',
    ),
    _DfcRole(
      '🏋️',
      'GYM OWNER',
      'Grow Your Gym',
      'List your gym on DFC, sell memberships, manage bookings, run classes, promote your fighters, attract sponsors worldwide.',
      [
        ' Gym Listing',
        ' Memberships',
        ' Class Booking',
        ' Fighter Profiles',
        ' Sponsor Connect',
      ],
      Color(0xFFD500F9),
      '/register',
    ),
    _DfcRole(
      '📱',
      'MEDIA / CREATOR',
      'Tell the Story',
      'Create fight content, build your audience, monetise through DFC. Video, articles, podcast, live coverage — all tools included.',
      [
        ' Content Studio',
        ' Audience Builder',
        ' Monetisation',
        ' Live Coverage',
        ' Brand Deals',
      ],
      Color(0xFFFF6D00),
      '/register',
    ),
    _DfcRole(
      '💼',
      'SPONSOR / BRAND',
      'Back the Best',
      'Sponsor fighters and events. Access fighter analytics. Run targeted campaigns to 1M+ fight fans globally. Measure every dollar.',
      [
        ' Fighter Sponsorship',
        ' Event Branding',
        ' Analytics',
        ' Targeted Ads',
        ' ROI Dashboard',
      ],
      Color(0xFF2979FF),
      '/register',
    ),
    _DfcRole(
      '🌍',
      'COMMUNITY BUILDER',
      'Repower Humanity',
      "Organise community events, run youth programs, connect with DFC's global network. Fight for a better planet, one person at a time.",
      [
        ' Youth Programs',
        ' Community Events',
        ' Global Network',
        ' Donations Hub',
        ' Education',
      ],
      Color(0xFFFF4081),
      '/register',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, _) => Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(_bgCtrl.value * 2 * math.pi) * 0.5,
                math.cos(_bgCtrl.value * 2 * math.pi) * 0.4,
              ),
              radius: 1.6,
              colors: const [
                Color(0xFF001A2E),
                Color(0xFF030810),
                Color(0xFF0A0010),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildHero(),
                Expanded(child: _buildGrid()),
                if (_selected >= 0) _buildConfirmBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/landing'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white54,
                size: 16,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'DFC',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: const Text(
              'SIGN IN',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) => Text(
              'WHO ARE YOU?',
              style: TextStyle(
                color: Color.lerp(Colors.white, _cyan, _pulseCtrl.value * 0.4),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your role shapes everything — your dashboard, tools, community and journey on DFC.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'You can always add more roles later.',
            style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: _roles.length,
      itemBuilder: (_, i) => _buildRoleCard(i),
    );
  }

  Widget _buildRoleCard(int i) {
    final r = _roles[i];
    final selected = _selected == i;
    return GestureDetector(
      onTap: () {
        setState(() => _selected = selected ? -1 : i);
        if (!selected) _showRoleDetail(i);
      },
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [
                      r.color.withValues(alpha: 0.22),
                      r.color.withValues(alpha: 0.08),
                    ]
                  : [
                      const Color(0xFF0A1428).withValues(alpha: 0.9),
                      const Color(0xFF060D1A),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? r.color.withValues(alpha: 0.7 + 0.3 * _pulseCtrl.value)
                  : r.color.withValues(alpha: 0.18),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: r.color.withValues(alpha: 0.25 * _pulseCtrl.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(r.emoji, style: const TextStyle(fontSize: 26)),
                    const Spacer(),
                    if (selected)
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: r.color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.title,
                  style: TextStyle(
                    color: r.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.tagline,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
                const SizedBox(height: 8),
                ...r.features
                    .take(3)
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 8,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: r.color.withValues(alpha: selected ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: r.color.withValues(alpha: selected ? 0.5 : 0.2),
                    ),
                  ),
                  child: Text(
                    selected ? 'SELECTED ✓' : 'SELECT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: r.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmBar() {
    final r = _roles[_selected];
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              r.color.withValues(alpha: 0.2),
              r.color.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: r.color.withValues(alpha: 0.5 + 0.2 * _pulseCtrl.value),
          ),
          boxShadow: [
            BoxShadow(color: r.color.withValues(alpha: 0.15), blurRadius: 16),
          ],
        ),
        child: Row(
          children: [
            Text(r.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JOINING AS ${r.title}',
                    style: TextStyle(
                      color: r.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    r.tagline,
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.go(r.route),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      r.color.withValues(alpha: 0.35),
                      r.color.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: r.color.withValues(alpha: 0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: r.color.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Text(
                  "LET'S GO →",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleDetail(int i) {
    final r = _roles[i];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A1428),
              r.color.withValues(alpha: 0.08),
              const Color(0xFF060D1A),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: r.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(r.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: TextStyle(
                        color: r.color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      r.tagline,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              r.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'WHAT YOU GET:',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: r.features
                  .map(
                    (f) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: r.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: r.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        f.trim(),
                        style: TextStyle(
                          color: r.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.go(r.route);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      r.color.withValues(alpha: 0.35),
                      r.color.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: r.color.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: r.color.withValues(alpha: 0.2),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Text(
                  'JOIN AS ${r.title} →',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DfcRole {
  final String emoji, title, tagline, description, route;
  final List<String> features;
  final Color color;
  const _DfcRole(
    this.emoji,
    this.title,
    this.tagline,
    this.description,
    this.features,
    this.color,
    this.route,
  );
}
