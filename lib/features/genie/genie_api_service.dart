// lib/features/genie/genie_api_service.dart
// Genie AI API integration for card producer and other features.

import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'genie_persona.dart';
import '../../core/constants/image_assets.dart';
import '../../shared/services/samurai_service.dart';

class GenieApiResponse {
  final String name;
  final String alias;
  final String division;
  final String record;
  final String suggestedStyle;
  final String border;
  final String overlay;
  final String backgroundImageUrl;
  final String hypeText;

  GenieApiResponse({
    required this.name,
    required this.alias,
    required this.division,
    required this.record,
    required this.suggestedStyle,
    required this.border,
    required this.overlay,
    required this.backgroundImageUrl,
    required this.hypeText,
  });

  factory GenieApiResponse.fromJson(Map<String, dynamic> json) {
    return GenieApiResponse(
      name: json['name'] ?? ' + ',
      alias: json['alias'] ?? ' + ',
      division: json['division'] ?? ' + ',
      record: json['record'] ?? ' + ',
      suggestedStyle: json['suggestedStyle'] ?? ' + ',
      border: json['border'] ?? ' + ',
      overlay: json['overlay'] ?? ' + ',
      backgroundImageUrl: json['backgroundImageUrl'] ?? ' + ',
      hypeText: json['hypeText'] ?? ' + ',
    );
  }
}

class GenieApiService {
  static final SamuraiService _samurai = SamuraiService();
  static bool _samuraiInitialized = false;
  static final _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  // ── Conversation memory for smarter offline fallback ──
  static final List<String> _recentTopics = [];
  static final Set<String> _givenResponseKeys = {};
  static int _responseCycle = 0;
  static final Random _rng = Random();

  /// AI-powered creative combo suggestion via Gemini Cloud Function.
  /// Falls back to persona-specific defaults if CF unavailable.
  static Future<GenieApiResponse> generateCreativeCombo({
    Uint8List? photoBytes,
    String? description,
    GeniePersona? persona,
  }) async {
    final p = persona ?? geniePersonas.first;
    try {
      final callable = _functions.httpsCallable('generateFanEngagementPost');
      final result = await callable.call<Map<String, dynamic>>({
        'topic': description ?? 'fighter card design',
        'style': p.style,
        'platform': 'card_creator',
      });
      final post = (result.data['post'] as String?) ?? ' + ';
      if (post.isNotEmpty) {
        return GenieApiResponse(
          name: ' + ',
          alias: ' + ',
          division: ' + ',
          record: ' + ',
          suggestedStyle: p.style,
          border: 'Gold',
          overlay: 'Sparks',
          backgroundImageUrl: ImageAssets.bgAction,
          hypeText: post,
        );
      }
    } catch (_) {
      // Fall through to local defaults
    }
    return _localCreativeCombo(p);
  }

  static GenieApiResponse _localCreativeCombo(GeniePersona p) {
    final combos = {
      'shido': (
        'cinematic',
        'Steel',
        'Spotlight',
        'Give me your weight class, timeline, and condition. I will return a plan you can run today.',
      ),
      'posterboy': (
        'cyberpunk',
        'Diamond',
        'Lightning',
        'Every masterpiece starts with a blank canvas and a crazy idea.',
      ),
    };
    final c =
        combos[p.id] ??
        ('cyberpunk', 'Diamond', 'Lightning', 'Unleash the storm!');
    return GenieApiResponse(
      name: ' + ',
      alias: ' + ',
      division: ' + ',
      record: ' + ',
      suggestedStyle: c.$1,
      border: c.$2,
      overlay: c.$3,
      backgroundImageUrl: ImageAssets.bgPromo,
      hypeText: c.$4,
    );
  }

  /// AI-powered card data generation via Gemini Cloud Function.
  /// Falls back to persona-specific defaults if CF unavailable.
  static Future<GenieApiResponse> generateCardData({
    Uint8List? photoBytes,
    String? description,
    GeniePersona? persona,
  }) async {
    final p = persona ?? geniePersonas.first;
    try {
      final callable = _functions.httpsCallable('generateFighterBio');
      final result = await callable.call<Map<String, dynamic>>({
        'fighterName': description ?? 'Fighter',
        'discipline': p.style,
      });
      final bio = (result.data['bio'] as String?) ?? ' + ';
      if (bio.isNotEmpty) {
        return GenieApiResponse(
          name: description ?? 'Fighter',
          alias: 'The ${p.displayName} Protégé',
          division: 'Open Weight',
          record: ' + ',
          suggestedStyle: p.style,
          border: 'Gold',
          overlay: 'Sparks',
          backgroundImageUrl: ImageAssets.bgEvent,
          hypeText: bio.length > 120 ? '${bio.substring(0, 117)}...' : bio,
        );
      }
    } catch (_) {
      // Fall through to local defaults
    }
    return GenieApiResponse(
      name: description ?? 'Fighter',
      alias: 'The ${p.displayName} Protégé',
      division: 'Lightweight',
      record: '12-1-0',
      suggestedStyle: p.style,
      border: 'Gold',
      overlay: 'Sparks',
      backgroundImageUrl: ImageAssets.bgHero,
      hypeText: p.quote,
    );
  }

