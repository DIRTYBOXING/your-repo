import 'package:flutter/material.dart';
import '../../../../dfc_theme.dart';
import '../controllers/creator_monetization_controller.dart';
import '../models/creator_offer_model.dart';

class CreatorOffersScreen extends StatefulWidget {
  final String creatorId;

  const CreatorOffersScreen({super.key, required this.creatorId});

  @override
  State<CreatorOffersScreen> createState() => _CreatorOffersScreenState();
}

class _CreatorOffersScreenState extends State<CreatorOffersScreen> {
  late final CreatorMonetizationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreatorMonetizationController()..loadOffers(widget.creatorId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          "JOIN THE TEAM",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentCyan),
            );
          }
          if (_controller.offers.isEmpty) {
            return const Center(
              child: Text(
                "No active offers.",
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _controller.offers.length,
            itemBuilder: (_, i) {
              final o = _controller.offers[i];
              return _buildOfferCard(context, o);
            },
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, CreatorOfferModel o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.championGold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.championGold.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                o.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.stars, color: AppColors.championGold),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            o.description,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          Text(
            "\$${(o.priceCents / 100).toStringAsFixed(2)} ${o.currency} / month",
            style: const TextStyle(
              color: AppColors.championGold,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.championGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await _controller.subscribe(o.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Subscription activated",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: AppColors.championGold,
                    ),
                  );
                }
              },
              child: const Text(
                "UNLOCK ACCESS",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
