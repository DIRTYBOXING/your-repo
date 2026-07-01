import '../services/article_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC ARTICLE SEEDS — Editorial content for launch
///
/// Usage:
///   await ArticleSeeder.seedAll();
/// ═══════════════════════════════════════════════════════════════════════════
class ArticleSeeder {
  static final _articleService = ArticleService();

  /// Seed all launch articles
  static Future<void> seedAll() async {
    await _seedLoganFightingSpirit();
  }

  /// Article #1 — The Fighting Spirit of Logan and Its Warriors
  static Future<String> _seedLoganFightingSpirit() async {
    return _articleService.publishArticle(
      title: 'DFC FightMedia — The Fighting Spirit of Logan and Its Warriors',
      summary:
          'Logan is the undisputed fighting heart of Australia. Home to a vibrant '
          'Pacific Islander and Māori population, it produces some of the '
          'fiercest competitors in boxing, MMA, Muay Thai, and bare-knuckle '
          'fighting. DFC FightMedia stands as the proud voice of Logan\'s warriors.',
      content: '''🌏 LOGAN — THE UNDISPUTED FIGHTING HEART OF AUSTRALIA

Logan is not just a city; it's a crucible where raw talent, relentless grit, and unbreakable spirit collide. It's a place where warriors are forged in the fires of the streets and gyms, where every punch thrown carries the weight of community pride and the hunger for respect. Home to a vibrant Pacific Islander and Māori population, Logan has become the undisputed fighting heart of Australia, producing some of the fiercest competitors in boxing, MMA, Muay Thai, and bare-knuckle fighting.

🥊 DFC — THE VOICE AND POWERHOUSE OF LOGAN'S FIGHTING ELITE

DFC FightMedia stands as the proud promoter and amplifier of Logan's fiercest warriors. We don't just organize fights; we tell the stories of those who carry their culture, their hood, and their legacy into every battle. This is where the streets meet the ring, and where fighters like Haze Hepi and BK Bau rise as true champions of their communities.

Haze Hepi, a titan in the ring, embodies the fighting spirit of Logan. From a promising rugby league talent to a warrior who overcame personal battles, Hepi's journey is a testament to resilience and transformation. His presence on the Tszyu undercard is not just a fight; it's a statement — a beacon for those who come from the same streets, proving that the hood's fighting spirit can conquer any arena.

BK Bau, another fierce competitor, carries the raw energy and pride of Logan into every fight. Together with Hepi and other warriors, they represent more than just themselves — they represent the hopes, struggles, and unyielding spirit of their neighborhoods.

🔥 FROM THE HOOD TO THE GLOBAL STAGE — THE UNSTOPPABLE FIGHTING SPIRIT

The fighters promoted by DFC are more than athletes; they are cultural icons and role models who bring the unfiltered energy of Logan's streets to the world. Their fights are battles for respect, legacy, and the future of their communities. DFC FightMedia is the platform that elevates these stories, turning local legends into international stars.

We celebrate the hustle, the sacrifice, and the relentless drive that defines Logan's fighters. Every fight is a chapter in a larger story — one of power, pride, and the soul of the hood unleashed.

🌟 DFC FIGHTMEDIA — BUILDING A LEGACY THAT HONORS ROOTS AND RAISES CHAMPIONS

DFC FightMedia is more than a promotion company; it's a movement dedicated to uplifting Logan's fighters and those who represent the hoods across Australia and beyond. We are committed to building a legacy that honors their roots, culture, and unyielding fighting spirit.

Join us as we champion the warriors of Logan — the fighters who bleed for their streets and fight for their future. This is more than combat sports; this is the raw, unbreakable soul of the hood unleashed on the world stage.''',
      tags: [
        'logan',
        'bkfc',
        'haze-hepi',
        'bk-bau',
        'bare-knuckle',
        'pacific-islander',
        'maori',
        'boxing',
        'mma',
        'australia',
        'dfc-fightmedia',
        'community',
      ],
      categories: ['bkfc', 'boxing', 'local'],
      isFeatured: true,
      relatedFighterIds: ['haze_hepi', 'bk_bau'],
    );
  }
}