  // Chat with Genie persona
  static Future<String> askGenie(
    String question, {
    GeniePersona? persona,
    List<String>? conversationHistory,
  }) async {
    final p = persona ?? geniePersonas.first;
    final samuraiPersona = _mapToSamuraiPersona(p.id);

    // Primary path: use SamurAI service (real intelligence stack).
    try {
      if (!_samuraiInitialized) {
        await _samurai.initialize();
        _samuraiInitialized = true;
      }

      final samuraiResponse = await _samurai.chat(
        question,
        persona: samuraiPersona,
        context: {
          'source': 'genie_chat',
          'personaId': p.id,
          'personaName': p.displayName,
          'responseStyle': 'plain_human',
          'tone': 'direct_coach',
          'avoidOneLiners': true,
          'maxLength': 360,
          if (conversationHistory != null && conversationHistory.isNotEmpty)
            'recentUserMessages': conversationHistory.take(6).toList(),
        },
      );
      if (samuraiResponse.response.trim().isNotEmpty) {
        return _formatConversationalResponse(
          samuraiResponse.response,
          persona: p,
        );
      }
    } catch (e) {
      // If SamuraiService fails, use its own local fallback mechanism.
      // This avoids duplicating complex response logic in the client.
      final fallbackResponse = SamuraiResponse.localFallback(
        question,
        samuraiPersona,
      );

      if (fallbackResponse.response.trim().isNotEmpty) {
        return _formatConversationalResponse(fallbackResponse.response, persona: p);
      }
    }

    // Final, simple fallback if all other systems (including Samurai's own fallback) fail.
    return _formatConversationalResponse(
      "I'm having trouble connecting to my core intelligence right now. Please try again in a moment.",
      persona: p,
    );
  }

  static SamuraiPersona _mapToSamuraiPersona(String id) {
    switch (id) {
      case 'shido':
        return SamuraiPersona.shido;
      case 'posterboy':
        return SamuraiPersona.posterboy;
      default:
        return SamuraiPersona.shido;
    }
  }

  static String _formatConversationalResponse(
    String text, {
    required GeniePersona persona,
  }) {
    var cleaned = text.trim();

    // Tone cleanup for more natural chat.
    cleaned = cleaned
        .replaceAll('Warrior, I hear your call.', 'I hear you.')
        .replaceAll('Listen carefully, brave one.', 'Here is what I think.')
        .replaceAll('In the way of the samurai,', ' + ')
        .replaceAll('Hello warrior.', 'Hey.')
        .replaceAll('Hey warrior.', 'Hey.')
        .replaceAll('brave one', 'friend')
        .replaceAll(
          'The battle is won in the mind before it is fought in the ring.',
          'Preparation and mindset usually decide the result early.',
        )
        .replaceAll(' + ', ' + ')
        .trim();

    // Keep answers concise in default chat.
    final sentences = cleaned
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (sentences.length > 3) {
      cleaned = sentences.take(3).join(' + ');
    }

    if (cleaned.length > 360) {
      cleaned = '${cleaned.substring(0, 357)}...';
    }

    // Keep Shido concise but practical: avoid short slogan-like one-liners.
    // Only pad technical responses, not conversational ones.
    if (persona.id == 'shido' && cleaned.length < 110) {
      final lower = cleaned.toLowerCase();
      final isConversational =
          lower.contains('hey') ||
          lower.contains('what are you') ||
          lower.contains('what do you need') ||
          lower.contains('what is going on') ||
          lower.contains('i hear you') ||
          lower.contains('give me more') ||
          lower.contains('pick one') ||
          lower.contains('tell me') ||
          lower.contains('where do you want') ||
          lower.contains('got it') ||
          lower.contains('ready') ||
          lower.contains('what else') ||
          lower.contains('good') ||
          lower.contains('no worries') ||
          lower.contains('coaching brain') ||
          lower.endsWith('?');
      if (!isConversational) {
        cleaned =
            '$cleaned Next step: tell me your weight class, session type, and target date, and I will give a specific plan.';
      }
    }

    return cleaned;
  }

