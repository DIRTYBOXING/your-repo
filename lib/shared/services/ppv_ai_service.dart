// ignore_for_file: avoid_print
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ppv_model.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PPV AI SERVICE — DFC Intelligence Layer
// ═════════════════════════════════════════════════════════════════════════════
//
// Domain-aware, context-sensitive assistant that understands PPV sales,
// fight breakdowns, event navigation, and support queries.
//
// Architecture:
//   User text → _parseIntent() → Firestore query → _composeResponse()
//
// Intent coverage:
//   greeting        — hi / hello / hey
//   listEvents      — show events / what's on / upcoming
//   buyPpv          — buy / purchase / price / how much
//   explainFight    — tell me about / who is / fighter / record / matchup
//   findByCriteria  — cheapest / boxing / MMA / live now / under $X / tonight
//   getHelp         — can't access / stream broken / receipt / support / cast
//   navigate        — go to / take me to / open
//   unknown         — fallback
//
// ═════════════════════════════════════════════════════════════════════════════

enum PpvAiIntent {
  greeting,
  listEvents,
  buyPpv,
  explainFight,
  findByCriteria,
  getHelp,
  navigate,
  unknown,
}

// ── Message model ─────────────────────────────────────────────────────────────

class PpvAiMessage {
  final String id;
  final bool isUser;
  final String text;

  /// Optional structured data — rendered as cards in the UI
  final List<PPVEvent> events;
  final List<Map<String, dynamic>> fighters;

  /// Quick-reply chip suggestions shown below this message
  final List<String> quickReplies;

  final DateTime timestamp;

  const PpvAiMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.events = const [],
    this.fighters = const [],
    this.quickReplies = const [],
    required this.timestamp,
  });

  static PpvAiMessage user(String text) => PpvAiMessage(
    id: '${DateTime.now().millisecondsSinceEpoch}-u',
    isUser: true,
    text: text,
    timestamp: DateTime.now(),
  );

  static PpvAiMessage ai({
    required String text,
    List<PPVEvent> events = const [],
    List<Map<String, dynamic>> fighters = const [],
    List<String> quickReplies = const [],
  }) => PpvAiMessage(
    id: '${DateTime.now().millisecondsSinceEpoch}-a',
    isUser: false,
    text: text,
    events: events,
    fighters: fighters,
    quickReplies: quickReplies,
    timestamp: DateTime.now(),
  );
}

// ── Service ───────────────────────────────────────────────────────────────────

class PpvAiService extends ChangeNotifier {
  PpvAiService._();
  static final PpvAiService _instance = PpvAiService._();
  factory PpvAiService() => _instance;

  final _firestore = FirebaseFirestore.instance;

  final List<PpvAiMessage> _messages = [];
  bool _isThinking = false;

  List<PpvAiMessage> get messages => List.unmodifiable(_messages);
  bool get isThinking => _isThinking;
  bool get hasConversation => _messages.isNotEmpty;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Start a fresh session (called when overlay opens)
  void startSession() {
    if (_messages.isNotEmpty) return; // Already has conversation
    _messages.add(
      PpvAiMessage.ai(
        text:
            'DFC INTELLIGENCE — Ready.\n\nI know every event, every fighter, every price. What are you looking for?',
        quickReplies: [
          "What's on this weekend?",
          "Show me live events",
          "Cheapest PPV right now",
          "Tell me about a fighter",
        ],
      ),
    );
    notifyListeners();
  }

