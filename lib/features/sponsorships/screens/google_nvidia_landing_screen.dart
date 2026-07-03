import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleNvidiaLandingScreen extends StatefulWidget {
  const GoogleNvidiaLandingScreen({super.key});

  @override
  State<GoogleNvidiaLandingScreen> createState() => _GoogleNvidiaLandingScreenState();
}

class _GoogleNvidiaLandingScreenState extends State<GoogleNvidiaLandingScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020810),
      body: Stack(
        children: [
          // Background Tech Grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/tech_grid.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
          
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 400.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.neonCyan.withValues(alpha: 0.2),
                              const Color(0xFF020810),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 50),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Placeholder for DFC Logo
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.neonMagenta, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: AppTheme.neonMagenta.withValues(alpha: 0.5), blurRadius: 20),
                                  ],
                                ),
                                child: const Center(
                                  child: Text('DFC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                                ),
                              ),
                              const SizedBox(width: 20),
                              const Icon(Icons.add, color: Colors.white, size: 30),
                              const SizedBox(width: 20),
                              // Placeholder for Google/Nvidia Logos
                              Container(
                                width: 140,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.neonCyan, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: AppTheme.neonCyan.withValues(alpha: 0.5), blurRadius: 20),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.g_mobiledata, color: Colors.white, size: 40),
                                    Text('Cloud', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'EMPOWERING COMBAT SPORTS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'AT GLOBAL SCALE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.neonCyan,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              shadows: [
                                Shadow(color: AppTheme.neonCyan.withValues(alpha: 0.8), blurRadius: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('THE ARCHITECTURE OF IMPACT', AppTheme.neonCyan),
                      const SizedBox(height: 20),
                      Text(
                        'Data Fight Central (DFC) leverages elite cloud infrastructure to build the most comprehensive, low-latency combat sports ecosystem on earth. From real-time global event streaming to deep neural coaching networks, we require computing power that scales instantly.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, height: 1.6),
                      ),
                      const SizedBox(height: 60),
                      
                      _buildPartnerCard(
                        title: 'GOOGLE CLOUD FOR STARTUPS',
                        subtitle: 'SCALABLE BACKEND & ML',
                        color: const Color(0xFF4285F4),
                        icon: Icons.cloud_queue,
                        details: [
                          'Real-time Firestore for live fight data & chat',
                          'Edge-cached streaming for PPV events worldwide',
                          'TensorFlow pipelines for fighter biomechanics',
                        ],
                      ),
                      const SizedBox(height: 30),
                      
                      _buildPartnerCard(
                        title: 'NVIDIA INCEPTION PROGRAM',
                        subtitle: 'AI & EDGE INFERENCE',
                        color: const Color(0xFF76B900),
                        icon: Icons.memory,
                        details: [
                          'GPU-accelerated video rendering for promo engine',
                          'On-device neural coaching models (TensorRT)',
                          'Computer vision for live fight scoring analytics',
                        ],
                      ),
                      const SizedBox(height: 60),
                      
                      _buildSectionHeader('PARTNER WITH DFC', AppTheme.neonMagenta),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'We are currently accepting applications for strategic technology partners and infrastructure grants.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () => _launchURL('mailto:partners@datafightcentral.com'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.neonCyan,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'INITIATE CONTACT',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required List<String> details,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Icon(
                    icon,
                    size: 150,
                    color: color.withValues(alpha: 0.05 + (_pulseController.value * 0.05)),
                  );
                }
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: color,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...details.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle, color: color, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                d,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}