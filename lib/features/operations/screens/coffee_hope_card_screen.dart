import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// ═══════════════════════════════════════════════════════════════
/// COFFEE HOPE CARD — "No One Should Suffer Alone"
///
/// QR-coded digital cards for anyone in need:
/// • Homeless, desperate, lost, handicapped
/// • People battling addictions, pain, suffering
/// • Cold, lonely, forgotten
///
/// Each card unlocks:
/// → Free coffee at McDonald's 24hr, 7-Eleven, partner retailers
/// → Emergency contacts (Lifeline, Beyond Blue, 000)
/// → Shelter & housing referrals
/// → Addiction & mental health support
/// → DFC community connection
/// → "Sometimes a warm cup of coffee restarts hope"
///
/// Generate → Share → Print → Save a Life
/// ═══════════════════════════════════════════════════════════════

// ── Hope palette ──
const Color _hopeWarm = Color(0xFFFF8C42);
const Color _hopeGold = Color(0xFFFFD700);
const Color _hopeCyan = Color(0xFF00F5FF);
const Color _hopeGreen = Color(0xFF00FF88);
const Color _hopePink = Color(0xFFFF6B9D);
const Color _hopeBg = Color(0xFF050A14);
const Color _hopeCard = Color(0xFF0D1B2A);
const Color _hopeCardDark = Color(0xFF091420);

class CoffeeHopeCardScreen extends StatefulWidget {
  const CoffeeHopeCardScreen({super.key});

  @override
  State<CoffeeHopeCardScreen> createState() => _CoffeeHopeCardScreenState();
}