  void reset() {
    _messages.clear();
    _isThinking = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messages.add(PpvAiMessage.user(text));
    _isThinking = true;
    notifyListeners();

    try {
      final intent = _parseIntent(text);
      final response = await _buildResponse(intent, text);
      _messages.add(response);
    } catch (e) {
      debugPrint('PpvAiService.sendMessage error: $e');
      _messages.add(
        PpvAiMessage.ai(
          text:
              "I hit a snag pulling that data. Try again or ask me something else.",
          quickReplies: ["What's on?", "Show live events", "Help"],
        ),
      );
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }

  // ── Intent Parser ─────────────────────────────────────────────────────────

  PpvAiIntent _parseIntent(String text) {
    final t = text.toLowerCase();

    // Greeting
    if (RegExp(r'\b(hi|hey|hello|sup|yo|gday)\b').hasMatch(t)) {
      return PpvAiIntent.greeting;
    }

    // Help / Support
    if (RegExp(
      r"can't access|can't watch|not working|stream broken|"
      r'receipt|refund|cast|chromecast|support|help me|issue|problem|'
      r'purchase (didn|did not)|not working',
    ).hasMatch(t)) {
      return PpvAiIntent.getHelp;
    }

    // Navigate
    if (RegExp(r'\b(go to|take me|open|navigate|show me the)\b').hasMatch(t) &&
        RegExp(r'\b(feed|home|map|gym|profile|store|hub)\b').hasMatch(t)) {
      return PpvAiIntent.navigate;
    }

    // Buy / Purchase
    if (RegExp(
      r'\b(buy|purchase|get|order|subscribe|checkout|how much|price|cost|'
      r'how do i (buy|get|watch)|want to watch)\b',
    ).hasMatch(t)) {
      return PpvAiIntent.buyPpv;
    }

    // Fighter / Matchup
    if (RegExp(
      r'\b(fighter|matchup|match up|who is|who are|record|stats|'
      r'tell me about|breakdown|vs|versus|fight card|main event)\b',
    ).hasMatch(t)) {
      return PpvAiIntent.explainFight;
    }

    // Find by criteria
    if (RegExp(
      r'\b(cheapest|most expensive|best value|boxing|mma|bkfc|kickboxing|'
      r'muay thai|live now|live tonight|starting soon|tonight|this weekend|'
      r'under \$|below \$|australia|aussie|region|sport)\b',
    ).hasMatch(t)) {
      return PpvAiIntent.findByCriteria;
    }

    // List events
    if (RegExp(
      r"\b(show|list|what's on|upcoming|events|schedule|lineup|available)\b",
    ).hasMatch(t)) {
      return PpvAiIntent.listEvents;
    }

    return PpvAiIntent.unknown;
  }

  // ── Response Builder ──────────────────────────────────────────────────────

  Future<PpvAiMessage> _buildResponse(PpvAiIntent intent, String raw) async {
    switch (intent) {
      case PpvAiIntent.greeting:
        return PpvAiMessage.ai(
          text:
              "Let's go. I have the full DFC fight schedule, pricing, and fighter intel loaded.\n\nWhat do you need?",
          quickReplies: [
            "Upcoming PPV events",
            "What's live right now?",
            "Cheapest event",
            "Fighter breakdown",
          ],
        );

      case PpvAiIntent.listEvents:
        return await _handleListEvents();

      case PpvAiIntent.buyPpv:
        return await _handleBuy(raw);

      case PpvAiIntent.explainFight:
        return await _handleFighterBreakdown(raw);

      case PpvAiIntent.findByCriteria:
        return await _handleFindByCriteria(raw);

      case PpvAiIntent.getHelp:
        return _handleHelp(raw);

      case PpvAiIntent.navigate:
        return _handleNavigate(raw);

      case PpvAiIntent.unknown:
        return await _handleUnknown(raw);
    }
  }

  // ── Intent Handlers ───────────────────────────────────────────────────────

  Future<PpvAiMessage> _handleListEvents() async {
    final events = await _fetchUpcomingPpvEvents(limit: 5);
    if (events.isEmpty) {
      return PpvAiMessage.ai(
        text:
            "No upcoming PPV events are scheduled right now. Check back soon — the card drops fast.",
        quickReplies: ["What's live now?", "Help"],
      );
    }
    return PpvAiMessage.ai(
      text:
          "${events.length} upcoming events on the DFC slate. Here's the breakdown:",
      events: events,
      quickReplies: [
        "Buy the cheapest one",
        "Show only boxing",
        "What's live now?",
      ],
    );
  }

  Future<PpvAiMessage> _handleBuy(String raw) async {
    // Try to match a specific event from the query
    final events = await _fetchUpcomingPpvEvents();
    final keyword = _extractKeyword(raw);
    final matched = keyword != null
        ? events
              .where(
                (e) =>
                    e.title.toLowerCase().contains(keyword) ||
                    (e.sport ?? '').toLowerCase().contains(keyword) ||
                    (e.promotion ?? '').toLowerCase().contains(keyword),
              )
              .take(3)
              .toList()
        : events.take(3).toList();

    if (matched.isEmpty) {
      return PpvAiMessage.ai(
        text:
            "No matching events found. Here are all upcoming PPVs you can buy:",
        events: events.take(5).toList(),
        quickReplies: ["Cheapest option", "Show boxing only", "Help"],
      );
    }

    final e = matched.first;
    final price = _formatPrice(e.standardPriceCents, e.currency);
    return PpvAiMessage.ai(
      text:
          "${e.title}\n\n"
          "Price: $price\n"
          "${e.earlyBirdPriceCents != null ? 'Early Bird: ${_formatPrice(e.earlyBirdPriceCents!, e.currency)}\n' : ''}"
          "${e.description != null && e.description!.length > 120 ? '${e.description!.substring(0, 120)}…' : e.description ?? ''}\n\n"
          "Tap the card below to purchase.",
      events: matched,
      quickReplies: ["Compare other events", "What's included?", "Help"],
    );
  }

  Future<PpvAiMessage> _handleFighterBreakdown(String raw) async {
    final fighters = await _fetchFighters(raw);
    if (fighters.isEmpty) {
      return PpvAiMessage.ai(
        text:
            "I couldn't find that fighter in the DFC database. Try the full name, or ask about a specific event's fight card.",
        quickReplies: ["Show upcoming events", "Show fight card"],
      );
    }

    final f = fighters.first;
    final name = f['name'] ?? f['displayName'] ?? 'Unknown';
    final record = '${f['wins'] ?? 0}-${f['losses'] ?? 0}-${f['draws'] ?? 0}';
    final weight = f['weightClass'] ?? '';
    final org = f['organization'] ?? f['promotion'] ?? '';
    final style = f['fightingStyle'] ?? f['style'] ?? '';
    final nationality = f['nationality'] ?? f['country'] ?? '';

    final bio = StringBuffer();
    bio.write('$name\n');
    if (record != '0-0-0') bio.write('Record: $record\n');
    if (weight.isNotEmpty) bio.write('Division: $weight\n');
    if (org.isNotEmpty) bio.write('Promotion: $org\n');
    if (style.isNotEmpty) bio.write('Style: $style\n');
    if (nationality.isNotEmpty) bio.write('From: $nationality\n');

    return PpvAiMessage.ai(
      text: bio.toString().trim(),
      fighters: fighters.take(3).toList(),
      quickReplies: [
        "Show their upcoming fight",
        "Compare fighters",
        "Show events",
      ],
    );
  }

  Future<PpvAiMessage> _handleFindByCriteria(String raw) async {
    final t = raw.toLowerCase();
    final events = await _fetchUpcomingPpvEvents(limit: 20);

    List<PPVEvent> filtered = events;

    // Sport filter
    for (final sport in ['boxing', 'mma', 'bkfc', 'kickboxing', 'muay thai']) {
      if (t.contains(sport)) {
        filtered = filtered
            .where(
              (e) =>
                  (e.sport ?? '').toLowerCase().contains(sport) ||
                  e.title.toLowerCase().contains(sport) ||
                  (e.promotion ?? '').toLowerCase().contains(sport),
            )
            .toList();
        break;
      }
    }

    // Cheapest
    if (t.contains('cheapest') || t.contains('best value')) {
      filtered.sort((a, b) => a.standardPriceCents - b.standardPriceCents);
      final top = filtered.take(3).toList();
      if (top.isEmpty) {
        return PpvAiMessage.ai(
          text: "No events match those criteria right now.",
          quickReplies: ["Show all events", "What's live?"],
        );
      }
      return PpvAiMessage.ai(
        text: "Lowest price events right now:",
        events: top,
        quickReplies: ["Show most expensive", "Show all", "Buy the cheapest"],
      );
    }

    // Price ceiling — "under $X"
    final priceMatch = RegExp(r'under \$?(\d+)').firstMatch(t);
    if (priceMatch != null) {
      final ceil = int.tryParse(priceMatch.group(1) ?? '') ?? 0;
      filtered = filtered
          .where((e) => e.standardPriceCents <= ceil * 100)
          .toList();
    }

    // Live now
    if (t.contains('live now') ||
        t.contains('live tonight') ||
        t.contains('starting soon')) {
      filtered = filtered
          .where(
            (e) => e.status == PPVStatus.live || e.status == PPVStatus.onSale,
          )
          .toList();
    }

    if (filtered.isEmpty) {
      return PpvAiMessage.ai(
        text:
            "Nothing matches that filter right now. Here's everything upcoming:",
        events: events.take(5).toList(),
        quickReplies: ["Show all", "Cheapest option"],
      );
    }

    return PpvAiMessage.ai(
      text:
          "${filtered.length} event${filtered.length == 1 ? '' : 's'} match your criteria:",
      events: filtered.take(5).toList(),
      quickReplies: ["Buy the top one", "Show all events", "Narrow it down"],
    );
  }

  PpvAiMessage _handleHelp(String raw) {
    final t = raw.toLowerCase();
    String response;
    List<String> replies;

    if (t.contains('stream') ||
        t.contains("can't watch") ||
        t.contains('access')) {
      response =
          "Stream not loading? Here's the fix:\n\n"
          "1. Confirm your purchase is in My PPVs (Tab 4)\n"
          "2. Check your internet — stream needs 5+ Mbps\n"
          "3. Try refreshing the screen\n"
          "4. On mobile: force-close app, relaunch\n"
          "5. Still broken? Contact support at support@datafightcentral.com";
      replies = [
        "Go to My PPVs",
        "Contact support",
        "Help with something else",
      ];
    } else if (t.contains('receipt') || t.contains('purchase')) {
      response =
          "Your purchase receipt is emailed immediately after checkout.\n\n"
          "You can also find your PPVs in:\n"
          "PPV Hub → My PPVs (Tab 4)\n\n"
          "If nothing is there after payment, it may take up to 2 minutes to confirm.";
      replies = ["Go to My PPVs", "Contact support"];
    } else if (t.contains('cast') ||
        t.contains('chromecast') ||
        t.contains('tv')) {
      response =
          "To cast to your TV:\n\n"
          "• Android: Use the Cast icon in the player controls\n"
          "• iOS: Use AirPlay from Control Center\n"
          "• Web: Chrome → Cast tab (3-dot menu → Cast)\n\n"
          "Make sure your TV and phone are on the same Wi-Fi network.";
      replies = ["Stream isn't loading", "Contact support"];
    } else {
      response =
          "Support options:\n\n"
          "• Email: support@datafightcentral.com\n"
          "• Response time: Usually within 2 hours on event days\n"
          "• For urgent stream issues, include your purchase ID\n\n"
          "What specifically is the problem?";
      replies = ["Stream not loading", "Missing receipt", "Casting to TV"];
    }

    return PpvAiMessage.ai(text: response, quickReplies: replies);
  }

  PpvAiMessage _handleNavigate(String raw) {
    final t = raw.toLowerCase();
    String dest = 'unknown';
    // ignore: unused_local_variable
    String route = '/home';

    if (t.contains('feed') || t.contains('social')) {
      dest = 'Social Feed';
      route = '/home';
    } else if (t.contains('map') || t.contains('gym')) {
      dest = 'Gym Map';
      route = '/maps';
    } else if (t.contains('profile')) {
      dest = 'Profile';
      route = '/profile';
    } else if (t.contains('store') || t.contains('shop')) {
      dest = 'Store';
      route = '/store';
    } else if (t.contains('ppv') || t.contains('hub')) {
      dest = 'PPV Hub';
      route = '/ppv';
    }

    return PpvAiMessage.ai(
      text: dest == 'unknown'
          ? "I can take you to: Feed, Gym Map, Profile, Store, or PPV Hub. Where?"
          : "Navigating to $dest.",
      quickReplies: dest == 'unknown'
          ? ['Feed', 'Gym Map', 'Profile', 'Store']
          : ['Show me events instead', 'Stay here'],
    );
  }

  Future<PpvAiMessage> _handleUnknown(String raw) async {
    // Try to surface relevant events anyway
    final keyword = _extractKeyword(raw);
    if (keyword != null && keyword.length > 2) {
      final events = await _fetchUpcomingPpvEvents(limit: 20);
      final matched = events
          .where(
            (e) =>
                e.title.toLowerCase().contains(keyword) ||
                (e.sport ?? '').toLowerCase().contains(keyword) ||
                (e.description ?? '').toLowerCase().contains(keyword),
          )
          .take(3)
          .toList();
      if (matched.isNotEmpty) {
        return PpvAiMessage.ai(
          text: "Here's what I found related to \"$keyword\":",
          events: matched,
          quickReplies: ["Show all events", "Buy this", "Fighter breakdown"],
        );
      }
    }

    return PpvAiMessage.ai(
      text:
          "I'm built for PPV — events, fighters, pricing, and support.\n\nTry asking:",
      quickReplies: [
        "What's on this weekend?",
        "Cheapest PPV right now",
        "Tell me about a fighter",
        "I can't access my stream",
      ],
    );
  }

  // ── Firestore Queries ─────────────────────────────────────────────────────

  Future<List<PPVEvent>> _fetchUpcomingPpvEvents({int limit = 10}) async {
    try {
      final snap = await _firestore
          .collection('ppv_events')
          .where('status', whereIn: ['announced', 'presale', 'onSale', 'live'])
          .orderBy('eventDate')
          .limit(limit)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs.map(PPVEvent.fromFirestore).toList();
      }
    } catch (e) {
      debugPrint('PpvAiService._fetchUpcomingPpvEvents: $e');
    }

    // Fallback: demo events sorted by date
    return _demoFallbackEvents();
  }