  static String _analyzeQuestion(String question) {
    final q = question.toLowerCase();
    if (q.contains('train') || q.contains('workout')) {
      return 'Periodization matters more than intensity. Structure sessions around one technical focus, one energy system, and always include a recovery window.';
    } else if (q.contains('fight') || q.contains('match')) {
      return 'Fight IQ starts with information gathering in the first 90 seconds. Read the opponent before committing to your A-game.';
    } else if (q.contains('fear') ||
        q.contains('nervous') ||
        q.contains('scared')) {
      return 'Pre-competition arousal is physiologically identical to excitement. The difference is cognitive framing. Use 4-2-6 breathing to regulate.';
    } else if (q.contains('lose') ||
        q.contains('lost') ||
        q.contains('defeat')) {
      return 'Post-loss protocol: review technical failures, mental lapses, and conditioning gaps separately. Pick one correction and pressure-test it in sparring.';
    } else if (q.contains('motivat') || q.contains('inspire')) {
      return 'Motivation is unreliable. Build systems: scheduled sessions, accountability partners, and micro-goals that compound into results.';
    } else if (q.contains('recover') ||
        q.contains('rest') ||
        q.contains('sleep')) {
      return 'Sleep is the primary recovery driver. 7-9 hours with consistent timing beats any supplement stack. Protein within 90 minutes post-session accelerates repair.';
    } else if (q.contains('weight') || q.contains('diet')) {
      return 'Track trend weight daily at the same time. Aim for 0.5-1% bodyweight loss per week to preserve power output. Never cut water aggressively before competing.';
    } else {
      return 'Here is what I think:';
    }
  }

