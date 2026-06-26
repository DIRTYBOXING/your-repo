/// ════════════════════════════════════════════════════════════════════════
/// DFC CONTENT POLICY — Zero-tolerance rules baked into code
///
/// DataFightCentral is an educational, sport-first combat sports platform.
/// All content is sanctioned sport — boxing, MMA, bare-knuckle, grappling.
/// No gambling. No drugs. No pornography. No toxic behaviour.
/// Built for fighters, coaches, fans, and families of the sport.
/// ════════════════════════════════════════════════════════════════════════
class ContentPolicy {
  ContentPolicy._();

  // ── Platform values ─────────────────────────────────────────────────
  static const String platformMission =
      'DataFightCentral is an educational combat sports platform. '
      'We cover all sanctioned combat sports — boxing, MMA, Muay Thai, '
      'bare-knuckle, wrestling, and grappling. Like football or basketball, '
      'these are legitimate sports viewed by athletes, coaches, families, '
      'and fans of all ages. We support discipline, recovery, respect, '
      'and accountability. Sport is never hidden here.';

  static const String inclusionPolicy =
      'DataFightCentral welcomes everyone. We do not judge people by '
      'identity, background, culture, religion, gender, orientation, age, '
      'or experience level. Moderation decisions are based on harmful or '
      'unsafe content and behavior only.';

  static const List<String> inclusiveCommunityPrinciples = [
    'Everyone is welcome to participate respectfully.',
    'No judgment based on identity, background, or personal story.',
    'Only unsafe, abusive, exploitative, or prohibited content is removed.',
    'Support, courage, recovery, and growth are core values.',
  ];

  // ── Prohibited categories ───────────────────────────────────────────
  static const List<String> prohibitedCategories = [
    'Adult / sexual content',
    'Nudity or sexualized imagery',
    'OnlyFans / escort / cam promotion',
    'Dating or hookup solicitation',
    'Gambling, betting, or odds',
    'Drug promotion or sales',
    'Alcohol / tobacco advertising',
    'Violence outside sanctioned sport',
    'Weapons promotion',
    'Hate speech or discrimination',
    'Harassment, bullying, or trolling',
    'Stalking or predatory behaviour',
    'Spam, scams, or phishing',
    'Health misinformation',
    'Political agendas',
    'Rage-bait or shock content',
  ];

  // ── Report reasons ──────────────────────────────────────────────────
  static const List<String> reportReasons = [
    'Adult or sexual content',
    'Harassment or bullying',
    'Gambling or betting',
    'Drug or substance promotion',
    'Violence or threats',
    'Hate speech or discrimination',
    'Spam or scam',
    'Stalking or predatory behaviour',
    'Health misinformation',
    'Inbox solicitation',
    'Trolling or toxic behaviour',
    'Underage safety concern',
    'Other',
  ];

