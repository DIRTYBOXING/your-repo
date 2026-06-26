import 'package:flutter/material.dart';
import '../core/constants/image_assets.dart';
import 'fight_card_poster.dart';
import 'dfc_ppv_event_card.dart';

class PpvHubScreen extends StatelessWidget {
  const PpvHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'PPV HUB',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero poster — uses a poster URL
            const AspectRatio(
              aspectRatio: 16 / 9,
              child: FightCardPosterSimple(posterUrl: ImageAssets.ppvBkfc72Hero),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'UPCOMING CARDS',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  DfcPpvEventCard(
                    title: 'Opetaia vs. Bakole',
                    date: 'Jan 2025',
                    posterUrl: ImageAssets.boxingPlaceholder,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  DfcPpvEventCard(
                    title: 'Ngannou vs. Jones 2',
                    date: 'March 2025',
                    posterUrl: ImageAssets.ufcPlaceholder,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