  static String _buildShidoResponse(String question, String topic) {
    final q = question.toLowerCase();

    // ── Variant pools: 3-4 responses per topic, never the same twice in a row ──
    final variants = <String, List<String>>{
      'training': [
        'Training structure for today:\n' + '1) Technical block (35-45 min): pick ONE skill — single-leg takedown defense, jab-cross exit angles, or guard retention. Drill with progressive resistance.\n' + '2) Energy system block (12-18 min): intervals that match your fight pace. 3-min rounds, 1-min rest for MMA; 2-min for boxing.\n' + '3) Cooldown: 10 min mobility + box breathing (4-4-4-4).\n' + 'If sleep was under 6 hours, cap intensity at RPE 7 and skip live sparring.',
        'Here is how I would program this week:\n' + 'Mon — Technical drilling at 70% intensity. Pick your weakest position and live-drill it for 5x3-min rounds.\n' + 'Tue — Conditioning: 8-12 rounds of 30s max effort / 30s rest. Finisher: 3x60s heavy bag at fight pace.\n' + 'Wed — Active recovery. 30-min walk or light swim, 15-min stretching. Do NOT skip this.\n' + 'Thu — Sparring day. 6 rounds minimum, one round per partner if possible. Film it and review Friday morning.\n' + 'Fri — Strength: compound lifts (deadlift, squat, pull-up) at 3x5 heavy. Accessory work for grip and neck.\n' + 'Sat — Open mat or light technique. No ego, work on entries and transitions.\n' + 'Sun — Full rest. Sleep 9 hours if you can.',
        'Before your next session, answer these:\n' + '1) What specific skill broke down in your last sparring session? That is your technical focus.\n' + '2) Did you gas out, or did you have energy left? That tells me your conditioning priority.\n' + '3) Any joint pain or lingering soreness? That decides load management.\n' + 'Give me those three answers and I will build a session plan around your actual needs, not a generic template.',
        'Periodization matters more than grinding. If you are 8+ weeks from competition, you are in a general preparation phase — keep volume moderate, rotate skills, and build your aerobic base. 4 weeks out, shift to sport-specific intensity. Last 2 weeks, taper volume but keep sharpness with technique-only rounds. Most fighters overtrain in fight camp. Smart structure beats hard effort.',
      ],
      'fight': [
        'Pre-fight tactical framework:\n' + '1) First 90 seconds: information-gathering. Throw feints, test range, read their lead-hand habits and stance shifts.\n' + '2) Round 1 game plan: build around your highest-percentage entry and one safe exit. Do not overcommit early.\n' + '3) Round 2+: escalate pressure ONLY if breathing, posture, and exits remain solid.\n' + '4) Corner cues: "eyes" = reset focus, "feet" = move off center, "levels" = mix targets.\n' + 'Southpaw? Control the lead foot. Orthodox mirror? Win the jab lane.',
        'Game planning breaks down into three questions:\n' + '1) WHERE do you win? If your advantage is grappling, every exchange should end in a clinch or takedown attempt. If it is striking range, maintain distance and punish entries.\n' + '2) WHERE do they win? Actively deny that range. If they box well inside, circle and use the jab. If they wrestle, fight off the cage and keep your hips free.\n' + '3) WHEN does fatigue flip the fight? If you are better conditioned, force pace in round 2. If they fade late, survive round 1 and take over.\n' + 'This is fight IQ: making the fight happen where you are best and they are worst.',
        'Round-by-round strategy template:\n' + 'Round 1 — Data collection. Jab-feint-jab. Watch their rear hand reaction. Are they a counter fighter or a presser? Adjust by the bell.\n' + 'Round 2 — Execute A-game. If they counter, feint-and-level-change. If they press, angle out and punish with hooks as they overcommit.\n' + 'Round 3+ — Impose your will. You have the reads now. Increase volume, mix levels, and deny their best weapon. Whoever controls pace wins late rounds.\n' + 'Between rounds: 1 deep breath, 1 sip of water, 1 tactical note from your corner. Nothing else.',
      ],
      'fear': [
        'Performance anxiety protocol:\n' + '1) Physiological sigh: 2 quick inhales through nose, 1 long exhale through mouth. 6 reps. Downregulates sympathetic activation faster than box breathing.\n' + '2) Reframe: "I am nervous" → "my body is preparing." The hormonal profile is identical.\n' + '3) Anchor cue: pick one specific action for the first exchange. Focus process, not outcome.\n' + '4) Warm up to a light sweat 20 min before. Cold muscles amplify anxiety signals.',
        'Fear before a fight is your nervous system doing its job. The issue is not the fear — it is what you do with the adrenaline dump. Here is the protocol:\n' + '1) Exhale-dominant breathing: 4-count in, 7-count out. Do 10 cycles. This shifts your nervous system from fight-or-flight to ready-and-focused.\n' + '2) Narrow your focus to the next 30 seconds. Not the fight. Not the result. Just the first technique you will throw.\n' + '3) Move. Shadow-box, pace backstage, shake out your limbs. A still body amplifies nervous energy. Moving body converts it to readiness.\n' + 'You are not scared. You are loaded.',
        'Every fighter feels it. The ones who look calm are not fearless — they have practiced managing arousal under pressure. You build this skill:\n' + '1) In training: simulate fight-day conditions. Walk-out music, crowd noise app, full warm-up routine, timed rounds with strangers watching.\n' + '2) In sparring: practice composure drills. Your partner hits you clean — instead of firing back wildly, reset feet, breathe, and answer with technique.\n' + '3) Pre-fight: write down your 3-step opening sequence on a card. Read it 10 min before walkout. It gives your brain a checklist instead of spiraling.\n' + 'Courage is not absence of fear. It is executing your plan while the fear is there.',
      ],
      'loss': [
        'Post-loss analysis framework:\n' + '1) Technical: 2-3 recurring failures — were they getting past your lead hand? Overreaching on entries?\n' + '2) Tactical: did your game plan hold, or did you abandon structure under pressure?\n' + '3) Physical: gas tank, chin, grip strength by round 3 — which degraded first?\n' + '4) Mental: where did composure break? What triggered it?\n' + 'Pick ONE correction. Drill it under fatigue for 2 weeks before re-evaluating.',
        'A loss is data, not a verdict. Here is how you extract value:\n' + '1) Watch the fight footage twice — once for emotion (let yourself feel it), once with a notebook (be clinical).\n' + '2) Mark the moment the fight shifted. Was it a specific exchange, a positional error, or a conditioning drop?\n' + '3) Ask your coach: "if I changed ONE thing, what would have the biggest impact?" Not five things. One.\n' + '4) Build your next 3-week training block around that single correction.\n' + 'Losses are expensive lessons. Do not waste them by moving on too quickly.',
        'Losing hurts. That is normal and healthy — it means you care. But here is the framework for moving forward:\n' + 'Week 1 — Debrief: film review, honest conversation with your team, identify the top failure point.\n' + 'Week 2 — Rebuild: high-volume drilling of the specific skill that failed. No sparring yet.\n' + 'Week 3 — Pressure test: controlled sparring focused specifically on the corrected area.\n' + 'After week 3, you have turned a loss into a permanent improvement. Then you decide: was it a skills problem, a preparation problem, or a matchmaking problem? Each has a different solution.',
      ],
      'recovery': [
        'Recovery science protocol:\n' + '1) Sleep: 7-9 hours, consistent bed/wake times. HGH peaks during deep sleep — timing and reaction speed depend on it.\n' + '2) Nutrition: 25-40g protein within 90 min post-session. Carbs to replenish glycogen.\n' + '3) Active recovery: 20-30 min walk or yoga on rest days.\n' + '4) Monitor: track morning resting HR. 5+ bpm above baseline = fatigue, scale back.\n' + '5) No hard sessions after less than 6 hours sleep. Injury risk climbs 60%+.',
        'Recovery is not passive. It is the other half of adaptation. Here is the hierarchy:\n' + '1) Sleep quality > sleep quantity. Dark room, cool temp, no screen 30 min before bed, consistent time.\n' + '2) Nutrition timing: post-session protein + carb meal within 90 min. Pre-bed casein or cottage cheese for overnight muscle protein synthesis.\n' + '3) Nervous system management: after heavy sparring, your CNS needs 48-72 hours. Do not stack two sparring days. Fill the gaps with technical drilling or conditioning.\n' + '4) Soft tissue: foam roll quads, lats, IT band for 5 min post-session. Weekly massage or self-myofascial release.\n' + 'If you are training hard but not recovering harder, you are just accumulating fatigue, not building fitness.',
        'You asked about recovery, so let me check: are you actually resting, or are you doing "active recovery" that is really just more training? Common traps:\n' + '1) "Light sparring" on rest days — this is not rest, your CNS is still firing.\n' + '2) Skipping sleep for conditioning — you are trading your best recovery tool for your worst return.\n' + '3) Ignoring persistent soreness — if a joint hurts for 5+ days, see a physio. Do not train through it.\n' + 'Real recovery protocol: 1 true rest day per week minimum. 8 hours sleep non-negotiable. 0.5g/kg bodyweight in protein at 4 meals across the day.',
      ],
      'weight': [
        'Weight management protocol:\n' + '1) Track trend weight daily (same time, post-bathroom). 7-day moving average is your real weight.\n' + '2) Target 0.5-1% bodyweight loss per week to preserve power.\n' + '3) Protein floor: 1.6-2.2g/kg. Non-negotiable during cuts.\n' + '4) Fight week: gradual water loading 5 days out. Never panic-cut more than 3% via dehydration.\n' + '5) Post-weigh-in: sip electrolytes, eat digestible carbs, recheck 2 hours before fight.',
        'Weight cuts go wrong when fighters leave it too late. Here is the timeline:\n' + '8 weeks out — Weigh yourself daily. Calculate the gap. If it is over 8% of target, you may need to move up a class.\n' + '6 weeks out — Caloric deficit of 300-500 kcal/day. Keep protein high, drop fats slightly, keep carbs around training sessions.\n' + '2 weeks out — You should be within 3-5% of target. Fine-tune with sodium and water manipulation.\n' + 'Fight week — Water load Mon-Wed (1.5x normal intake), then taper Thu-Fri. Sauna only as last resort, max 30 min total.\n' + 'Weigh-in morning — You made weight or you did not. If you are still 2%+ over, the cut was mismanaged. Learn for next time.',
        'Quick question before I build your weight plan: where are you at right now, and what is your target? The approach changes:\n' + '- 2-3 kg over: diet adjustment only, no water cut needed.\n' + '- 4-6 kg over: 4-6 week structured deficit + mild water manipulation fight week.\n' + '- 7+ kg over with 4+ weeks: aggressive cut required. Needs nutritionist involvement.\n' + '- 7+ kg over with less than 4 weeks: seriously consider moving up a weight class.\n' + 'Cutting weight badly wrecks performance more than carrying an extra kilo. I would rather you fight sharp at 155 than depleted at 145.',
      ],
      'cardio': [
        'Combat conditioning protocol:\n' + '1) Aerobic base: 2-3 sessions/week, 30-45 min steady-state (HR 130-150). This builds the engine.\n' + '2) Anaerobic capacity: 1-2 sessions/week. 30s max effort, 30s rest, 8-12 rounds.\n' + '3) Sport-specific: heavy bag or grappling circuits at fight pace.\n' + '4) Do NOT replace skill work with conditioning. Tired + sharp technique beats fresh + sloppy.',
        'If you are gassing in rounds, the problem is usually one of three things — and the fix is different for each:\n' + '1) Low aerobic base: you cannot recover between bursts. Fix: 3x per week, 30-40 min conversational-pace running or cycling. Build this over 6-8 weeks.\n' + '2) Inefficient technique: you are muscling through techniques instead of using leverage. Fix: slow drilling, relaxation cues, breathing during grappling exchanges.\n' + '3) Adrenaline dump: your nervous system is redlining from stress, not effort. Fix: controlled sparring, gradually increasing intensity. Simulate competition conditions in training.\n' + 'Which one sounds like you? Tell me and I will give you the specific protocol.',
        'Here is a 4-week conditioning block that works alongside your skill training:\n' + 'Week 1-2 — Base building: 3x 30 min steady-state (run, bike, swim) + 1x interval session (6x 3-min rounds at 75% HR max, 1 min rest).\n' + 'Week 3 — Intensity shift: drop steady-state to 2x, add 2x sport-specific intervals (heavy bag Tabata: 20s on/10s off, 8 rounds, 3 sets).\n' + 'Week 4 — Fight simulation: 2x full fight-pace sessions (rounds matching your competition format), 1x recovery session.\n' + 'The key: never sacrifice skill sessions for conditioning. If you only have 4 days to train, give 3 to skill and 1 to conditioning. Fitness without fight IQ is just cardio.',
      ],
      'injury': [
        'Injury management framework:\n' + '1) Distinguish DOMS (diffuse, 24-72h, improves with movement) from injury (sharp, localized, worsens with specific movement).\n' + '2) DOMS: train through it at lighter loads.\n' + '3) Acute injury: RICE for 48h, then gradual loading. See a physio if it lasts 5+ days.\n' + '4) Train around it: shoulder issue = work legs; knee issue = upper body.\n' + '5) Never spar with an injury affecting your defensive movement.',
        'The biggest mistake fighters make with injuries: training through pain that changes movement patterns. A sore muscle is fine. A joint that makes you compensate is dangerous. Here is the decision tree:\n' + 'Can you shadow-box at full speed without guarding the area? → Train with reduced contact.\n' + 'Does the pain change your stance or footwork? → No sparring. Technical drilling only.\n' + 'Is it worse after sleep? → Possible inflammation or structural issue. Get imaging.\n' + 'Has it persisted 7+ days without improvement? → See a sports physio. Do not self-diagnose.\n' + 'In the meantime, train everything that does not aggravate it. Injuries are a chance to build the parts of your game you have been neglecting.',
        'Tell me specifically: what hurts, where, and when did it start? I need three things to give you a real answer:\n' + '1) Location and type of pain (sharp, aching, burning, clicking).\n' + '2) What movements make it worse (punching, weight-bearing, rotation).\n' + '3) How long it has been like this.\n' + 'Generic injury advice is useless. I need your specifics to tell you what you can and cannot train through, and how to modify your program.',
      ],
      'mental': [
        'Mental performance framework:\n' + '1) Confidence from evidence: log training outputs — rounds, techniques landed, sparring notes. Review before competition.\n' + '2) Focus training: one cue per round in sparring (e.g., "lead hand active") to train selective attention.\n' + '3) Self-talk audit: replace "I am gassing" with "heavy breathing, adjust pace." Factual language reduces emotional hijacking.\n' + '4) Visualization: 5-10 min daily. See yourself executing your game plan, not winning.',
        'Mindset is trainable, not innate. Here is the progression:\n' + 'Level 1 — Awareness: start noticing your self-talk during hard rounds. Write it down after training. Most fighters have no idea what they are saying to themselves.\n' + 'Level 2 — Reframing: when you catch a negative thought ("he is better than me"), replace it with a task ("move my feet, reset distance"). Process focus beats outcome focus.\n' + 'Level 3 — Pre-performance routine: build a 3-step ritual you do before every round — breathe, touch gloves, pick one technical focus. This anchors you when pressure rises.\n' + 'Level 4 — Post-failure protocol: when you get hit clean or lose a scramble, what is your recovery action? Train a specific reset (e.g., clinch, circle out, hands up) so the response is automatic.',
        'The mental game comes down to this: what happens in the 2 seconds after something goes wrong. Get hit clean? Lose position? Gas out? The gap between the problem and your response is where fights are won and lost.\n' + 'Build automatic resets:\n' + '1) After taking a hard shot: hands up, circle away from power hand, reset at range. Drill this 50 times per session until it is reflex.\n' + '2) After losing position in grappling: inside control (underhook or wrist), hip escape, rebuild guard. No panic movement.\n' + '3) After gassing: clinch, control pace, force a reset. Use the ref break if needed.\n' + 'Champions do not avoid adversity. They have practiced the exact response to it.',
      ],
      'mobility': [
        'Mobility and warm-up protocol:\n' + '1) Pre-session: dynamic movement only — leg swings, hip circles, arm circles, light shadow. 8-12 min.\n' + '2) Static stretching AFTER training. Never before explosive work — reduces power output temporarily.\n' + '3) Priority areas: hip flexors, thoracic spine, ankles, shoulder external rotation.\n' + '4) Foam roll pre-session: 2-3 min on tight areas. Not a replacement for stretching.',
        'Most combat athletes are tight in 3 areas that directly limit their game:\n' + '1) Hip flexors: tight hips kill your guard retention in grappling and your kick height in striking. Fix: couch stretch 2x60s per side, daily.\n' + '2) Thoracic extension: rounded upper back limits head movement and makes you easier to break down in clinch. Fix: foam roller extensions, 2x15 reps.\n' + '3) Ankle dorsiflexion: limited ankle range forces wide stances and kills lateral movement. Fix: banded ankle mobilizations, 2x30s per side.\n' + 'Spend 10 minutes on these three areas daily and you will move measurably better within 2 weeks.',
      ],
      // ── Conversational responses ──
      'greeting': [
        'Hey. What are you working on right now? Training, fight prep, recovery — give me a direction and I will give you something useful.',
        'What is going on. Tell me where you are at — camp, off-season, coming back from a break? I will tailor everything to your situation.',
        'Good to see you. What do you need today? I have got training plans, fight strategy, recovery protocols, weight management, mental prep — pick one or describe what is on your mind.',
        'Hey. I am ready when you are. What is the priority right now?',
      ],
      'meta': [
        'I am Samurai Shido — the coaching brain behind DataFightCentral. I handle training structure, fight strategy, recovery science, weight management, conditioning, mental performance, injury rehab, and mobility. I am not a chatbot giving you motivational quotes. Give me specifics and I will give you a plan.',
        'Yes, I have a brain. I am built to coach combat athletes across every discipline — MMA, boxing, kickboxing, Muay Thai, BJJ, wrestling, bare knuckle. I work with real periodization, real sport science, and real fight IQ. What do you need?',
        'I am an AI fight coach. I know training programming, fight analysis, cutting weight, recovery timing, and mental preparation. I do not do small talk well, but I will outwork any coach on specifics. Try me.',
        'Think of me as a sports scientist who also watches tape. I cover the full spectrum — from your warm-up to your game plan to your post-fight recovery. Ask me something real and see what I come back with.',
      ],
      'frustration': [
        'Fair enough. I hear the frustration. Let me be more useful — tell me one specific thing you need help with right now. Training, weight, fight prep, recovery, mental game. Pick one and I will deliver.',
        'I get it. Let me cut the rubbish. What is the actual problem you are trying to solve? Give me the situation and I will give you the answer.',
        'Noted. I will skip the generic stuff. Tell me exactly what is going wrong — your training, your fight, your body, your head — and I will give you something you can actually use.',
        'Alright, let us reset. I am here to solve problems, not waste your time. What do you need?',
      ],
      'appreciation': [
        'Good. Now let us build on that. What is the next thing you want to work on?',
        'Glad that landed. What else do you need? I am here until you are sorted.',
        'No worries. That is what I am here for. What is next on the list?',
      ],
      'help': [
        'Here is what I can do:\n' + '1) Training programming — periodization, session structure, skill vs conditioning balance\n' + '2) Fight strategy — game plans, opponent analysis frameworks, round-by-round tactics\n' + '3) Weight management — cut protocols, nutrition timing, rehydration\n' + '4) Recovery — sleep, deload weeks, active recovery, overtraining detection\n' + '5) Conditioning — aerobic base, anaerobic intervals, fight-specific cardio\n' + '6) Mental performance — pre-fight anxiety, focus training, post-loss protocols\n' + '7) Injury management — training modifications, return-to-training decisions\n' + '8) Mobility — warm-up protocols, flexibility priorities for combat athletes\n' + 'Pick a number or describe your situation and I will take it from there.',
        'Tell me what you are dealing with and I will figure out the right approach. The more specific you are, the more useful I can be. "I need to cut 5kg in 3 weeks" beats "help me with weight."',
        'I work best with context. Tell me: what are you training for, when is it, and what is the weakest link right now? I will build from there.',
      ],
      'yesno': [
        'Got it. What specifically do you want to dig into next?',
        'OK. Give me more detail and I will work with it. What is on your mind?',
        'Right. Tell me more — I need context to give you something useful.',
        'Copy that. Where do you want to go from here?',
      ],
    };

    // Pick a response from the matched topic pool, avoiding recent duplicates
    final pool = variants[topic];
    if (pool != null && pool.isNotEmpty) {
      // Find an unused variant first
      for (int i = 0; i < pool.length; i++) {
        final idx = (_responseCycle + i) % pool.length;
        final key = '${topic}_$idx';
        if (!_givenResponseKeys.contains(key)) {
          _givenResponseKeys.add(key);
          // Cycle reset: when all variants used, clear so they can repeat
          if (_givenResponseKeys.where((k) => k.startsWith(topic)).length >=
              pool.length) {
            _givenResponseKeys.removeWhere((k) => k.startsWith(topic));
          }
          return pool[idx];
        }
      }
      // All used recently — just rotate
      return pool[_responseCycle % pool.length];
    }

    // ── Context-aware generic fallback ──
    return _buildContextualFallback(q);
  }