  // ── Blocked keywords (client-side pre-filter) ────────────────────────
  /// Lowercased patterns that flag content for review.
  /// Server-side AI moderation does the heavy lifting; this list
  /// provides a fast client-side short-circuit for obvious violations.
  ///
  /// Categories: self-harm, threats, harassment, doxxing, hate speech,
  /// sexual/adult, gambling, drugs, scams, match fixing, spam, weapons.
  static const List<String> flaggedKeywordPatterns = [
    // ── Self-harm & suicide ─────────────────────────────────────────
    'kill yourself',
    'kys',
    'go die',
    'end your life',
    'drink bleach',
    'hang yourself',
    'slit your wrists',
    'jump off a bridge',
    'better off dead',
    'no one would miss you',
    'world without you',
    'self harm',
    'self-harm',
    'cut yourself',

    // ── Threats & violence ──────────────────────────────────────────
    'i will find you',
    'i know where you live',
    'i will hurt you',
    'i will end you',
    'i will destroy you',
    'come to your house',
    'you are dead',
    'you\'re dead',
    'gonna get you',
    'watch your back',
    'sleep with one eye open',
    'put you in a body bag',
    'curb stomp you',
    'bash your head',
    'break your legs',
    'snap your neck',
    'bomb threat',
    'shoot up',
    'mass shooting',
    'swatting',
    'swat you',

    // ── Harassment & bullying ───────────────────────────────────────
    'worthless',
    'pathetic loser',
    'kill urself',
    'off yourself',
    'neck yourself',
    'die in a fire',
    'hope you die',
    'fat pig',
    'ugly trash',
    'piece of garbage',
    'waste of oxygen',
    'waste of space',
    'nobody loves you',
    'you should be ashamed',
    'you disgust me',
    'subhuman',

    // ── Doxxing & stalking ──────────────────────────────────────────
    'doxx',
    'dox',
    'doxxed',
    'doxxing',
    'doxing',
    'leaked address',
    'leaked phone',
    'leaked number',
    'home address is',
    'real name is',
    'lives at',
    'works at',
    'i found your',
    'posted your address',
    'stalk',
    'stalking',
    'following you home',
    'tracking you',

    // ── Hate speech & slurs ─────────────────────────────────────────
    'white power',
    'white supremacy',
    'heil hitler',
    'sieg heil',
    'race war',
    'ethnic cleansing',
    'gas the',
    'lynch',
    'go back to your country',
    'dirty immigrant',
    'illegal alien',
    'sand monkey',
    'mud people',
    'subhuman race',

    // ── Sexual / adult content ──────────────────────────────────────
    'onlyfans',
    'only fans',
    'escort',
    'cam girl',
    'cam boy',
    'webcam show',
    'nude',
    'nudes',
    'send nudes',
    'xxx',
    'porn',
    'pornhub',
    'xvideos',
    'sex tape',
    'sex video',
    'hookup',
    'hook up',
    'sugar daddy',
    'sugar baby',
    'sugar mama',
    'dm for prices',
    'inbox me',
    'link in bio',
    'linktree',
    'fansly',
    'manyvids',
    'chaturbate',
    'stripchat',
    'cam site',
    'adult content',
    'nsfw',
    'explicit content',
    'sexual favors',
    'sexual favour',
    'lap dance',
    'happy ending',
    'body rub',
    'erotic massage',

    // ── Gambling & betting ──────────────────────────────────────────
    'gambling',
    'bet now',
    'place your bets',
    'parlay',
    'odds:',
    'sportsbet',
    'fanduel',
    'draftkings',
    'casino',
    'slot machine',
    'poker site',
    'online casino',
    'bet365',
    'bovada',
    'betway',
    'pinnacle bet',
    'unibet',
    'paddy power',
    'william hill',
    'ladbrokes',
    'tab betting',
    'pointsbet',
    'neds betting',
    'sportsbook',
    'accumulator bet',
    'free bet',
    'deposit bonus',
    'wagering',
    'payout odds',
    'crypto betting',

    // ── Drugs & substances ──────────────────────────────────────────
    'buy drugs',
    'sell drugs',
    'dealer',
    'mdma',
    'cocaine',
    'meth',
    'fentanyl',
    'heroin',
    'crack pipe',
    'crystal meth',
    'ice dealer',
    'weed delivery',
    'dmt',
    'lsd',
    'shrooms delivery',
    'xanax bars',
    'oxycontin',
    'percocet',
    'codeine syrup',
    'lean',
    'sizzurp',
    'drug plug',
    'telegram plug',
    'wickr',
    'signal plug',

    // ── Scams & phishing ────────────────────────────────────────────
    'send me bitcoin',
    'send me crypto',
    'double your money',
    'guaranteed returns',
    'wire transfer',
    'send gift card',
    'gift card code',
    'verify your account',
    'click this link',
    'account suspended',
    'act now before',
    'limited time offer',
    'congratulations you won',
    'you have been selected',
    'nigerian prince',
    'advance fee',
    'phishing',
    'too good to be true',
    'pyramid scheme',
    'ponzi',
    'get rich quick',
    'mlm opportunity',
    'forex signal',

    // ── Match fixing & corruption ───────────────────────────────────
    'fix the fight',
    'fixed fight',
    'took a dive',
    'take a dive',
    'throw the match',
    'threw the fight',
    'paid to lose',
    'rigged fight',
    'rigged match',
    'fight is fixed',
    'match fixing',
    'corruption in',
    'bribed referee',
    'bribed judge',
    'paid off the ref',
    'judge was bought',
    'insider tip',
    'guaranteed winner',

    // ── Spam & commercial abuse ─────────────────────────────────────
    'buy followers',
    'buy likes',
    'buy views',
    'follow for follow',
    'f4f',
    'sub for sub',
    's4s',
    'check my profile',
    'check my page',
    'promo code',
    'use code',
    'discount code',
    'affiliate link',
    'click my link',
    'free iphone',
    'free money',
    'giveaway winner',
    'claim your prize',
    'earn from home',
    'work from home opportunity',

    // ── Weapons & explosives ────────────────────────────────────────
    'buy gun',
    'sell gun',
    'ghost gun',
    'unregistered firearm',
    'untraceable weapon',
    'how to make a bomb',
    'pipe bomb',
    'molotov',
    'explosive device',
    'switch blade',
    'brass knuckles for sale',

    // ── Impersonation & fraud ───────────────────────────────────────
    'i am the real',
    'official account',
    'verified account',
    'i work for dfc',
    'dfc staff',
    'dfc admin',
    'send me your password',
    'share your login',
    'account recovery fee',
  ];

  // ── Safe engagement examples ────────────────────────────────────────
  static const List<String> encouragedContent = [
    'Training updates & camp progress',
    'Technique and strategy analysis',
    'Fight event promotion (official)',
    'Gym and coach recognition',
    'Mentorship and guidance',
    'Recovery stories & mental health',
    'Fitness and nutrition education',
    'Injury prevention tips',
    'Career guidance for athletes',
    'Supportive motivation',
    'Run It / combat sport news',
    'Family-friendly fan discussion',
  ];

  // ── Enforcement tiers ───────────────────────────────────────────────
  static const Map<int, String> enforcementTiers = {
    1: 'Content removed + warning',
    2: 'Temporary restriction + education',
    3: 'Extended suspension + review',
    4: 'Immediate permanent ban',
  };

  // ── Youth protection ────────────────────────────────────────────────
  static const int minimumAge = 13;
  static const int adultAge = 18;
  static const String youthProtectionPolicy =
      'Enhanced protections for under-18 users. No direct messaging '
      'between adults and minors. Youth-specific resources available.';

  // ── Crisis helplines (AU / NZ focus) ────────────────────────────────
  static const List<Map<String, String>> crisisHelplines = [
    {
      'name': 'Lifeline Australia',
      'number': '13 11 14',
      'description': '24/7 crisis support',
    },
    {
      'name': 'Beyond Blue',
      'number': '1300 22 4636',
      'description': 'Anxiety & depression support',
    },
    {
      'name': 'Kids Helpline',
      'number': '1800 55 1800',
      'description': 'Young people 5-25',
    },
    {
      'name': 'Lifeline NZ',
      'number': '0800 543 354',
      'description': '24/7 crisis support',
    },
    {
      'name': '1737 NZ',
      'number': '1737',
      'description': 'Mental health & addiction',
    },
    {
      'name': 'Youthline NZ',
      'number': '0800 376 633',
      'description': 'Youth support',
    },
  ];
}
