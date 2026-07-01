import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/dfc_glass_panel.dart';
import '../services/only_fit_service.dart';

class OnlyFitCreatorProfileScreen extends StatefulWidget {
  final String userId;

  const OnlyFitCreatorProfileScreen({super.key, required this.userId});

  @override
  State<OnlyFitCreatorProfileScreen> createState() =>
      _OnlyFitCreatorProfileScreenState();
}

class _WishListCounter extends StatefulWidget {
  final int initialCount;
  const _WishListCounter({required this.initialCount});

  @override
  State<_WishListCounter> createState() => _WishListCounterState();
}

class _WishListCounterState extends State<_WishListCounter> {
  late int _count;
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            _joined ? Icons.favorite : Icons.favorite_border,
            color: _joined ? AppColors.neonMagenta : Colors.white70,
            size: 28,
          ),
          onPressed: () {
            setState(() {
              _joined = !_joined;
              _count += _joined ? 1 : -1;
            });
          },
        ),
        Text(
          '$_count SUPPORTING',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _OnlyFitCreatorProfileScreenState
    extends State<OnlyFitCreatorProfileScreen> {
  final _onlyFitService = OnlyFitService();
  Map<String, dynamic>? _creatorData;
  bool _loading = true;
  bool _isPurchasingPpv = false;
  bool _isPurchasingTicket = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _onlyFitService.getCreatorProfile(widget.userId);
    if (mounted) {
      setState(() {
        _creatorData = data;
        _loading = false;
      });
    }
  }

  Future<void> _handlePpvPurchase() async {
    if (_isPurchasingPpv) return;
    setState(() {
      _isPurchasingPpv = true;
    });

    try {
      final checkoutUrl = await _onlyFitService.initiatePpvPurchase(
        widget.userId,
        'ppv_stream_id_101',
      );
      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isPurchasingPpv = false;
      });
    }
  }

  Future<void> _handleTicketPurchase() async {
    if (_isPurchasingTicket) return;
    setState(() {
      _isPurchasingTicket = true;
    });

    try {
      final checkoutUrl = await _onlyFitService.initiateTicketPurchase(
        'event_id_202',
        1,
      );
      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isPurchasingTicket = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.neonMagenta),
        ),
      );
    }

    final themeColor = _creatorData?['themeColor'] != null
        ? Color(int.parse(_creatorData!['themeColor'].replaceAll('#', '0xFF')))
        : AppColors.neonMagenta;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Vogue-Grade Editorial Hero Image
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _creatorData?['photoUrl'] ??
                        'https://api.datafightcentral.com/assets/placeholder.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.person,
                        size: 120,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _creatorData?['displayName']?.toUpperCase() ??
                                'CREATOR',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _creatorData?['specialty']?.toUpperCase() ??
                                'ATHLETE',
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const _WishListCounter(initialCount: 240),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Biography
                  DfcGlassPanel(
                    glowColor: themeColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CREATOR BIOGRAPHY',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _creatorData?['bio'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ONE-TAP DIRECT SALES BUTTONS
                  Row(
                    children: [
                      // Direct Buy PPV Ticket Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: themeColor.withValues(alpha: 0.4),
                          ),
                          onPressed: _isPurchasingPpv
                              ? null
                              : _handlePpvPurchase,
                          child: _isPurchasingPpv
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Column(
                                  children: [
                                    const Text(
                                      'BUY PPV ACCESS',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${((_creatorData?['ppvPriceCents'] ?? 0) / 100).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Direct Buy Event Ticket Button
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: themeColor, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isPurchasingTicket
                              ? null
                              : _handleTicketPurchase,
                          child: _isPurchasingTicket
                              ? CircularProgressIndicator(color: themeColor)
                              : Column(
                                  children: [
                                    const Text(
                                      'BUY EVENT TICKETS',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${((_creatorData?['ticketPriceCents'] ?? 0) / 100).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: themeColor,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      '⚡ NO CONVERSATIONS • DIRECT TICKETS & PPV SALES',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
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
}