  /// Detect conversational topic from user input
  static String _detectTopic(String question) {
    final q = question.toLowerCase();
    if (q.contains('train') ||
        q.contains('workout') ||
        q.contains('spar') ||
        q.contains('drill') ||
        q.contains('session') ||
        q.contains('program')) {
      return 'training';
    }
    if (q.contains('fight') ||
        q.contains('match') ||
        q.contains('opponent') ||
        q.contains('game plan') ||
        q.contains('strategy') ||
        q.contains('round')) {
      return 'fight';
    }
    if (q.contains('fear') ||
        q.contains('nervous') ||
        q.contains('anxious') ||
        q.contains('scared') ||
        q.contains('panic')) {
      return 'fear';
    }
    if (q.contains('lost') ||
        q.contains('lose') ||
        q.contains('defeat') ||
        q.contains('beaten')) {
      return 'loss';
    }
    if (q.contains('sleep') ||
        q.contains('recover') ||
        q.contains('rest') ||
        q.contains('fatigue') ||
        q.contains('overtraining')) {
      return 'recovery';
    }
    if (q.contains('weight') ||
        q.contains('diet') ||
        q.contains('cut') ||
        q.contains('nutrition') ||
        q.contains('calorie') ||
        q.contains('eat')) {
      return 'weight';
    }
    if (q.contains('cardio') ||
        q.contains('conditioning') ||
        q.contains('gas') ||
        q.contains('endurance') ||
        q.contains('stamina')) {
      return 'cardio';
    }
    if (q.contains('injur') ||
        q.contains('pain') ||
        q.contains('hurt') ||
        q.contains('sore') ||
        q.contains('broken') ||
        q.contains('torn')) {
      return 'injury';
    }
    if (q.contains('mental') ||
        q.contains('focus') ||
        q.contains('confidence') ||
        q.contains('mindset') ||
        q.contains('psychology') ||
        q.contains('head')) {
      return 'mental';
    }
    if (q.contains('stretch') ||
        q.contains('flex') ||
        q.contains('mobil') ||
        q.contains('warm')) {
      return 'mobility';
    }
    // ── Conversational / meta topics ──
    if (q.contains('hello') ||
        q.contains('hey') ||
        q.contains('hi ') ||
        q.contains('sup') ||
        q.contains('yo ') ||
        q.contains('g\'day') ||
        q.contains('what\'s up') ||
        q.contains('howdy') ||
        q.contains('awake') ||
        q.contains('u there') ||
        q.contains('you there') ||
        q == 'hi' ||
        q == 'yo' ||
        q == 'sup' ||
        q == 'wat' ||
        q == 'wut' ||
        q == 'huh' ||
        q == 'oi') {
      return 'greeting';
    }
    if (q.contains('brain') ||
        q.contains('real') ||
        q.contains('alive') ||
        q.contains('are you') ||
        q.contains('who are') ||
        q.contains('what are') ||
        q.contains('can you') ||
        q.contains('do you') ||
        q.contains('how old') ||
        q.contains('who made') ||
        q.contains('what do you')) {
      return 'meta';
    }
    if (q.contains('fuk') ||
        q.contains('fuck') ||
        q.contains('shit') ||
        q.contains('useless') ||
        q.contains('stupid') ||
        q.contains('suck') ||
        q.contains('trash') ||
        q.contains('garbage') ||
        q.contains('terrible') ||
        q.contains('awful') ||
        q.contains('worst') ||
        q.contains('hate') ||
        q.contains('dumb') ||
        q.contains('idiot') ||
        q.contains('crap')) {
      return 'frustration';
    }
    if (q.contains('thank') ||
        q.contains('cheers') ||
        q.contains('nice one') ||
        q.contains('legend') ||
        q.contains('awesome') ||
        q.contains('perfect') ||
        q.contains('brilliant') ||
        q.contains('sick')) {
      return 'appreciation';
    }
    if (q.contains('help') ||
        q.contains('what can') ||
        q.contains('how do') ||
        q.contains('tell me') ||
        q.contains('explain') ||
        q.contains('show me')) {
      return 'help';
    }
    if (q.length < 8 &&
        (q.contains('yes') ||
            q.contains('yeah') ||
            q.contains('yep') ||
            q.contains('nah') ||
            q.contains('no') ||
            q.contains('nope') ||
            q.contains('ok'))) {
      return 'yesno';
    }
    return 'general';
  }

