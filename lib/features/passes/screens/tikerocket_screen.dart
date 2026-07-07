import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/tikerocket_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TIKEROCKET — DFC Digital Ticketing & FightCoin Wallet
// Real combat sports event tickets. Peer-to-peer transfers. Instant QR entry.
// ═══════════════════════════════════════════════════════════════════════════════

class TikeRocketScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const TikeRocketScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<TikeRocketScreen> createState() => _TikeRocketScreenState();
}

class _TikeRocketScreenState extends State<TikeRocketScreen>
    with TickerProviderStateMixin {
  late TabController _tabs;
  late AnimationController _coinPulse;
  late Animation<double> _coinAnim;

  static const _bg = Color(0xFF050A14);
  static const _panel = Color(0xFF0A1628);
  static const _surface = Color(0xFF131F38);
  static const _gold = Color(0xFFFFD600);
  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _red = Color(0xFFFF1744);
  static const _purple = Color(0xFF9C6FFF);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _coinPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _coinAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _coinPulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _coinPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildWalletCard(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildMyTickets(),
                  _buildBuyTickets(),
                  _buildResaleMarket(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    decoration: BoxDecoration(
      color: _panel,
      border: Border(bottom: BorderSide(color: _gold.withValues(alpha: 0.15))),
    ),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white54,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        // TikeRocket logo mark
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD600), Color(0xFFFF6D00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('🚀', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TIKEROCKET',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            Text(
              'DFC Digital Ticketing',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
        const Spacer(),
        _fcBadge('LIVE'),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showSendCoinsSheet(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _gold.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⚡', style: TextStyle(fontSize: 12)),
                SizedBox(width: 4),
                Text(
                  'SEND',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 11,
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

  Widget _fcBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _green.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: _green.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _green,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    ),
  );

  // ── Wallet Card ─────────────────────────────────────────────────────────────
  Widget _buildWalletCard() => AnimatedBuilder(
    animation: _coinAnim,
    builder: (_, __) => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1000).withValues(alpha: _coinAnim.value),
            const Color(0xFF0A1628),
            const Color(0xFF1A0A00).withValues(alpha: _coinAnim.value),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withValues(alpha: 0.3 * _coinAnim.value),
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.08 * _coinAnim.value),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: StreamBuilder<FightCoinLedger>(
        stream: TikeRocketService().watchWallet(widget.userId),
        builder: (context, snap) {
          final balance = snap.data?.balance ?? 0;
          return Row(
            children: [
              // Coin icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFD600), Color(0xFFFF8C00)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⚡', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DFC FIGHT COINS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${balance.toStringAsFixed(2)} FC',
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Digital combat sports currency',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _walletAction(
                    'BUY FC',
                    _cyan,
                    Icons.add_circle_outline,
                    () {},
                  ),
                  const SizedBox(height: 8),
                  _walletAction(
                    'HISTORY',
                    Colors.white38,
                    Icons.receipt_long,
                    () => _showHistory(snap.data),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _walletAction(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );

  // ── Tab Bar ─────────────────────────────────────────────────────────────────
  Widget _buildTabBar() => Container(
    color: _panel,
    child: TabBar(
      controller: _tabs,
      indicatorColor: _gold,
      labelColor: _gold,
      unselectedLabelColor: Colors.white38,
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
      tabs: const [
        Tab(
          icon: Icon(Icons.confirmation_number, size: 16),
          text: 'MY TICKETS',
        ),
        Tab(icon: Icon(Icons.local_activity, size: 16), text: 'BUY TICKETS'),
        Tab(icon: Icon(Icons.storefront, size: 16), text: 'RESALE'),
      ],
    ),
  );

  // ── TAB 1: My Tickets ───────────────────────────────────────────────────────
  Widget _buildMyTickets() => StreamBuilder<List<DfcTicket>>(
    stream: TikeRocketService().watchMyTickets(widget.userId),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: _gold));
      }
      final tickets = snap.data ?? [];
      if (tickets.isEmpty) {
        return _emptyState(
          '🎟️',
          'No tickets yet',
          'Buy tickets to upcoming DFC events below.',
          _gold,
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (_, i) => _ticketCard(tickets[i]),
      );
    },
  );

  Widget _ticketCard(DfcTicket ticket) {
    final statusColor = switch (ticket.status) {
      TicketStatus.active => _green,
      TicketStatus.used => Colors.white38,
      TicketStatus.transferred => _cyan,
      TicketStatus.cancelled => _red,
      TicketStatus.resale => _gold,
    };
    final statusLabel = switch (ticket.status) {
      TicketStatus.active => 'READY TO SCAN',
      TicketStatus.used => 'ENTRY COMPLETE',
      TicketStatus.transferred => 'TRANSFERRED',
      TicketStatus.cancelled => 'CANCELLED',
      TicketStatus.resale => 'LISTED FOR RESALE',
    };
    final typeColor = switch (ticket.type) {
      TicketType.vip => _gold,
      TicketType.ringside => _red,
      TicketType.ppv => _purple,
      _ => _cyan,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Event header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_surface, _bg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Text('🥊', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.eventTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(ticket.eventDate),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: typeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    ticket.type.name.toUpperCase(),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.06),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                if (ticket.seat != null)
                  Text(
                    'SEAT ${ticket.seat}',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
              ],
            ),
          ),

          // QR + actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // QR code
                if (ticket.status == TicketStatus.active)
                  GestureDetector(
                    onTap: () => _showQrFullscreen(ticket),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: QrImageView(
                        data: ticket.qrCode,
                        version: QrVersions.auto,
                        size: 80,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.qr_code_2,
                        color: Colors.white24,
                        size: 48,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ticketInfoRow(
                        'Paid',
                        '\$${ticket.pricePaid.toStringAsFixed(2)} AUD',
                      ),
                      if (ticket.fightCoinsSpent > 0)
                        _ticketInfoRow(
                          'FC used',
                          '${ticket.fightCoinsSpent.toStringAsFixed(0)} ⚡',
                        ),
                      const SizedBox(height: 12),
                      if (ticket.status == TicketStatus.active) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _actionBtn(
                                'TRANSFER',
                                _cyan,
                                Icons.send,
                                () => _showTransferSheet(ticket),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _actionBtn(
                                'RESALE',
                                _gold,
                                Icons.storefront,
                                () => _showResaleSheet(ticket),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (ticket.status == TicketStatus.active)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: _actionBtn(
                              'TAP QR TO ENTER',
                              _green,
                              Icons.qr_code_scanner,
                              () => _showQrFullscreen(ticket),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _actionBtn(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ),
  );

  // ── TAB 2: Buy Tickets ──────────────────────────────────────────────────────
  Widget _buildBuyTickets() {
    // Real DFC combat sports events
    const events = [
      _EventListing(
        id: 'dfc_ibc3_2026',
        title: 'IBC3 WORLD CHAMPIONSHIP NIGHT',
        subtitle: 'Makhachev vs Volkanovski III',
        venue: 'Qudos Bank Arena, Sydney',
        date: 'Saturday 19 July 2026 · 7:00 PM AEST',
        sport: 'MMA',
        promotion: 'IBC',
        flag: '🇦🇺',
        tiers: [
          _TicketTier(
            'General Admission',
            49,
            TicketType.general,
            Colors.white70,
          ),
          _TicketTier('VIP Ringside', 199, TicketType.vip, _gold),
          _TicketTier('PPV Digital Stream', 29, TicketType.ppv, _purple),
        ],
        fcBonus: 50,
      ),
      _EventListing(
        id: 'dfc_brawl_2026',
        title: 'DFC BRAWL STARS NIGHT 7',
        subtitle: 'Super Fight Cards · 8 Bouts',
        venue: 'Entertainment Quarter, Melbourne',
        date: 'Friday 1 Aug 2026 · 6:30 PM AEST',
        sport: 'Kickboxing',
        promotion: 'DFC',
        flag: '🇦🇺',
        tiers: [
          _TicketTier(
            'General Admission',
            35,
            TicketType.general,
            Colors.white70,
          ),
          _TicketTier('Floor Access', 89, TicketType.vip, _cyan),
          _TicketTier('PPV Digital Stream', 19, TicketType.ppv, _purple),
        ],
        fcBonus: 25,
      ),
      _EventListing(
        id: 'dfc_one_2026',
        title: 'ONE CHAMPIONSHIP × DFC',
        subtitle: 'Super Series · 3 World Title Fights',
        venue: 'Singapore Indoor Stadium',
        date: 'Saturday 23 Aug 2026 · 8:00 PM SGT',
        sport: 'MMA / Muay Thai',
        promotion: 'ONE',
        flag: '🇸🇬',
        tiers: [
          _TicketTier(
            'General Admission',
            75,
            TicketType.general,
            Colors.white70,
          ),
          _TicketTier('Ringside VIP', 320, TicketType.ringside, _red),
          _TicketTier('PPV Digital Stream', 39, TicketType.ppv, _purple),
        ],
        fcBonus: 80,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (_, i) => _eventListing(events[i]),
    );
  }

  Widget _eventListing(_EventListing e) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _cyan.withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_surface, _bg],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Row(
            children: [
              Text(e.flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      e.subtitle,
                      style: TextStyle(
                        color: _cyan.withValues(alpha: 0.7),
                        fontSize: 11,
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
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      e.sport,
                      style: const TextStyle(
                        color: _red,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.promotion,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white38,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    e.venue,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white38,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    e.date,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '⚡ Earn ${e.fcBonus} DFC Fight Coins with purchase',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tier buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          child: Column(
            children: e.tiers
                .map(
                  (tier) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _showPurchaseSheet(e, tier),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: tier.color.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: tier.color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tier.type == TicketType.ppv
                                  ? Icons.live_tv
                                  : tier.type == TicketType.vip
                                  ? Icons.star
                                  : Icons.confirmation_number,
                              color: tier.color,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tier.name,
                                style: TextStyle(
                                  color: tier.color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '\$${tier.priceAud} AUD',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: tier.color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'BUY',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );

  // ── TAB 3: Resale Market ────────────────────────────────────────────────────
  Widget _buildResaleMarket() => StreamBuilder<List<DfcTicket>>(
    stream: TikeRocketService().watchResaleMarket(),
    builder: (context, snap) {
      final tickets = snap.data ?? [];
      if (tickets.isEmpty) {
        return _emptyState(
          '🏷️',
          'No resale listings',
          'Check back closer to events for fan-listed tickets.',
          _gold,
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (_, i) => _resaleCard(tickets[i]),
      );
    },
  );

  Widget _resaleCard(DfcTicket t) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _gold.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        const Text('🎟️', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.eventTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${t.type.name.toUpperCase()} · ${_formatDate(t.eventDate)}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${t.resalePrice?.toStringAsFixed(2) ?? '--'} AUD',
              style: const TextStyle(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _confirmBuyResale(t),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'BUY NOW',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // ── Sheets ──────────────────────────────────────────────────────────────────
  void _showQrFullscreen(DfcTicket ticket) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ticket.eventTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(ticket.eventDate),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: ticket.qrCode,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SHOW TO GATE STAFF TO ENTER',
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.type.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransferSheet(DfcTicket ticket) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: _panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TRANSFER TICKET',
              style: TextStyle(
                color: _cyan,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.eventTitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter recipient User ID or @handle',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _cyan),
                ),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Colors.white38,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await TikeRocketService().transferTicket(
                    ticketId: ticket.id,
                    fromUserId: widget.userId,
                    toUserId: ctrl.text.trim(),
                    toUserName: ctrl.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? '✅ Ticket transferred!'
                              : '❌ Transfer failed',
                        ),
                        backgroundColor: success ? _green : _red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CONFIRM TRANSFER',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResaleSheet(DfcTicket ticket) {
    double price = ticket.pricePaid * 1.1;
    showModalBottomSheet(
      context: context,
      backgroundColor: _panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIST FOR RESALE',
                style: TextStyle(
                  color: _gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticket.eventTitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Text(
                'Resale price: \$${price.toStringAsFixed(2)} AUD',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Slider(
                value: price,
                min: ticket.pricePaid * 0.5,
                max: ticket.pricePaid * 3.0,
                activeColor: _gold,
                inactiveColor: Colors.white12,
                onChanged: (v) => setSt(() => price = v),
              ),
              const SizedBox(height: 8),
              const Text(
                'DFC takes 10% platform fee. You receive the rest.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await TikeRocketService().listForResale(
                      ticketId: ticket.id,
                      userId: widget.userId,
                      resalePrice: price,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? '✅ Listed for resale at \$${price.toStringAsFixed(2)}!'
                                : '❌ Failed to list',
                          ),
                          backgroundColor: success ? _green : _red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'LIST ON RESALE MARKET',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPurchaseSheet(_EventListing event, _TicketTier tier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BUY TICKET',
              style: TextStyle(
                color: tier.color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(tier.name, style: TextStyle(color: tier.color, fontSize: 12)),
            const SizedBox(height: 20),
            _purchaseRow('Price', '\$${tier.priceAud}.00 AUD'),
            _purchaseRow('FC Bonus', '+${event.fcBonus} ⚡ Fight Coins'),
            _purchaseRow('Event', event.date),
            _purchaseRow('Venue', event.venue),
            const Divider(color: Colors.white12, height: 24),
            _purchaseRow('Total', '\$${tier.priceAud}.00 AUD', bold: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  HapticFeedback.mediumImpact();
                  final ticket = await TikeRocketService().purchaseTicket(
                    userId: widget.userId,
                    userName: widget.userName,
                    eventId: event.id,
                    eventTitle: event.title,
                    eventDate: DateTime.now().add(const Duration(days: 14)),
                    type: tier.type,
                    priceAud: tier.priceAud.toDouble(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ticket != null
                              ? '✅ Ticket purchased! +${event.fcBonus} ⚡ FC earned!'
                              : '❌ Purchase failed. Try again.',
                        ),
                        backgroundColor: ticket != null ? _green : _red,
                      ),
                    );
                    if (ticket != null) _tabs.animateTo(0);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tier.color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CONFIRM & PAY',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _purchaseRow(String label, String value, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  void _showSendCoinsSheet() {
    final ctrl = TextEditingController();
    double amount = 10;
    showModalBottomSheet(
      context: context,
      backgroundColor: _panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SEND FIGHT COINS ⚡',
                style: TextStyle(
                  color: _gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Recipient User ID or @handle',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _gold),
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Colors.white38,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Amount: ${amount.toStringAsFixed(0)} ⚡ FC',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Slider(
                value: amount,
                min: 1,
                max: 500,
                activeColor: _gold,
                inactiveColor: Colors.white12,
                onChanged: (v) => setSt(() => amount = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await TikeRocketService()
                        .transferFightCoins(
                          fromUserId: widget.userId,
                          toUserId: ctrl.text.trim(),
                          amount: amount,
                          description: 'FC sent via TikeRocket',
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? '✅ ${amount.toStringAsFixed(0)} FC sent!'
                                : '❌ Transfer failed',
                          ),
                          backgroundColor: success ? _green : _red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SEND FIGHT COINS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory(FightCoinLedger? ledger) {
    final txs = ledger?.recentTxs ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TRANSACTION HISTORY',
              style: TextStyle(
                color: _gold,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            if (txs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              )
            else
              ...txs
                  .take(10)
                  .map(
                    (tx) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: tx.amount > 0
                                  ? _green.withValues(alpha: 0.1)
                                  : _red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              tx.type == 'transfer'
                                  ? Icons.send
                                  : tx.type == 'purchase'
                                  ? Icons.local_activity
                                  : Icons.receipt_long,
                              size: 14,
                              color: tx.amount > 0 ? _green : _red,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.description,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDate(tx.createdAt),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${tx.amount > 0 ? '+' : ''}${tx.amount.toStringAsFixed(0)} ⚡',
                            style: TextStyle(
                              color: tx.amount >= 0 ? _green : _red,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _confirmBuyResale(DfcTicket ticket) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Buy Resale Ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          '${ticket.eventTitle}\n${ticket.type.name.toUpperCase()}\n\n'
          'Price: \$${ticket.resalePrice?.toStringAsFixed(2) ?? '--'} AUD',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await TikeRocketService().buyResaleTicket(
                ticketId: ticket.id,
                buyerId: widget.userId,
                buyerName: widget.userName,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? '✅ Ticket purchased!' : '❌ Purchase failed',
                    ),
                    backgroundColor: success ? _green : _red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'CONFIRM',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String emoji, String title, String sub, Color color) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );

  String _formatDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

// ─── Data Models (view-only) ──────────────────────────────────────────────────

class _EventListing {
  final String id;
  final String title;
  final String subtitle;
  final String venue;
  final String date;
  final String sport;
  final String promotion;
  final String flag;
  final List<_TicketTier> tiers;
  final int fcBonus;
  const _EventListing({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.venue,
    required this.date,
    required this.sport,
    required this.promotion,
    required this.flag,
    required this.tiers,
    required this.fcBonus,
  });
}

class _TicketTier {
  final String name;
  final int priceAud;
  final TicketType type;
  final Color color;
  const _TicketTier(this.name, this.priceAud, this.type, this.color);
}
