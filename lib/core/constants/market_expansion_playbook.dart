library;

class MarketExpansionScript {
  final String region;
  final String prominentFightBrand;
  final String gatewayHeadline;
  final String gatewaySubtitle;
  final String gymOffer;
  final String creatorAmplifier;

  const MarketExpansionScript({
    required this.region,
    required this.prominentFightBrand,
    required this.gatewayHeadline,
    required this.gatewaySubtitle,
    required this.gymOffer,
    required this.creatorAmplifier,
  });
}

class MarketExpansionPlaybook {
  MarketExpansionPlaybook._();

  static const Map<String, String> _countryToRegion = {
    'IN': 'india',
    'NZ': 'oceania',
    'PG': 'oceania',
    'SB': 'oceania',
    'AU': 'oceania',
    'JP': 'japan',
    'NG': 'africa',
    'KE': 'africa',
    'GH': 'africa',
    'ZA': 'africa',
    'TZ': 'africa',
    'UG': 'africa',
    'CM': 'africa',
    'SN': 'africa',
    'BR': 'latam',
    'MX': 'latam',
    'CO': 'latam',
    'AR': 'latam',
    'PE': 'latam',
    'CL': 'latam',
    'US': 'north-america',
    'CA': 'north-america',
    'GB': 'europe',
    'FR': 'europe',
    'DE': 'europe',
    'IT': 'europe',
    'ES': 'europe',
    'NL': 'europe',
  };

  static String prominentPromotionForRegion(String region) {
    switch (region) {
      case 'india':
        return 'MMA + Boxing crossover cards';
      case 'africa':
        return 'Boxing + MMA regional title nights';
      case 'oceania':
        return 'Kickboxing + MMA contender showcases';
      case 'japan':
        return 'Elite kickboxing and MMA grand events';
      case 'latam':
        return 'Boxing mega cards + rising MMA scenes';
      case 'north-america':
        return 'UFC, boxing, and BKFC mainstream cards';
      case 'europe':
        return 'Kickboxing and MMA major arena events';
      default:
        return 'Top local fight cards by demand';
    }
  }

  static MarketExpansionScript scriptFor({
    required String countryCode,
    required String languageCode,
  }) {
    final country = countryCode.toUpperCase();
    final lang = languageCode.toLowerCase();
    final region = _countryToRegion[country] ?? 'global';
    final prominent = prominentPromotionForRegion(region);

    final headline = _headlineFor(lang);
    final subtitle = _subtitleFor(lang);
    final gymOffer = _gymOfferFor(lang);
    final amplifier = _creatorAmplifierFor(lang);

    return MarketExpansionScript(
      region: region,
      prominentFightBrand: prominent,
      gatewayHeadline: headline,
      gatewaySubtitle: subtitle,
      gymOffer: gymOffer,
      creatorAmplifier: amplifier,
    );
  }

  static String _headlineFor(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'DFC FightPipe - Aapka agla mauka';
      case 'sw':
        return 'DFC FightPipe - Nafasi yako inayofuata';
      case 'pt':
        return 'DFC FightPipe - Sua proxima chance';
      case 'ja':
        return 'DFC FightPipe - Next destination stage';
      default:
        return 'DFC FightPipe - Your next fight destination';
    }
  }

  static String _subtitleFor(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'Sthanik talent ko global events, gym deals, aur travel opportunity se jodo.';
      case 'sw':
        return 'Unganisha vipaji vya eneo lako na matukio ya kimataifa, ofa za gym, na safari za mapambano.';
      case 'pt':
        return 'Conecte talentos locais a eventos globais, ofertas de academia e oportunidades de viagem.';
      case 'ja':
        return 'Local talent to global cards, gym partnerships, and destination fight opportunities.';
      default:
        return 'Connect local talent to global cards, gym partnerships, and destination fight opportunities.';
    }
  }

  static String _gymOfferFor(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'Gym offer: team tickets + fighter entry bundle for partner events.';
      case 'sw':
        return 'Gym offer: tiketi za timu + kifurushi cha usajili wa mpiganaji kwa matukio washirika.';
      case 'pt':
        return 'Oferta para academias: ingressos de equipe + pacote de inscricao para lutadores.';
      case 'ja':
        return 'Gym offer: team ticket bundles plus fighter entry allocations.';
      default:
        return 'Gym offer: team ticket bundles plus fighter entry allocations.';
    }
  }

  static String _creatorAmplifierFor(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'Amplifier: ex-champ + creator collab (5M+ subscribers) to lift awareness and sales.';
      case 'sw':
        return 'Amplifier: ushirikiano wa bingwa wa zamani na muundaji (5M+ subscribers) kuongeza mauzo.';
      case 'pt':
        return 'Amplificador: parceria com ex-campeao e criador (5M+ inscritos) para aumentar vendas.';
      case 'ja':
        return 'Amplifier: ex-champion and 5M+ creator collaborations to drive ticket and PPV sales.';
      default:
        return 'Amplifier: ex-champion and 5M+ creator collaborations to drive ticket and PPV sales.';
    }
  }
}
