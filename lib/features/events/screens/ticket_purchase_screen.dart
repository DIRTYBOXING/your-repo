import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/router_config.dart' as app_router;
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/stripe_config.dart';
import '../../../shared/services/paypal_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// TICKET PURCHASE SCREEN — Event ticket checkout flow
/// Tier selection → quantity → payment summary → confirm
class TicketPurchaseScreen extends StatefulWidget {
  final String eventId;
  const TicketPurchaseScreen({super.key, required this.eventId});

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _selectedTier = 0;
  int _quantity = 1;
  bool _isProcessing = false;
  bool _purchaseComplete = false;
  String _paymentMethod = 'stripe'; // stripe or paypal

  // Event + ticket data — will be replaced with Firestore reads
  late Map<String, dynamic> _event;
  late List<Map<String, dynamic>> _tiers;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
    _loadEventData();
  }

  void _loadEventData() {
    // Lookup by eventId — eventually Firestore
    final events = <String, Map<String, dynamic>>{
      'ufc-sydney-2026': {
        'name': 'UFC Fight Night — Sydney',
        'date': 'Saturday, 18 April 2026',
        'venue': 'Qudos Bank Arena, Sydney Olympic Park',
        'doors': '4:00 PM AEST',
        'mainEvent': '5:00 PM Prelims · 7:00 PM Main Card',
        'imageTag': 'UFC',
      },
      'one-samurai': {
        'name': 'ONE Samurai — Tokyo',
        'date': 'Friday, 8 May 2026',
        'venue': 'Ryōgoku Kokugikan, Tokyo',
        'doors': '3:00 PM JST',
        'mainEvent': '4:00 PM Prelims · 6:30 PM Main Card',
        'imageTag': 'ONE',
      },
      'bkfc-perth': {
        'name': 'BKFC Australia Tour — Perth',
        'date': 'Saturday, 30 May 2026',
        'venue': 'RAC Arena, Perth',
        'doors': '5:00 PM AWST',
        'mainEvent': '6:00 PM Prelims · 8:00 PM Main Card',
        'imageTag': 'BKFC',
      },
      'glory-kickboxing-82': {
        'name': 'GLORY 82 — World Championship',
        'date': 'Saturday, 14 June 2026',
        'venue': 'Rotterdam Ahoy, Netherlands',
        'doors': '5:00 PM CET',
        'mainEvent': '6:00 PM Prelims · 8:00 PM Main Card',
        'imageTag': 'GLORY',
      },
      'pfl-playoffs': {
        'name': 'PFL 2026 Playoffs — Lightweight',
        'date': 'Friday, 27 June 2026',
        'venue': 'Seminole Hard Rock, Hollywood FL',
        'doors': '5:30 PM EST',
        'mainEvent': '6:30 PM Prelims · 9:00 PM Main Card',
        'imageTag': 'PFL',
      },
    };

    _event =
        events[widget.eventId] ??
        {
          'name': 'DFC Combat Event',
          'date': 'TBA',
          'venue': 'Location TBA',
          'doors': 'TBA',
          'mainEvent': 'Full card TBA',
          'imageTag': 'DFC',
        };

    _tiers = [
      {
        'name': 'General Admission',
        'price': 79.00,
        'description': 'Standard bowl seating with full card access',
        'icon': Icons.event_seat,
        'color': DesignTokens.neonCyan,
        'features': [
          'Full event access',
          'Food court access',
          'DFC digital program',
        ],
      },
      {
        'name': 'Ringside',
        'price': 249.00,
        'description': 'Premium ringside seating within 5 rows',
        'icon': Icons.visibility,
        'color': DesignTokens.neonAmber,
        'features': [
          'Rows 1-5 ringside',
          'Complimentary drink on arrival',
          'DFC premium lanyard',
          'Early entry (30 min before doors)',
        ],
      },
      {
        'name': 'VIP Cageside',
        'price': 499.00,
        'description': 'Front-row cageside + backstage mixer access',
        'icon': Icons.diamond_outlined,
        'color': DesignTokens.neonMagenta,
        'features': [
          'Row 1 cageside seat',
          'Pre-event backstage tour',
          'Post-fight athlete mixer',
          'Open bar & premium catering',
          'Signed event poster',
          'DFC VIP merch pack',
        ],
      },
      {
        'name': 'DFC Platinum',
        'price': 999.00,
        'description': 'Ultimate event night experience — strictly limited',
        'icon': Icons.military_tech,
        'color': const Color(0xFFE0E0E0),
        'features': [
          'Private suite (4 guests)',
          'Meet & greet with headliners',
          'Walk-in with fighter entrance',
          'All-inclusive food & premium drinks',
          'Professional photo package',
          'Exclusive DFC Platinum merch',
          'Lifetime DFC Pro membership',
        ],
      },
    ];
  }

  double get _subtotal =>
      (_tiers[_selectedTier]['price'] as double) * _quantity;
  double get _serviceFee => _subtotal * 0.05;
  double get _total => _subtotal + _serviceFee;

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_purchaseComplete) return _buildConfirmation();

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildEventBanner()),
              SliverToBoxAdapter(child: _buildTierSelector()),
              SliverToBoxAdapter(child: _buildQuantityPicker()),
              SliverToBoxAdapter(child: _buildOrderSummary()),
              SliverToBoxAdapter(child: _buildPaymentMethods()),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildCheckoutBar(),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: DesignTokens.bgPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Get Tickets',
        style: TextStyle(
          color: DesignTokens.neonCyan,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: DesignTokens.neonGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: DesignTokens.neonGreen.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: DesignTokens.neonGreen, size: 14),
              SizedBox(width: 4),
              Text(
                'Secure',
                style: TextStyle(
                  color: DesignTokens.neonGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Event Banner ─────────────────────────────────────────────────
  Widget _buildEventBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
            DesignTokens.neonMagenta.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _event['imageTag'] ?? 'DFC',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _event['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _eventInfoRow(Icons.calendar_month, _event['date'] ?? ''),
          const SizedBox(height: 6),
          _eventInfoRow(Icons.location_on_outlined, _event['venue'] ?? ''),
          const SizedBox(height: 6),
          _eventInfoRow(Icons.access_time, 'Doors: ${_event['doors'] ?? ''}'),
          const SizedBox(height: 6),
          _eventInfoRow(Icons.sports_mma, _event['mainEvent'] ?? ''),
        ],
      ),
    );
  }

  Widget _eventInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ── Tier Selector ────────────────────────────────────────────────
  Widget _buildTierSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Ticket',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_tiers.length, (i) {
            final tier = _tiers[i];
            final selected = i == _selectedTier;
            final color = tier['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() => _selectedTier = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.1)
                      : DesignTokens.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? color.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.06),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(tier['icon'] as IconData, color: color, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tier['name'] as String,
                            style: TextStyle(
                              color: selected ? color : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          '\$${(tier['price'] as double).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    if (selected) ...[
                      const SizedBox(height: 8),
                      Text(
                        tier['description'] as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: (tier['features'] as List<String>)
                            .map(
                              (f) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: color.withValues(alpha: 0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Quantity Picker ──────────────────────────────────────────────
  Widget _buildQuantityPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              color: Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Quantity',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            _quantityButton(
              Icons.remove,
              _quantity > 1,
              () => setState(() => _quantity--),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$_quantity',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            _quantityButton(
              Icons.add,
              _quantity < 10,
              () => setState(() => _quantity++),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? DesignTokens.neonCyan.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: enabled ? DesignTokens.neonCyan : Colors.white24,
          size: 20,
        ),
      ),
    );
  }

  // ── Order Summary ────────────────────────────────────────────────
  Widget _buildOrderSummary() {
    final tierName = _tiers[_selectedTier]['name'] as String;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            _summaryRow(
              '$tierName × $_quantity',
              '\$${_subtotal.toStringAsFixed(2)}',
            ),
            _summaryRow(
              'Service fee (5%)',
              '\$${_serviceFee.toStringAsFixed(2)}',
            ),
            const Divider(color: Colors.white12, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment Methods ──────────────────────────────────────────────
  Widget _buildPaymentMethods() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            _paymentOption(
              'stripe',
              Icons.credit_card,
              'Credit / Debit Card',
              DesignTokens.neonCyan,
            ),
            const SizedBox(height: 8),
            _paymentOption(
              'paypal',
              Icons.account_balance_wallet,
              'PayPal',
              const Color(0xFF0070BA),
            ),
            const SizedBox(height: 8),
            _paymentOption(
              'afterpay',
              Icons.schedule,
              'Afterpay — 4 interest-free payments',
              const Color(0xFFB2FCE4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: DesignTokens.neonGreen,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Secured by Stripe, PayPal & Afterpay. DFC never stores your card details.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption(String id, IconData icon, String label, Color color) {
    final selected = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : Colors.white38, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? color : Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Checkout Bottom Bar ──────────────────────────────────────────
  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: DesignTokens.bgSecondary,
        border: Border(
          top: BorderSide(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
        ),
      ),
      child: GestureDetector(
        onTap: _isProcessing ? null : _handlePurchase,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: _isProcessing
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  )
                : const LinearGradient(
                    colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                  ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: _isProcessing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'PAY \$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePurchase() async {
    setState(() => _isProcessing = true);

    if (_paymentMethod == 'paypal') {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final tierName = _tiers[_selectedTier]['name'] as String;
      final price = _tiers[_selectedTier]['price'] as double;
      final paypal = PayPalService();
      final orderId = await paypal.createOrder(
        userId: userId,
        amountCents: (price * _quantity * 100).round(),
        currency: 'AUD',
        productType: 'ticket',
        productId: widget.eventId,
        productName: '$tierName x$_quantity — ${_event['name']}',
      );

      if (!mounted) return;
      if (orderId != null) {
        setState(() {
          _isProcessing = false;
          _purchaseComplete = true;
        });
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paypal.error ?? 'PayPal checkout failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      final tierName = _tiers[_selectedTier]['name'] as String;
      final link = DfcStripeLinks.ticketLink(tierName);
      final opened = await DfcStripeLinks.openPaymentLink(link);

      if (!mounted) return;
      if (opened) {
        setState(() {
          _isProcessing = false;
          _purchaseComplete = true;
        });
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open checkout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Purchase Confirmation ────────────────────────────────────────
  Widget _buildConfirmation() {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DesignTokens.neonGreen, DesignTokens.neonCyan],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'You\'re In!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_tiers[_selectedTier]['name']} × $_quantity',
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _event['name'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _event['date'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignTokens.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: DesignTokens.neonGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _confirmRow(
                        'Order #',
                        'DFC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                      ),
                      _confirmRow('Amount', '\$${_total.toStringAsFixed(2)}'),
                      _confirmRow('Status', 'Confirmed ✓'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A confirmation email has been sent.\nYour e-ticket and QR pass are available in My Passes.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => context.go(app_router.RouteConstants.home),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          DesignTokens.neonCyan,
                          DesignTokens.neonMagenta,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'BACK TO DFC',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.push(
                    app_router.RouteConstants.fightPassMyPassesPath,
                  ),
                  child: const Text(
                    'View My Passes',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontWeight: FontWeight.w600,
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

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
