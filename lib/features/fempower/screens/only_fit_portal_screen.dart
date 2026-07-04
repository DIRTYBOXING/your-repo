import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/dfc_glass_panel.dart';
import '../../../../shared/widgets/onlyfit_prediction_card.dart';
import '../../creator/widgets/premium_creator_profile_showroom.dart';

class OnlyFitPortalScreen extends StatefulWidget {
  const OnlyFitPortalScreen({super.key});

  @override
  State<OnlyFitPortalScreen> createState() => _OnlyFitPortalScreenState();
}

class _OnlyFitPortalScreenState extends State<OnlyFitPortalScreen> {
  String? _selectedCreatorId;

  // Curated, elegant lineup of premium combat-fitness experts & champions
  final List<Map<String, dynamic>> _creators = [
    {
      'id': 'cristine_fereano',
      'name': 'Cristine Fereano',
      'title': 'Cris "The Rose" Fereano',
      'specialty': 'Bantamweight MMA / Muay Thai',
      'country': '🇦🇺 AU/NZ',
      'payoutStatus': 'verified',
      'image': 'https://api.datafightcentral.com/assets/cristine_avatar.png',
      'bgGradient': [Color(0xFFE86A8A), Colors.black],
    },
    {
      'id': 'bec_rawlings',
      'name': 'Bec Rawlings',
      'title': 'Bec "Rowdy" Rawlings',
      'specialty': 'Flyweight Bareknuckle Boxing',
      'country': '🇦🇺 AU/NZ',
      'payoutStatus': 'verified',
      'image': 'https://api.datafightcentral.com/assets/bec_avatar.png',
      'bgGradient': [Color(0xFF4A90E2), Colors.black],
    },
    {
      'id': 'cassy_thompson',
      'name': 'Cassy Thompson',
      'title': 'Cassy "The Shadow" Thompson',
      'specialty': 'Kickboxing / Conditioning',
      'country': '🇬🇧 UK',
      'payoutStatus': 'verified',
      'image': 'https://api.datafightcentral.com/assets/cassy_avatar.png',
      'bgGradient': [Color(0xFF2ECC71), Colors.black],
    },
  ];

  // Professional corporate-grade ML match prediction data
  final FighterBrief _fereanoBrief = const FighterBrief(
    name: 'Cris Fereano',
    record: '15-2-0',
    heightCm: 168,
    reachCm: 172,
    avgStrikesLanded: 6.84,
    keyStrengths: [
      'Striking volume & precision',
      'Queensland Muay Thai dominance',
      'Bantamweight size advantage',
    ],
    keyWeaknesses: [
      'Grappling defense transitions',
      'Loves aggressive tie-ups early',
    ],
  );

  final FighterBrief _rawlingsBrief = const FighterBrief(
    name: 'Bec Rawlings',
    record: '18-9-0',
    heightCm: 165,
    reachCm: 168,
    avgStrikesLanded: 5.12,
    keyStrengths: [
      'Bareknuckle championship grit',
      'Devastating dirty boxing output',
      'Extremely durable recovery rate',
    ],
    keyWeaknesses: [
      'Striking guard defense at range',
      'Gets out-volumed by kickboxers',
    ],
  );

  @override
  Widget build(BuildContext context) {
    // If an athlete is selected, open their premium high-fidelity showroom
    if (_selectedCreatorId != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedCreatorId = null;
              });
            },
          ),
          title: const Text(
            'ONLYFIT SHOWROOM',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white54,
            ),
          ),
        ),
        body: PremiumCreatorProfileShowroom(creatorId: _selectedCreatorId!),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Vogue-grade Elite Header Banner
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'ONLYFIT DIRECTORY',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HIGH-PRESTIGE COMBAT CREATOR NETWORK',
                    style: TextStyle(
                      color: AppColors.neonMagenta,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1F0D24), Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neonMagenta.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.neonMagenta.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.shield,
                            color: AppColors.neonMagenta,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'STRIPE EXPRESS INTEGRATED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Portal Feed & Navigation Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Corporate Predictive Card Showcase Header
                const Row(
                  children: [
                    Icon(Icons.query_stats, color: Colors.white54),
                    SizedBox(width: 8),
                    Text(
                      'AI FIGHT PREDICTIONS',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Real Data Prediction Engine integration
                OnlyFitPredictionCard(
                  fighterA: _fereanoBrief,
                  fighterB: _rawlingsBrief,
                  winProbA: 0.64,
                  explanation:
                      'SHAP analysis weights Fereano Muay Thai low-mid clinch range volume (+18% contribution) over Rawlings traditional glove guards (+10% contribution). Expected outcome matches a high-pace strike separation win.',
                ),

                const SizedBox(height: 36),

                // Athlete Directory header
                const Row(
                  children: [
                    Icon(
                      Icons.supervised_user_circle_sharp,
                      color: Colors.white54,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ELITE ATHLETES & CURATORS',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Artist-grade athletes list
                ..._creators.map((creator) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCreatorId = creator['id'];
                        });
                      },
                      child: DfcGlassPanel(
                        glowColor: creator['bgGradient'][0] as Color,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              // Elegant rounded avatar bordered by brand token
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: creator['bgGradient'][0] as Color,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    creator['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[900],
                                      child: Icon(
                                        Icons.person,
                                        color:
                                            creator['bgGradient'][0] as Color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),

                              // Metadata Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          creator['name'].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          creator['country'],
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      creator['specialty'].toUpperCase(),
                                      style: TextStyle(
                                        color:
                                            creator['bgGradient'][0] as Color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          color:
                                              creator['bgGradient'][0] as Color,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'KYC VERIFIED • DIRECT PORTAL',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Next navigation chevron
                              Icon(
                                Icons.chevron_right_rounded,
                                color: creator['bgGradient'][0] as Color,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