  Future<List<Map<String, dynamic>>> _fetchFighters(String query) async {
    final keyword = _extractKeyword(query);
    if (keyword == null) return [];

    try {
      // Try name search (Firestore doesn't support full-text, so we do
      // a prefix query on the normalized name field if it exists)
      final snap = await _firestore
          .collection('fighters')
          .orderBy('name')
          .startAt([keyword])
          .endAt(['$keyword\uf8ff'])
          .limit(5)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      }

      // Fallback: scan first 50 and filter in memory
      final allSnap = await _firestore.collection('fighters').limit(50).get();
      return allSnap.docs
          .where(
            (d) =>
                (d.data()['name'] ?? '').toString().toLowerCase().contains(
                  keyword,
                ) ||
                (d.data()['displayName'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(keyword),
          )
          .map((d) => {'id': d.id, ...d.data()})
          .take(3)
          .toList();
    } catch (e) {
      debugPrint('PpvAiService._fetchFighters: $e');
    }
    return [];
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? _extractKeyword(String raw) {
    // Strip common question words and return the meaningful noun/name
    final cleaned = raw
        .toLowerCase()
        .replaceAll(
          RegExp(
            r'\b(tell me about|who is|show me|what about|i want|buy|purchase|find|the|a|an|me|my|the)\b',
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String _formatPrice(int cents, String currency) {
    if (cents == 0) return 'FREE';
    final symbol = switch (currency.toUpperCase()) {
      'AUD' => 'A\$',
      'USD' => '\$',
      'NZD' => 'NZ\$',
      _ => '\$',
    };
    final dollars = cents / 100;
    return '$symbol${dollars.toStringAsFixed(dollars == dollars.truncate() ? 0 : 2)}';
  }

  List<PPVEvent> _demoFallbackEvents() {
    // Minimal demo list — real data should come from Firestore
    return [
      PPVEvent(
        id: 'demo-ai-bkfc',
        eventId: 'bkfc-au-demo',
        promoterId: 'bkfc',
        title: 'BKFC AUSTRALIA',
        subtitle: 'Bare Knuckle — Melbourne Debut',
        sport: 'BKFC',
        promotion: 'BKFC',
        description: 'The bare-knuckle revolution lands in Australia.',
        eventDate: DateTime.now().add(const Duration(days: 6)),
        standardPriceCents: 3999,
        status: PPVStatus.onSale,
        createdAt: DateTime.now(),
      ),
      PPVEvent(
        id: 'demo-ai-boxing',
        eventId: 'boxing-main-demo',
        promoterId: 'dfc',
        title: 'CHAMPIONSHIP BOXING NIGHT',
        subtitle: 'World Title on the Line',
        sport: 'Boxing',
        promotion: 'DFC',
        description: 'Elite boxing as championship belts go on the line.',
        eventDate: DateTime.now().add(const Duration(days: 13)),
        standardPriceCents: 2999,
        createdAt: DateTime.now(),
      ),
    ];
  }
}