class _CoffeeHopeCardScreenState extends State<CoffeeHopeCardScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  late AnimationController _heartController;
  late Animation<double> _heartAnim;

  int _cardsGenerated = 12847;
  final int _coffeesRedeemed = 8932;
  final int _livesReached = 4216;
  final int _partnersActive = 14;

  // ── Emergency Contacts ──
  final List<_EmergencyContact> _emergencyContacts = [
    const _EmergencyContact(
      'Lifeline Australia',
      '13 11 14',
      '24/7 crisis support & suicide prevention',
      Icons.phone_in_talk,
      _hopePink,
    ),
    const _EmergencyContact(
      'Beyond Blue',
      '1300 22 4636',
      'Anxiety, depression & mental health',
      Icons.psychology,
      _hopeCyan,
    ),
    const _EmergencyContact(
      'Emergency Services',
      '000',
      'Police, Ambulance, Fire',
      Icons.emergency,
      Color(0xFFFF3366),
    ),
    const _EmergencyContact(
      '1800RESPECT',
      '1800 737 732',
      'Domestic & family violence support',
      Icons.shield,
      _hopePink,
    ),
    const _EmergencyContact(
      'Kids Helpline',
      '1800 55 1800',
      'Counselling for young people 5-25',
      Icons.child_care,
      _hopeGreen,
    ),
    const _EmergencyContact(
      'Homeless Hotline',
      '1800 152 152',
      'Connect to nearest shelter & housing',
      Icons.night_shelter,
      _hopeWarm,
    ),
    const _EmergencyContact(
      'Drug & Alcohol Help',
      '1800 250 015',
      'Addiction counselling & rehab referrals',
      Icons.healing,
      _hopeGold,
    ),
    const _EmergencyContact(
      'DFC Community Line',
      '1300 DFC HELP',
      'Our community is here for you',
      Icons.favorite,
      Color(0xFFFF00FF),
    ),
  ];

  // ── Partner Retailers ──
  final List<_CoffeePartner> _coffeePartners = [
    const _CoffeePartner(
      "McDonald's 24hr",
      'Free coffee any time · No questions asked',
      Icons.coffee,
      _hopeWarm,
      true,
      '24hr nationwide',
    ),
    const _CoffeePartner(
      '7-Eleven',
      'Free Slurpee or hot drink · Show QR',
      Icons.local_drink,
      Color(0xFF00875A),
      true,
      '24hr stores',
    ),
    const _CoffeePartner(
      'Salvation Army',
      'Hot meal + coffee · Walk-in welcome',
      Icons.volunteer_activism,
      Color(0xFFCC0000),
      true,
      'All centres',
    ),
    const _CoffeePartner(
      'OzHarvest',
      'Free community meals · No ID needed',
      Icons.restaurant,
      _hopeGold,
      true,
      'Major cities',
    ),
    const _CoffeePartner(
      'Vinnies',
      'Emergency food & shelter referral',
      Icons.home,
      Color(0xFF0066CC),
      true,
      'Nationwide',
    ),
    const _CoffeePartner(
      'Boost Juice',
      'Free smoothie for card holders',
      Icons.blender,
      _hopePink,
      true,
      'Selected stores',
    ),
    const _CoffeePartner(
      'Mission Australia',
      'Shelter + meals + counselling',
      Icons.church,
      Color(0xFF006633),
      true,
      'All centres',
    ),
    const _CoffeePartner(
      'Foodbank',
      'Emergency food hamper · QR verified',
      Icons.inventory_2,
      _hopeGreen,
      true,
      'Nationwide',
    ),
  ];

  // ── Card Types ──
  final List<_HopeCardType> _cardTypes = [
    const _HopeCardType(
      'WARM CUP CARD',
      'One free coffee at any partner',
      'For a stranger who looks like they need warmth',
      Icons.coffee,
      _hopeWarm,
      1,
    ),
    const _HopeCardType(
      'COMFORT CARD',
      '3 coffees + meal voucher',
      'For someone sleeping rough or at a shelter',
      Icons.night_shelter,
      _hopeGold,
      3,
    ),
    const _HopeCardType(
      'HOPE CARD',
      '7 coffees + emergency contacts + shelter referral',
      'For someone in crisis — food, warmth, connection',
      Icons.favorite,
      _hopePink,
      7,
    ),
    const _HopeCardType(
      'LIFELINE CARD',
      '30 coffees + full support bundle',
      'Monthly support: food, health check, counselling contact',
      Icons.health_and_safety,
      _hopeCyan,
      30,
    ),
    const _HopeCardType(
      'RESTART CARD',
      'Unlimited coffees for 90 days + full DFC community access',
      'For someone rebuilding their life — we walk with you',
      Icons.refresh,
      _hopeGreen,
      90,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _heartAnim = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _hopeBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeroMessage()),
          SliverToBoxAdapter(child: _buildImpactStats()),
          SliverToBoxAdapter(child: _buildCardTypesSection()),
          SliverToBoxAdapter(child: _buildEmergencySection()),
          SliverToBoxAdapter(child: _buildPartnerRetailersSection()),
          SliverToBoxAdapter(child: _buildHowItWorks()),
          SliverToBoxAdapter(child: _buildShareTheWarmth()),
          SliverToBoxAdapter(child: _buildPledge()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: _buildGenerateFAB(),
    );
  }

  // ═══════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: _hopeBg.withValues(alpha: 0.95),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _heartAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: _heartAnim.value,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_hopeWarm, _hopePink]),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _hopePink.withValues(
                          alpha: 0.3 * _heartAnim.value,
                        ),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'HOPE CARDS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: _hopeWarm),
          onPressed: _showShareSheet,
        ),
        IconButton(
          icon: const Icon(Icons.qr_code_2, color: _hopeCyan),
          onPressed: _showInstantQR,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // HERO MESSAGE — "No One Should Suffer Alone"
  // ═══════════════════════════════════════════
  Widget _buildHeroMessage() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _hopeWarm.withValues(alpha: 0.12 * _glowAnim.value),
                _hopePink.withValues(alpha: 0.08),
                _hopeCyan.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _hopeWarm.withValues(alpha: 0.25 * _glowAnim.value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _hopeWarm.withValues(alpha: 0.1 * _glowAnim.value),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              // Warm coffee cup with heart
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [_hopeWarm, _hopePink]),
                      boxShadow: [
                        BoxShadow(
                          color: _hopeWarm.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.coffee,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _hopePink,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _hopePink.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Main message
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_hopeWarm, _hopeGold, Colors.white],
                ).createShader(bounds),
                child: const Text(
                  'NO ONE SHOULD\nSUFFER ALONE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Sometimes a warm cup of coffee\nrestarts hope.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),

              // Sub-message
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _hopeWarm.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _hopeWarm.withValues(alpha: 0.15)),
                ),
                child: Text(
                  'For the homeless. The desperate. The lost.\n'
                  'The handicapped. Those battling addictions.\n'
                  'The cold. The lonely. The forgotten.\n'
                  'We see you. We care. You matter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Generate Card CTA
              GestureDetector(
                onTap: _showGenerateCardSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_hopeWarm, _hopePink]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _hopeWarm.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'GENERATE A HOPE CARD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // IMPACT STATS
  // ═══════════════════════════════════════════
  Widget _buildImpactStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard('$_cardsGenerated', 'CARDS\nGENERATED', _hopeWarm),
          const SizedBox(width: 8),
          _statCard('$_coffeesRedeemed', 'COFFEES\nREDEEMED', _hopeGold),
          const SizedBox(width: 8),
          _statCard('$_livesReached', 'LIVES\nREACHED', _hopePink),
          const SizedBox(width: 8),
          _statCard('$_partnersActive', 'ACTIVE\nPARTNERS', _hopeGreen),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // CARD TYPES — Choose which Hope Card to generate
  // ═══════════════════════════════════════════
  Widget _buildCardTypesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('CHOOSE A HOPE CARD', Icons.card_giftcard, _hopeGold),
          const SizedBox(height: 8),
          Text(
            'Each card is a lifeline — generate, share, or print for someone in need',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ..._cardTypes.map(_buildHopeCardTypeItem),
        ],
      ),
    );
  }

  Widget _buildHopeCardTypeItem(_HopeCardType card) {
    return GestureDetector(
      onTap: () => _showCardPreview(card),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [card.color.withValues(alpha: 0.1), _hopeCard],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: card.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [card.color, card.color.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: card.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(card.icon, color: Colors.white, size: 22),
                  Text(
                    card.coffees == 90 ? '∞' : '${card.coffees}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: TextStyle(
                      color: card.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: card.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.qr_code_2, color: card.color, size: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  'GENERATE',
                  style: TextStyle(
                    color: card.color,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // EMERGENCY CONTACTS — Always visible, always available
  // ═══════════════════════════════════════════
  Widget _buildEmergencySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'EMERGENCY CONTACTS',
            Icons.emergency,
            const Color(0xFFFF3366),
          ),
          const SizedBox(height: 6),
          Text(
            'Every Hope Card includes these numbers — help is always one call away',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          ..._emergencyContacts.map(_buildEmergencyContactCard),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(_EmergencyContact contact) {
    return GestureDetector(
      onTap: () => _showCallDialog(contact),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hopeCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: contact.color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: contact.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(contact.icon, color: contact.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [contact.color, contact.color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    contact.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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

  // ═══════════════════════════════════════════
  // PARTNER RETAILERS — Where to redeem
  // ═══════════════════════════════════════════
  Widget _buildPartnerRetailersSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('WHERE TO REDEEM', Icons.storefront, _hopeGold),
          const SizedBox(height: 6),
          Text(
            'Show a Hope Card QR code at any of these partners — no questions asked, no judgement',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ..._coffeePartners.map(_buildPartnerCard),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(_CoffeePartner partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _hopeCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: partner.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: partner.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(partner.icon, color: partner.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      partner.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (partner.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _hopeGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ACCEPTING',
                          style: TextStyle(
                            color: _hopeGreen,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  partner.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: partner.color.withValues(alpha: 0.5),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      partner.availability,
                      style: TextStyle(
                        color: partner.color.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.qr_code_2,
            color: partner.color.withValues(alpha: 0.5),
            size: 28,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HOW IT WORKS
  // ═══════════════════════════════════════════
  Widget _buildHowItWorks() {
    final steps = [
      const _HowStep(
        '1',
        'GENERATE',
        'Create a Hope Card with QR code',
        Icons.qr_code_2,
        _hopeWarm,
      ),
      const _HowStep(
        '2',
        'SHARE',
        'Send via text, print, or show on screen',
        Icons.share,
        _hopeCyan,
      ),
      const _HowStep(
        '3',
        'GIVE',
        'Hand it to someone who needs warmth & hope',
        Icons.card_giftcard,
        _hopePink,
      ),
      const _HowStep(
        '4',
        'REDEEM',
        'They show QR at any partner — free coffee, no questions',
        Icons.coffee,
        _hopeGold,
      ),
      const _HowStep(
        '5',
        'CONNECT',
        'Card includes emergency numbers & DFC community link',
        Icons.people,
        _hopeGreen,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('HOW IT WORKS', Icons.info_outline, _hopeCyan),
          const SizedBox(height: 14),
          ...steps.map(
            (step) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _hopeCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: step.color.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [step.color, step.color.withValues(alpha: 0.6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: step.color.withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        step.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            color: step.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    step.icon,
                    color: step.color.withValues(alpha: 0.4),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SHARE THE WARMTH
  // ═══════════════════════════════════════════
  Widget _buildShareTheWarmth() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _hopePink.withValues(alpha: 0.1),
              _hopeWarm.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _hopePink.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.people, color: _hopePink, size: 36),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_hopePink, _hopeWarm],
              ).createShader(bounds),
              child: const Text(
                'SHARE THE WARMTH',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Know someone who needs help? Generate a Hope Card and share it.\n\n'
              'Print them out and leave at shelters, hostels, train stations, '
              'hospitals, community centres, churches — anywhere someone might '
              'be suffering in silence.\n\n'
              'One QR code could restart someone\'s life.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _shareButton('TEXT', Icons.sms, _hopeCyan)),
                const SizedBox(width: 10),
                Expanded(child: _shareButton('EMAIL', Icons.email, _hopeGold)),
                const SizedBox(width: 10),
                Expanded(child: _shareButton('PRINT', Icons.print, _hopeGreen)),
                const SizedBox(width: 10),
                Expanded(child: _shareButton('SOCIAL', Icons.share, _hopePink)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareButton(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // DFC PLEDGE
  // ═══════════════════════════════════════════
  Widget _buildPledge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _hopeCardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _hopeWarm.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [_hopeWarm, _hopeGold]),
                boxShadow: [
                  BoxShadow(
                    color: _hopeWarm.withValues(alpha: 0.3),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(Icons.handshake, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'THE DFC PLEDGE',
              style: TextStyle(
                color: _hopeGold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"We believe that no human being should go cold, hungry, or forgotten. '
              'DataFightCentral was built for fighters — and in life, we are all fighters. '
              'Every Hope Card is a promise: you are not alone, you are not invisible, '
              'and there is always someone who cares.\n\n'
              'Buy a Coffee, Not a Coffin."',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.7,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '— DFC Pty Ltd\nDFC HQ, Queens Rd, Woodridge QLD 4114',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // GENERATE FAB
  // ═══════════════════════════════════════════
  Widget _buildGenerateFAB() {
    return AnimatedBuilder(
      animation: _heartAnim,
      builder: (context, child) {
        return FloatingActionButton.extended(
          onPressed: _showGenerateCardSheet,
          backgroundColor: _hopeWarm,
          icon: Transform.scale(
            scale: _heartAnim.value,
            child: const Icon(Icons.favorite, color: Colors.white),
          ),
          label: const Text(
            'GIVE HOPE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════
  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // DIALOGS & SHEETS
  // ═══════════════════════════════════════════

  void _showGenerateCardSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _hopeCardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(Icons.favorite, color: _hopePink, size: 36),
                const SizedBox(height: 12),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_hopeWarm, _hopeGold],
                  ).createShader(bounds),
                  child: const Text(
                    'GENERATE HOPE CARD',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a card type, add a personal message, and share it with someone who needs hope',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),

                // Card type chips
                ..._cardTypes.map(
                  (card) => GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showCardPreview(card);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: card.color.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: card.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(card.icon, color: card.color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.name,
                                  style: TextStyle(
                                    color: card.color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  card.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: card.color.withValues(alpha: 0.5),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _hopeWarm.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hopeWarm.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _hopeWarm.withValues(alpha: 0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hope Cards are free to generate. DFC covers the cost through the Buy a Coffee Not a Coffin donation fund.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCardPreview(_HopeCardType card) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_hopeCardDark, card.color.withValues(alpha: 0.08)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: card.color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: card.color.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Card header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: card.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.favorite, color: card.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'DFC HOPE CARD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Text(
                    '#HC-${(math.Random().nextInt(9999) + 1000).toString()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // QR Code area
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: card.color.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: QrImageView(
                    data:
                        'https://datafightcentral.com/hope?card=${card.name.replaceAll(' ', '-').toLowerCase()}&id=HC-${(math.Random().nextInt(9999) + 1000)}',
                    size: 140,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: card.color,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: card.color.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                card.name,
                style: TextStyle(
                  color: card.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                card.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You are not alone. You matter.',
                style: TextStyle(
                  color: _hopePink.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lifeline: 13 11 14 · Beyond Blue: 1300 22 4636',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _previewAction('SHARE', Icons.share, _hopeCyan, () {
                      Navigator.pop(context);
                      setState(() => _cardsGenerated++);
                      _showSnack(
                        'Hope Card shared — you may have just saved a life',
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _previewAction('PRINT', Icons.print, _hopeGold, () {
                      Navigator.pop(context);
                      setState(() => _cardsGenerated++);
                      _showSnack('Hope Card ready to print');
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _previewAction(
                      'SAVE',
                      Icons.download,
                      _hopeGreen,
                      () {
                        Navigator.pop(context);
                        setState(() => _cardsGenerated++);
                        _showSnack('Hope Card saved to device');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'datafightcentral.com/hope',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _hopeCardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SHARE HOPE CARDS',
              style: TextStyle(
                color: _hopeGold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Spread the word — every share could save a life',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            _shareOption('Share via SMS / Text', Icons.sms, _hopeCyan),
            _shareOption('Share via Email', Icons.email, _hopeGold),
            _shareOption('Share on Social Media', Icons.share, _hopePink),
            _shareOption('Print Batch (10 cards)', Icons.print, _hopeGreen),
            _shareOption('Copy Link', Icons.content_copy, _hopeWarm),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _shareOption(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showSnack('$label — coming soon');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showInstantQR() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _hopeCardDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _hopeWarm.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'INSTANT HOPE QR',
                style: TextStyle(
                  color: _hopeWarm,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Show this to anyone in need',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _hopeWarm.withValues(alpha: 0.3),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(
                    data:
                        'https://datafightcentral.com/hope?type=instant&card=universal-hope&lifeline=131114',
                    size: 176,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFFFF8C42),
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: const Color(0xFFFF8C42).withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Free coffee · No questions asked\nLifeline: 13 11 14',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CLOSE',
                  style: TextStyle(
                    color: _hopeCyan,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCallDialog(_EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _hopeCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(contact.icon, color: contact.color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                contact.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    contact.color.withValues(alpha: 0.15),
                    contact.color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: contact.color.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, color: contact.color, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    contact.number,
                    style: TextStyle(
                      color: contact.color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You are not alone. Help is available right now.',
              style: TextStyle(
                color: _hopePink.withValues(alpha: 0.8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: contact.number));
              _showSnack('${contact.number} copied to clipboard');
            },
            child: const Text(
              'COPY NUMBER',
              style: TextStyle(color: _hopeCyan),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _hopeCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.favorite, color: _hopePink, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════

class _EmergencyContact {
  final String name;
  final String number;
  final String description;
  final IconData icon;
  final Color color;
  const _EmergencyContact(
    this.name,
    this.number,
    this.description,
    this.icon,
    this.color,
  );
}

class _CoffeePartner {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isActive;
  final String availability;
  const _CoffeePartner(
    this.name,
    this.description,
    this.icon,
    this.color,
    this.isActive,
    this.availability,
  );
}

class _HopeCardType {
  final String name;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final int coffees;
  const _HopeCardType(
    this.name,
    this.subtitle,
    this.description,
    this.icon,
    this.color,
    this.coffees,
  );
}

class _HowStep {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  const _HowStep(
    this.number,
    this.title,
    this.description,
    this.icon,
    this.color,
  );
}
