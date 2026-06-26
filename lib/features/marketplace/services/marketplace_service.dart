import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/market_item_model.dart';

class MarketplaceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'marketplace_items';

  // Demo items used as fallback when Firestore is empty
  static final List<MarketItem> demoItems = [
    const MarketItem(
      id: '1',
      name: 'DFC T-Shirt',
      description: 'Official Data Fight Central tee. Neon print.',
      imageUrl: 'assets/marketplace/tshirt.png',
      price: 2500,
      category: 'Apparel',
    ),
    const MarketItem(
      id: '2',
      name: 'Premium Fight Card',
      description: 'Unlock a premium AI-generated fight card.',
      imageUrl: 'assets/marketplace/fightcard.png',
      price: 1200,
      category: 'Digital',
    ),
    const MarketItem(
      id: '3',
      name: 'Custom Avatar Frame',
      description: 'Stand out in the community with a neon avatar frame.',
      imageUrl: 'assets/marketplace/avatar_frame.png',
      price: 800,
      category: 'Cosmetic',
    ),
  ];

  /// Fetch items from Firestore; falls back to demoItems if empty or offline.
  static Future<List<MarketItem>> getMarketItems() async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .orderBy('price')
          .limit(50)
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs
            .map((d) => MarketItem.fromMap(d.data(), docId: d.id))
            .toList();
      }
    } catch (_) {
      // Firestore unavailable — use demo fallback
    }
    return demoItems;
  }

  /// Stream marketplace items in real-time.
  static Stream<List<MarketItem>> streamMarketItems() {
    return _firestore
        .collection(_collection)
        .orderBy('price')
        .limit(50)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return demoItems;
          return snap.docs
              .map((d) => MarketItem.fromMap(d.data(), docId: d.id))
              .toList();
        });
  }

  /// Add an item (admin/seller use).
  static Future<void> addItem(MarketItem item) async {
    await _firestore.collection(_collection).doc(item.id).set(item.toMap());
  }
}
