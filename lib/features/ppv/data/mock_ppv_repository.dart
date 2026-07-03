class PPVEvent {
  final String id;
  final String title;
  final String subtitle;
  final String date;
  final String price;
  final String imageUrl;
  final bool isLive;
  final bool isPurchased;

  PPVEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.price,
    required this.imageUrl,
    this.isLive = false,
    this.isPurchased = false,
  });
}

class MockPPVRepository {
  static final List<PPVEvent> featuredEvents = [
    PPVEvent(
      id: 'ppv_101',
      title: 'UFC 310: ISLAM VS LEON',
      subtitle: 'The Ultimate Showdown - Undisputed Lightweight Championship',
      date: 'Sat, Aug 24 • 10:00 PM EST',
      price: '\$79.99',
      imageUrl:
          'https://images.unsplash.com/photo-1544365558-35aa4afcf11f?q=80&w=1036&auto=format&fit=crop', // Replace with real asset later
      isLive: true,
    ),
    PPVEvent(
      id: 'ppv_102',
      title: 'GLORY: Knuckle Mania III',
      subtitle: 'Bare Knuckle World Championship',
      date: 'Sat, Sep 07 • 9:00 PM EST',
      price: '\$49.99',
      imageUrl:
          'https://images.unsplash.com/photo-1555597673-b21d5c935865?q=80&w=1000&auto=format&fit=crop',
    ),
  ];

  static final List<PPVEvent> vaultEvents = [
    PPVEvent(
      id: 'ppv_vault_1',
      title: 'UFC 300',
      subtitle: 'Pereira vs Hill',
      date: 'Archived',
      price: '\$19.99',
      imageUrl:
          'https://images.unsplash.com/photo-1599552375245-8fe1df6b7eb7?q=80&w=1000&auto=format&fit=crop',
    ),
    PPVEvent(
      id: 'ppv_vault_2',
      title: 'ONE FC: Impact',
      subtitle: 'Superbon Returns',
      date: 'Archived',
      price: '\$9.99',
      imageUrl:
          'https://images.unsplash.com/photo-1628286282822-ecc33fa81b8e?q=80&w=1000&auto=format&fit=crop',
      isPurchased: true,
    ),
    PPVEvent(
      id: 'ppv_vault_3',
      title: 'ADCC Worlds',
      subtitle: 'Grappling Championship',
      date: 'Archived',
      price: '\$14.99',
      imageUrl:
          'https://images.unsplash.com/photo-1622599511051-16f55a1234d0?q=80&w=1000&auto=format&fit=crop',
    ),
  ];
}