  /// Context-aware fallback when no topic keywords match — uses recent
  /// conversation topics to build a meaningful response instead of a
  /// generic "give me three specifics" every time.
  static String _buildContextualFallback(String q) {
    // If we have prior topics, build on them
    if (_recentTopics.length >= 2) {
      final lastTopic = _recentTopics[_recentTopics.length - 2];
      final followUps = <String, String>{
        'training':
            'Based on what we covered about training — how did the last session go? Tell me what worked and what felt off, and I will adjust the plan.',
        'fight':
            'Following up on fight strategy — do you have a specific opponent or are you building a general game plan? The approach is different.',
        'fear':
            'Regarding what we discussed about nerves — have you tried the breathing protocol yet? If the anxiety is happening outside of competition too, that is worth addressing separately.',
        'loss':
            'On the loss we talked about — have you re-watched the footage? I want to know the specific moment it turned.',
        'recovery':
            'On recovery — what does your current sleep schedule actually look like? Be honest. I need real numbers to help.',
        'weight':
            'Following up on weight management — what are you eating this week? Give me yesterday as an example: meals, timing, and approximate portions.',
        'cardio':
            'About the conditioning work — when you gas out, does it feel like a breathing problem (lungs) or a muscle fatigue problem (legs heavy)? That tells me which energy system to target.',
        'injury':
            'On the injury — has it improved, stayed the same, or gotten worse since we talked? And have you seen a physio?',
        'mental':
            'Building on the mental game discussion — are you logging your self-talk during sparring? That one habit changes everything.',
        'mobility':
            'On mobility — are you doing the stretches daily or just when you remember? Consistency matters more than duration.',
      };
      if (followUps.containsKey(lastTopic)) {
        return followUps[lastTopic]!;
      }
    }

    // Rotate through probing questions that pull useful info from the user
    final probes = [
      'I want to help, but I need context. Tell me: (1) what you are training for right now, (2) how far out your next event is, (3) what is currently the weakest part of your game. Those three things shape everything.',
      'Give me three specifics: your goal, your current condition (fitness, injuries, recent training load), and your timeline. I will return a day-by-day or round-by-round structure you can execute immediately.',
      'What is the one thing in your preparation that keeps you up at night? Is it fitness, technique, weight, nerves, or something else? Start there and I will break it down.',
      'Here is what I can help with: training programming, fight strategy, weight management, recovery protocols, mental preparation, conditioning, injury management, and mobility. Pick one, or tell me what is on your mind and I will figure out the right lane.',
      'Quick check: where are you at right now in your camp or training cycle? Early preparation, mid-camp, fight week, or off-season? The advice changes depending on where you are.',
    ];
    return probes[_responseCycle % probes.length];
  }
}

