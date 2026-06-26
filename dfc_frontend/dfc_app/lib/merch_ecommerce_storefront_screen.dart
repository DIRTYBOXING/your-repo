import 'package:flutter/material.dart';

class MerchEcommerceStorefrontScreen extends StatelessWidget {
  const MerchEcommerceStorefrontScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: [
            const SizedBox(height: 32),

            // ─── 1. HEADER & CART ────────────────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'MERCH & GEAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ─── 2. LIMITED DROP HERO ────────────────────────────────────────
            _buildSectionHeader(
              Icons.local_fire_department,
              'LIMITED DROP',
              Colors.redAccent,
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1517438476312-10d79c077509?auto=format&fit=crop&q=80&w=800',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SELLING FAST',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'DFC PRO WALKOUT HOODIE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      '\$85.00',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── 3. CATEGORIES ───────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryPill('ALL GEAR', isActive: true),
                  const SizedBox(width: 12),
                  _buildCategoryPill('APPAREL'),
                  const SizedBox(width: 12),
                  _buildCategoryPill('EQUIPMENT'),
                  const SizedBox(width: 12),
                  _buildCategoryPill('ACCESSORIES'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── 4. PRODUCT GRID ─────────────────────────────────────────────
            _buildSectionHeader(
              Icons.grid_view,
              'OFFICIAL MERCHANDISE',
              Colors.cyanAccent,
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.65,
              children: [
                _buildProductCard(
                  name: 'DFC 4oz MMA Gloves',
                  price: '\$65.00',
                  imageUrl:
                      'https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?auto=format&fit=crop&q=80&w=400',
                  isNew: true,
                ),
                _buildProductCard(
                  name: 'Fighter Rashguard',
                  price: '\$45.00',
                  imageUrl:
                      'https://images.unsplash.com/photo-1509927083803-4bd519298ac4?auto=format&fit=crop&q=80&w=400',
                ),
                _buildProductCard(
                  name: 'Corner Team Jacket',
                  price: '\$110.00',
                  imageUrl:
                      'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&q=80&w=400',
                ),
                _buildProductCard(
                  name: 'Classic Logo Tee',
                  price: '\$30.00',
                  imageUrl:
                      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&q=80&w=400',
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String title, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.cyanAccent : Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required String name,
    required String price,
    required String imageUrl,
    bool isNew = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: isNew
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {},
                    child: const Text(
                      'ADD TO CART',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
