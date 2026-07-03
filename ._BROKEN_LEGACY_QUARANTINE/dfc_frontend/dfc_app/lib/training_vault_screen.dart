import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'blue/controllers/training_content_controller.dart';
import 'blue/repositories/training_content_repository.dart';
import 'blue/state/training_content_state.dart';
import 'blue/models/training_content_model.dart';

class TrainingVaultScreen extends StatefulWidget {
  final String creatorId;
  final String creatorName;

  const TrainingVaultScreen({
    super.key,
    required this.creatorId,
    required this.creatorName,
  });

  @override
  State<TrainingVaultScreen> createState() => _TrainingVaultScreenState();
}

class _TrainingVaultScreenState extends State<TrainingVaultScreen> {
  late final TrainingContentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TrainingContentController(
      repo: TrainingContentRepository(api: ApiService()),
    )..loadVault(widget.creatorId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _triggerCheckoutSession(TrainingContentModel item) async {
    // 1. Show a loading dialog while we fetch the session URL from the backend
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.purpleAccent),
      ),
    );

    try {
      // 2. Call your backend (via ApiService) to create a Stripe Checkout Session
      // final String checkoutUrl = await ApiService().createStripeCheckoutSession(
      //   creatorId: widget.creatorId,
      //   contentId: item.id,
      // );
      
      // Placeholder URL. Replace this with the URL returned from your API.
      final Uri url = Uri.parse('https://checkout.stripe.com/pay/cs_test_placeholder');

      // 3. Launch the secure Stripe web checkout
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch checkout URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate checkout: $e')),
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss the loading dialog
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            // ─── HEADER ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.creatorName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Text(
                          'TRAINING VAULT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── VAULT CONTENT ───────────────────────────────────────────────
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final state = _controller.state;

                  if (state is TrainingContentInitial ||
                      state is TrainingContentLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.purpleAccent,
                      ),
                    );
                  }

                  if (state is TrainingContentError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  if (state is TrainingContentLoaded) {
                    if (state.content.isEmpty) {
                      return const Center(
                        child: Text(
                          'Vault is empty.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => _controller.loadVault(widget.creatorId),
                      color: Colors.purpleAccent,
                      backgroundColor: const Color(0xFF0A0E17),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        itemCount: state.content.length,
                        itemBuilder: (context, index) {
                          return _buildVaultCard(state.content[index]);
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultCard(TrainingContentModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Area
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(item.thumbnailUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: item.isPremium ? 0.6 : 0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),

              // Play Button or Lock Gate
              if (!item.isPremium)
                Icon(
                  Icons.play_circle_fill,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 54,
                )
              else
                GestureDetector(
                  onTap: () {
                    // V12 Entitlement Action: User clicks locked content
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Access Denied. Subscribe to unlock.',
                          style: TextStyle(color: Colors.black),
                        ),
                        backgroundColor: Colors.cyanAccent,
                        action: SnackBarAction(
                          label: "VIEW OFFERS",
                          textColor: Colors.black,
                          onPressed: () => _triggerCheckoutSession(item),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyanAccent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock, color: Colors.cyanAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'LOCKED • TAP TO UNLOCK',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.duration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Details Area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
