import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EVENT PRODUCT PAGE — Treats every event as a product with SKU variants
///
/// From the playbook: "Treat every event as a product with SKU variants:
/// General, Ringside, VIP Meet, PPV, Highlight Pack, Data Pack"
///
/// Each product card shows pricing, features, and a CTA.
/// Designed for promoters + fans to see the full event product offering.
/// ═══════════════════════════════════════════════════════════════════════════
class EventProductPage extends StatefulWidget {
  final EventModel? event;
  final String? eventId;

  const EventProductPage({super.key, this.event, this.eventId});

  @override
  State<EventProductPage> createState() => _EventProductPageState();
}

class _EventProductPageState extends State<EventProductPage> {
  late EventModel _event;

  @override
  void initState() {
    super.initState();
    _event =
        widget.event ??
        EventModel(
          id: 'product-demo',
          promoterId: 'self',
          name: 'Your Event Name',
          venue: 'Venue TBA',
          city: 'City',
          country: 'Australia',
          eventDate: DateTime.now().add(const Duration(days: 30)),
          sportType: 'MMA',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildEventHeader()),
            SliverToBoxAdapter(child: _buildSectionTitle('Tickets')),
            SliverToBoxAdapter(child: _buildTicketProducts()),
            SliverToBoxAdapter(child: _buildSectionTitle('Digital Products')),
            SliverToBoxAdapter(child: _buildDigitalProducts()),
            SliverToBoxAdapter(child: _buildSectionTitle('Bundles')),
            SliverToBoxAdapter(child: _buildBundles()),
            SliverToBoxAdapter(child: _buildPromoCodeField()),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: DesignTokens.bgPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Event Products',
        style: TextStyle(
          color: DesignTokens.neonCyan,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  // ── EVENT HEADER ─────────────────────────────────────────────────
  Widget _buildEventHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Sport icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonCyan.withValues(alpha: 0.3),
                  DesignTokens.neonCyan.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.sports_mma,
              color: DesignTokens.neonCyan,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _event.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_event.venue} • ${DateFormat('d MMM yyyy').format(_event.eventDate)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // ── TICKET PRODUCTS ──────────────────────────────────────────────
  Widget _buildTicketProducts() {
    final tickets = [
      const _ProductSKU(
        name: 'General Admission',
        price: 79,
        icon: Icons.event_seat,
        color: DesignTokens.neonCyan,
        features: [
          'Full event access',
          'Food court access',
          'DFC digital program',
        ],
      ),
      const _ProductSKU(
        name: 'Ringside',
        price: 249,
        icon: Icons.visibility,
        color: DesignTokens.neonAmber,
        features: ['Rows 1–5 ringside', 'Drink on arrival', 'Early entry'],
        tag: 'POPULAR',
      ),
      const _ProductSKU(
        name: 'VIP Meet & Greet',
        price: 499,
        icon: Icons.diamond_outlined,
        color: DesignTokens.neonMagenta,
        features: [
          'Cageside seat',
          'Backstage tour',
          'Athlete mixer',
          'Open bar',
          'Signed poster',
        ],
        tag: 'VIP',
      ),
      const _ProductSKU(
        name: 'DFC Platinum',
        price: 999,
        icon: Icons.military_tech,
        color: Color(0xFFE0E0E0),
        features: [
          'Private suite (4 guests)',
          'Headliner meet & greet',
          'Walk-in experience',
          'Photo package',
        ],
        tag: 'LIMITED',
      ),
    ];

    return _buildProductGrid(tickets);
  }

  // ── DIGITAL PRODUCTS ─────────────────────────────────────────────
  Widget _buildDigitalProducts() {
    final digital = [
      const _ProductSKU(
        name: 'PPV Live Stream',
        price: 24.99,
        icon: Icons.live_tv,
        color: Colors.red,
        features: [
          'Full live card',
          'Multi-camera',
          'Real-time scoring',
          '48hr replay',
        ],
        tag: 'STREAM',
      ),
      const _ProductSKU(
        name: 'Highlight Pack',
        price: 9.99,
        icon: Icons.auto_awesome,
        color: DesignTokens.neonGold,
        features: [
          'All finishes + KOs',
          'Slow-mo replays',
          'Downloadable clips',
          'Social-ready formats',
        ],
      ),
      const _ProductSKU(
        name: 'Data Pack',
        price: 14.99,
        icon: Icons.analytics,
        color: DesignTokens.neonGreen,
        features: [
          'Full fight stats',
          'Fighter profiles',
          'Prediction models',
          'CSV export',
        ],
        tag: 'NEW',
      ),
    ];

    return _buildProductGrid(digital);
  }

  // ── BUNDLES ──────────────────────────────────────────────────────
  Widget _buildBundles() {
    final bundles = [
      (
        name: 'Fan Bundle',
        items: 'GA Ticket + PPV + Highlight Pack',
        price: 99.99,
        savings: 'Save \$13',
        color: DesignTokens.neonCyan,
      ),
      (
        name: 'Ringside Digital',
        items: 'Ringside Ticket + PPV + Data Pack',
        price: 269.99,
        savings: 'Save \$19',
        color: DesignTokens.neonAmber,
      ),
      (
        name: 'Ultimate Experience',
        items: 'VIP Ticket + PPV + All Packs + Merch',
        price: 549.99,
        savings: 'Save \$38',
        color: DesignTokens.neonMagenta,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: bundles.map((bundle) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  bundle.color.withValues(alpha: 0.1),
                  bundle.color.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bundle.color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: bundle.color, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            bundle.name,
                            style: TextStyle(
                              color: bundle.color,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonGreen.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              bundle.savings,
                              style: const TextStyle(
                                color: DesignTokens.neonGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bundle.items,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${bundle.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: bundle.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Color(0xFF050A14),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── PROMO CODE ───────────────────────────────────────────────────
  Widget _buildPromoCodeField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Enter promo code',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'Apply',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PRODUCT GRID ─────────────────────────────────────────────────
  Widget _buildProductGrid(List<_ProductSKU> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: products.map(_buildProductCard).toList(),
      ),
    );
  }

  Widget _buildProductCard(_ProductSKU product) {
    final cardWidth = (MediaQuery.of(context).size.width - 44) / 2;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: product.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + tag
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: product.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(product.icon, color: product.color, size: 18),
              ),
              const Spacer(),
              if (product.tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: product.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.tag!,
                    style: TextStyle(
                      color: product.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Name
          Text(
            product.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 6),

          // Price
          Text(
            '\$${product.price % 1 == 0 ? product.price.toInt().toString() : product.price.toStringAsFixed(2)}',
            style: TextStyle(
              color: product.color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          // Features
          ...product.features
              .take(3)
              .map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check,
                        color: product.color.withValues(alpha: 0.6),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (product.features.length > 3)
            Text(
              '+${product.features.length - 3} more',
              style: TextStyle(
                color: product.color.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),

          const SizedBox(height: 10),

          // CTA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: product.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: product.color.withValues(alpha: 0.25)),
            ),
            child: Text(
              'Add to Cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: product.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal SKU model for product cards
class _ProductSKU {
  final String name;
  final double price;
  final IconData icon;
  final Color color;
  final List<String> features;
  final String? tag;

  const _ProductSKU({
    required this.name,
    required this.price,
    required this.icon,
    required this.color,
    required this.features,
    this.tag,
  });
}
