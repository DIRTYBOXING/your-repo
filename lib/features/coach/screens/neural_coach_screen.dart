import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/router_config.dart' as rc;

/// ═══════════════════════════════════════════════════════════════════════════
/// NEURAL COACH — DFC Neural Engine v3.0
///
/// The bridge between Human, Smart Device & AI.
/// Built on applied sport science:
///   Training · Energy Systems · Biomechanics · Motor Behaviour
///
/// ARCHITECTURE (The Simple Process):
///
///   ┌──────────┐        ┌───────────┐        ┌──────────┐
///   │  HUMAN   │◄──────►│  DEVICES  │◄──────►│    AI    │
///   │ (Athlete)│  data  │(Watches)  │  feed  │ (Coach)  │
///   └──────────┘        └───────────┘        └──────────┘
///        │                    │                    │
///        └────────────────────┼────────────────────┘
///                             │
///                    ┌────────▼────────┐
///                    │  COACH STONE    │
///                    │  NEURAL ENGINE  │
///                    └─────────────────┘
///
/// SECTIONS:
///  1. Stone Performance Map — Full-size radar chart (readable!)
///  2. Coach Voice — Coach Stone speaks to you
///  3. Neural Brain — Animated data hub
///  4. Biometric Live Feed — HR · HRV · Sleep · Stress (LIVE)
///  5. Behavioral Intelligence — Pattern analysis
///  6. Predictive Timeline — Past → Present → Future
///  7. Coach Action Cards — Today's priorities
///  8. Connection Triangle — Human ↔ Device ↔ AI
///  9. Device Hub — Connected smart devices
/// 10. SEO Signal — Fighter visibility
///
/// Zero third-party chart packages. 100% CustomPaint.
/// Live biometric simulation. Intelligent coaching engine.
/// ═══════════════════════════════════════════════════════════════════════════

// ═════════════════════════════════════════════════════════════════════════════
// COACH STONE NEURAL ENGINE — The brain behind the coach
// ═════════════════════════════════════════════════════════════════════════════

class _CoachStoneEngine {
  static final _rand = math.Random();

  /// Time-aware greeting in Coach Stone style
  static String greeting(int hour) {
    if (hour < 6) {
      return [
        'You\'re up before the sun. That\'s what separates you.',
        'This is the hour nobody sees. This is where champions are made.',
        'While they sleep, you build. I respect that.',
      ][_rand.nextInt(3)];
    } else if (hour < 10) {
      return [
        'Good morning, kid. Let\'s get to work.',
        'Rise and conquer. Your body\'s ready — I checked the numbers.',
        'Morning warrior. I\'ve been watching your vitals all night.',
      ][_rand.nextInt(3)];
    } else if (hour < 14) {
      return [
        'Midday check. Your metrics are talking to me.',
        'Stay sharp. The afternoon is where discipline lives.',
        'Listen to me carefully. Your body is sending signals.',
      ][_rand.nextInt(3)];
    } else if (hour < 18) {
      return [
        'Afternoon debrief. Let\'s look at the data.',
        'The day\'s not over. There\'s still work to be done.',
        'Training window is open. Your HRV says go.',
      ][_rand.nextInt(3)];
    } else if (hour < 22) {
      return [
        'Evening debrief. Let\'s review the numbers.',
        'Day\'s almost done. Recovery starts now.',
        'Wind down, warrior. Tomorrow we go again.',
      ][_rand.nextInt(3)];
    } else {
      return [
        'Get some rest, kid. Sleep is a weapon.',
        'The fight is tomorrow. Tonight, you recover.',
        'Shut it down. Your body needs this.',
      ][_rand.nextInt(3)];
    }
  }

  /// Biometric-driven coaching insight
  static String biometricInsight({
    required int heartRate,
    required int restingHR,
    required double hrv,
    required double sleepHours,
    required int sleepQuality,
    required int stressIndex,
    required int recoveryScore,
    required double vo2Max,
  }) {
    // Priority-based analysis — most critical issue first
    if (stressIndex > 70) {
      return 'Listen to me — stress index at $stressIndex is a red flag. '
          'Your cortisol is sabotaging your recovery. I don\'t care what the schedule says, '
          'today is active recovery only. Cold water, breathing exercises, easy movement. '
          'HRV is at ${hrv.toStringAsFixed(0)}ms — that confirms what I\'m seeing.';
    }
    if (sleepHours < 6.0) {
      return 'Only ${sleepHours.toStringAsFixed(1)} hours of sleep. That\'s not enough for a fighter. '
          'Your HRV dropped to ${hrv.toStringAsFixed(0)}ms because of it. Sleep quality at $sleepQuality%. '
          'You\'re running on borrowed energy. No heavy sparring today — I won\'t let you get hurt. '
          'Tonight: phone down by 9, dark room, 8 hours minimum.';
    }
    if (recoveryScore < 50) {
      return 'Recovery score: $recoveryScore%. That\'s below threshold. '
          'Resting HR at $restingHR bpm is elevated above your baseline. '
          'Your body is still paying the debt from yesterday. Light technique work only. '
          'Hydrate aggressively — 4L minimum. Trust the process.';
    }
    if (recoveryScore > 85 && hrv > 55) {
      return 'Green light across the board. Recovery at $recoveryScore%, HRV strong at '
          '${hrv.toStringAsFixed(0)}ms, resting HR steady at $restingHR bpm. '
          'This is your day to push. High-intensity rounds, sparring, conditioning — '
          'your body can handle it. VO₂ max holding at ${vo2Max.toStringAsFixed(1)}. '
          'Let\'s make this count.';
    }
    if (stressIndex < 25 && sleepQuality > 85) {
      return 'Stress at $stressIndex, sleep quality $sleepQuality%. You\'re in the zone, kid. '
          'Heart rate resting at $restingHR bpm. HRV at ${hrv.toStringAsFixed(0)}ms. '
          'This is optimal territory. Moderate-to-high intensity training recommended. '
          'Focus on technique refinement and power output.';
    }
    return 'Vitals check: HR $heartRate bpm, resting $restingHR, HRV ${hrv.toStringAsFixed(0)}ms. '
        'Sleep ${sleepHours.toStringAsFixed(1)}h at $sleepQuality% quality. '
        'Stress index $stressIndex, recovery $recoveryScore%. '
        'Moderate training zone. I\'m monitoring every metric — trust the engine.';
  }

  /// Motivational fire based on training load
  static String motivation(int trainingLoad, int recoveryScore) {
    if (trainingLoad > 90) {
      return 'Training load at $trainingLoad% — you\'re in the red zone. '
          'I see a warrior who doesn\'t quit, but I also see a coach who knows when to pull the reins. '
          'Champions are smart. Deload tomorrow. That\'s not a request.';
    }
    if (trainingLoad > 75) {
      return '$trainingLoad% load. This is where the magic happens — right at the edge. '
          'Not too much, not too little. Champions live in this zone. '
          'Recovery\'s at $recoveryScore% so we\'re managing the balance. Keep pushing.';
    }
    if (trainingLoad < 40) {
      return 'Training load: $trainingLoad%. Let me be straight with you — '
          'the cage doesn\'t care about comfort zones. Your opponents are working right now. '
          'Recovery\'s at $recoveryScore%, your body is ready. Get in the gym. '
          'The difference between a champ and a chump is U.';
    }
    return 'Optimal training load: $trainingLoad%. Consistent effort beats raw talent '
        'every single time. Recovery holding at $recoveryScore%. '
        'Stay the course. I\'m here tracking every rep, every breath, every heartbeat.';
  }

  /// Rotating wisdom from the Atlas philosophy — 40 real combat truths
  static String wisdom() {
    final wisdoms = [
      // ORIGINAL ATLAS PHILOSOPHY
      'The body achieves what the mind believes. Your data confirms what your discipline built.',
      'There are no shortcuts. The numbers don\'t lie. Put in the work.',
      'I\'ve watched thousands of fighters. The ones who win listen — to their body, to their data, to their coach.',
      'Fear is like fire. It can cook for you or it can burn you. Use it.',
      'Your heart rate tells me your fitness. Your discipline tells me your character.',
      'The fight is won or lost far away from witnesses. In the gym, in the dark, when nobody\'s watching.',
      'Every metric I track is a letter in the story of your body. Read it. Learn it. Master it.',
      'Talent is God-given. Be humble. Fame is man-given. Be grateful. Conceit is self-given. Be careful.',
      'The biometrics show me who you are today. Your choices show me who you\'ll be tomorrow.',
      'Sleep, stress, recovery — these aren\'t just numbers. They\'re the language your body speaks. I translate.',
      // FIGHTING FUNDAMENTALS — REAL TRUTH
      'The jab is the most important punch in boxing. It sets everything up. Master the jab, master the fight.',
      'Footwork is the foundation. You can\'t throw what you can\'t reach, and you can\'t avoid what you can\'t move from.',
      'Keep your chin down and your hands up. The punch you don\'t see is the one that drops you.',
      'Breathe out when you punch. Holding your breath burns energy and tightens your muscles. Stay loose.',
      'Distance management wins fights. If you control the space between you and your opponent, you control the fight.',
      'Always return your hands to your face after every punch. Lazy hands get you knocked out.',
      'The double jab changes fights. First jab finds range, second jab finds the target.',
      'In the clinch, fight for inside position. Underhooks beat overhooks every time.',
      'Don\'t load up on every punch. Speed and accuracy beat power if power can\'t find the target.',
      'Circle away from the power hand. Against an orthodox fighter, move to your left. Against a southpaw, move right.',
      // RING GENERALSHIP & STRATEGY
      'Cut the ring off, don\'t chase. Walk your opponent into the ropes using angles, not speed.',
      'Body shots are investments. They pay off in the later rounds when the legs go.',
      'Never fight angry. Emotion clouds judgment. Stay technical, stay cold, stay disciplined.',
      'The best defense is making your opponent miss by inches, not miles. Small movements save energy.',
      'Feints win fights at the highest level. Make them react to what isn\'t there, then punish what\'s open.',
      'Combinations end fights, single shots start them. Think in threes: jab-cross-hook, jab-body-head.',
      'Rounds are won in the last 30 seconds. Judges remember what they saw most recently. Finish strong.',
      'Study your opponent\'s patterns. Everyone has a tell. Find it, time it, exploit it.',
      'Recovery between rounds is a skill. Breathe deep from the belly, not the chest. Slow the heart down.',
      'The best fighters make adjustments mid-fight. Read, adapt, overcome. That\'s fighting IQ.',
      // MENTAL GAME & DISCIPLINE
      'Your legs go before your heart does. Condition from the ground up — roadwork, squats, stairs.',
      'Consistency beats intensity. Training hard once means nothing. Training smart every day means everything.',
      'Visualization is real training. See the fight in your mind before you step in the ring. Your brain can\'t tell the difference.',
      'You don\'t rise to the occasion, you fall to the level of your training. Train the way you want to fight.',
      'Sparring is practice, not war. The goal is to learn, not to win in the gym. Save the war for fight night.',
      'A fighter who doesn\'t study film is a fighter who doesn\'t want to win badly enough.',
      'Pain is temporary. Regret is permanent. Push through the moment — it\'s shorter than you think.',
      'Respect every opponent. Underestimating someone is the fastest way to get caught.',
      'Champions have the discipline to do what they don\'t feel like doing, when they don\'t feel like doing it.',
      'The gym doesn\'t lie. Put in honest work, get honest results. Cut corners, and the fight exposes you.',
    ];
    // Rotate based on day of year for consistency within a day
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year))
        .inDays;
    return wisdoms[dayOfYear % wisdoms.length];
  }

  /// TECHNIQUE OF THE DAY — rotating real fighting fundamentals
  static Map<String, String> techniqueOfTheDay() {
    final techniques = [
      {
        'name': 'THE JAB',
        'category': 'STRIKING',
        'detail':
            'Extend from the shoulder, not the elbow. Snap it — don\'t push it. '
            'Turn your fist over at full extension. Return the hand faster than you threw it. '
            'The jab is your rangefinder, your setup, your defense, and your scoring punch. '
            'Throw it from your stance without leaning forward. Weight stays centered.',
      },
      {
        'name': 'THE CROSS',
        'category': 'STRIKING',
        'detail':
            'Power comes from the ground up — push off the back foot, rotate the hip, '
            'then the torso, then fire the hand. The whole body is behind this punch. '
            'Keep the lead hand protecting the chin. Don\'t drop the right shoulder before throwing — that\'s a telegraph. '
            'Pivot the back foot like you\'re putting out a cigarette.',
      },
      {
        'name': 'LEAD HOOK',
        'category': 'STRIKING',
        'detail':
            'Rotate on the ball of the lead foot. The arm stays at 90 degrees — don\'t extend it. '
            'Power comes from hip rotation, not the arm swing. Palm can face down (traditional) or inward (thumb up). '
            'This is the knockout punch. It comes from the blind side and it doesn\'t have to travel far.',
      },
      {
        'name': 'UPPERCUT',
        'category': 'STRIKING',
        'detail':
            'Dip slightly, bend the knees, then drive UPWARD from the legs. The fist rises inside their guard. '
            'Don\'t wind up — that\'s a telegraph. Short, sharp, and inside. Works best in the pocket. '
            'Lead uppercut sets up the rear hook. Rear uppercut is for when they lean forward.',
      },
      {
        'name': 'STANCE & GUARD',
        'category': 'DEFENSE',
        'detail':
            'Feet shoulder-width apart, lead foot forward at 45 degrees. Back foot on the ball. '
            'Knees slightly bent — you should be able to move instantly in any direction. '
            'Hands up, elbows in, chin down. Your lead hand is at eyebrow height, rear hand touching your cheek. '
            'Stay relaxed. Tension drains energy. Be ready, not rigid.',
      },
      {
        'name': 'HEAD MOVEMENT',
        'category': 'DEFENSE',
        'detail':
            'Slip to the OUTSIDE of punches — move your head just enough to make them miss. '
            'Inches, not feet. Roll under hooks by bending at the knees, not the waist. '
            'Pull straight back from jabs but snap right back to position. Never stay in one place — '
            'a moving target is harder to hit. Head movement is offense disguised as defense.',
      },
      {
        'name': 'FOOTWORK BASICS',
        'category': 'MOVEMENT',
        'detail':
            'Push off the opposite foot to the direction you want to move. Going forward? Push with the back foot. '
            'Going back? Push with the front. Lateral? Push with the opposite side foot. '
            'Never cross your feet. Never let your feet come together — maintain your base at all times. '
            'Stay on the balls of your feet. Flat-footed fighters are slow fighters.',
      },
      {
        'name': 'PIVOTING',
        'category': 'MOVEMENT',
        'detail':
            'The pivot creates angles. Plant the lead foot and swing the back foot like a compass. '
            'After throwing a combination, pivot off the center line so you\'re no longer where they expect. '
            'The pivot turns defense into offense — you evade AND reposition to attack simultaneously. '
            'Practice pivoting after every jab until it\'s automatic.',
      },
      {
        'name': 'BODY PUNCHING',
        'category': 'STRATEGY',
        'detail':
            'Go to the body early and often. The liver shot (left hook to the right side of the body) is a fight-ender. '
            'Dig the punches up and under the elbow. Bend your knees to get below their elbows. '
            'Body punching slows the opponent, drops their hands, and kills their legs. '
            'It\'s an investment — the payoff comes in rounds 4, 5, 6 when they can\'t breathe.',
      },
      {
        'name': 'COUNTER PUNCHING',
        'category': 'STRATEGY',
        'detail':
            'The counter comes from timing, not speed. Wait for them to commit, then punish the opening. '
            'Slip their jab and throw the cross. Pull back from the cross and fire the counter cross. '
            'Catch their hook with the glove and return your own. Every attack creates a vulnerability — see it. '
            'The best counter punchers make opponents afraid to throw. That\'s control.',
      },
      {
        'name': 'BREATHING',
        'category': 'CONDITIONING',
        'detail':
            'Exhale sharply on every punch — the "tss" sound. Inhale between combinations. '
            'Never hold your breath during exchanges — you\'ll gas out in seconds. '
            'Between rounds: deep belly breaths, in through the nose, out through the mouth. '
            'Controlled breathing is the difference between lasting 3 rounds and lasting 12.',
      },
      {
        'name': 'LEG KICKS (MMA)',
        'category': 'STRIKING',
        'detail':
            'Turn the hip over completely. Strike with the shin, not the foot — 2 inches above the ankle. '
            'Target the outside of the thigh, just above the knee. Step at a 45-degree angle to the outside before throwing. '
            'Low kicks destroy mobility. After 4-5 clean leg kicks, they can\'t plant to punch. '
            'Always bring the leg back fast — a caught kick means a takedown.',
      },
      {
        'name': 'TAKEDOWN DEFENSE',
        'category': 'GRAPPLING',
        'detail':
            'Sprawl hard and FAST when you see the level change. Hips down, chest on their back, legs away. '
            'Keep your hands free — don\'t let them lock their hands. Overhook one arm and whizzer hard. '
            'Against a single leg: hop to the side, whizzer the arm, and push their head down. '
            'The best takedown defense is making them pay every time they try.',
      },
      {
        'name': 'CLINCH FIGHTING',
        'category': 'GRAPPLING',
        'detail':
            'In the clinch, inside position wins. Swim for underhooks. Control the head and posture. '
            'In Muay Thai: double collar tie, pull their head down, fire knees through the middle. '
            'In MMA: underhook + overhook = control. Use the cage as a weapon — pin them and work. '
            'Don\'t be passive in the clinch. Short punches, elbows, knees — always be working.',
      },
      // ── GROUND GAME ──
      {
        'name': 'GUARD RETENTION',
        'category': 'GROUND GAME',
        'detail':
            'Hips are everything on the bottom. Keep your hips angled, never flat on your back. '
            'Frame on the bicep and hip to create distance. Re-guard with a hip escape (shrimp) — '
            'bridge to create space, shrimp to insert a knee, recover guard. '
            'Grip fight constantly: if they control your wrists, break grips immediately. Active guard beats passive guard.',
      },
      {
        'name': 'MOUNT ESCAPES',
        'category': 'GROUND GAME',
        'detail':
            'Trap-and-roll (upa): trap the arm and same-side foot, bridge at 45 degrees to reverse. '
            'Elbow-knee escape: frame on the hip, shrimp to half guard, then recover full guard. '
            'These two escapes cover 90% of mount situations. Drill them until they are reflexive. '
            'Stay calm — panicking burns energy and opens submissions.',
      },
      {
        'name': 'BACK CONTROL & ESCAPES',
        'category': 'GROUND GAME',
        'detail':
            'When you have the back: seatbelt grip (over-under the arms), hooks in, head on the choking side. '
            'When escaping: protect the neck first (chin down, hands fighting grips), slide hips to the mat '
            'toward the underhook side, turn into them to recover guard. '
            'Fight the hands before the hooks. Grip breaks save your neck.',
      },
      // ── ENERGY SYSTEMS ──
      {
        'name': 'AEROBIC BASE',
        'category': 'ENERGY SYSTEMS',
        'detail':
            'The aerobic system fuels recovery between bursts — it is the engine underneath everything. '
            'Build it with 30-45 min steady-state work at 130-150 bpm HR (Zone 2). Running, cycling, swimming. '
            '2-3 sessions per week minimum. A strong aerobic base lets you recover faster between rounds, '
            'between exchanges, and between training sessions. It is the most undertrained energy system in combat sports.',
      },
      {
        'name': 'ANAEROBIC LACTIC',
        'category': 'ENERGY SYSTEMS',
        'detail':
            'This system powers sustained high-intensity efforts (30s-2min). It produces lactate as a byproduct. '
            'Train it with: 30s all-out / 30s rest intervals (8-12 rounds), heavy bag Tabata, '
            'or grappling rounds at competition pace. '
            'Buffering capacity (tolerance to lactate burn) improves with training. '
            'If you gas in the middle of rounds, this is the system to target.',
      },
      {
        'name': 'ALACTIC POWER',
        'category': 'ENERGY SYSTEMS',
        'detail':
            'The ATP-PCr system fuels explosive bursts under 10 seconds — knockout power, level changes, scrambles. '
            'Train it with: 5-8s maximal sprints with 60-90s full recovery, or explosive compound lifts (power clean, jump squat). '
            'Full recovery between sets is critical — this system requires complete phosphocreatine replenishment. '
            'This is the first system to fatigue in a fight and the fastest to recover if your aerobic base is strong.',
      },
      // ── BIOMECHANICS ──
      {
        'name': 'KINETIC CHAIN',
        'category': 'BIOMECHANICS',
        'detail':
            'Punching power is sequential: ground → ankle → knee → hip → core → shoulder → fist. '
            'Each segment accelerates the next. A break in the chain (dropping the shoulder, flat-footed stance) '
            'kills power transfer. The hip rotation generates ~40% of punch force. '
            'Train the chain: medicine ball rotational throws, cable woodchops, and plyometric push-ups.',
      },
      {
        'name': 'MUSCLE FIRING PATTERNS',
        'category': 'BIOMECHANICS',
        'detail':
            'Efficient striking requires proper muscle activation sequence: agonist fires, antagonist relaxes. '
            'Stiffness (co-contraction) is the enemy of speed. Stay relaxed until the moment of impact, '
            'then tense through the target. This is called the "snap" — loose-tight-loose. '
            'Slow drilling at low intensity builds these patterns. Speed comes from relaxation, not effort.',
      },
      // ── MOTOR BEHAVIOUR ──
      {
        'name': 'MOTOR LEARNING STAGES',
        'category': 'MOTOR BEHAVIOUR',
        'detail':
            'Stage 1 (Cognitive): you consciously think about each step. Drill slowly with clear cues. '
            'Stage 2 (Associative): movements become smoother. Add light resistance and timing. '
            'Stage 3 (Autonomous): technique is automatic under pressure. Test it in live sparring. '
            'Rushing to Stage 3 without sufficient reps in Stages 1-2 builds fragile skills that break under stress.',
      },
      {
        'name': 'VARIABILITY TRAINING',
        'category': 'MOTOR BEHAVIOUR',
        'detail':
            'Practicing a technique identically every rep builds a narrow motor program. '
            'Instead, vary the context: different angles, different partners, different fatigue levels. '
            'This builds adaptable, robust motor patterns that transfer to unpredictable fight conditions. '
            'After 100 identical reps, do 50 with random variations. Your body learns to self-organize.',
      },
      {
        'name': 'REACTION & ANTICIPATION',
        'category': 'MOTOR BEHAVIOUR',
        'detail':
            'Pure reaction time (~200ms) cannot be significantly trained. But anticipation can. '
            'Elite fighters read postural cues 100-200ms before a strike lands — the hip turn, the shoulder dip, the weight shift. '
            'Train this with pattern-recognition drills: partner throws set combos, you identify and respond to the opener. '
            'Film study accelerates anticipation — you learn to read tells before you see them live.',
      },
    ];
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year))
        .inDays;
    return techniques[dayOfYear % techniques.length];
  }

  /// TRUTH BOMBS — hard real talk about fighting
  static String truthBomb() {
    final truths = [
      'You don\'t need talent to work hard. You need discipline. Get up. Show up. Do the work.',
      'Your opponent is training right now. While you scroll your phone, someone who wants to beat you is putting in rounds.',
      'There\'s no cheat code in fighting. The ring exposes everything — your preparation, your cardio, your heart, your weakness.',
      'If you\'re not drilling fundamentals every single session, you\'re building a house on sand. Fancy moves mean nothing without basics.',
      'Most fighters lose because they didn\'t prepare properly, not because the other guy was better. Preparation is everything.',
      'You will get hit. Accept that. The question is: what do you do after you get hit? Champions answer back.',
      'Your diet IS your training. You can\'t outwork a bad diet. What you eat today shows up in the ring next month.',
      'Skipping roadwork because you hate running is like skipping the foundation because you want to build the roof first.',
      'The mirror lies. Sparring tells the truth. Film tells the truth. Your coach tells the truth. Listen.',
      'If you can\'t control your emotions in the gym, you won\'t control them in the fight. Practice composure with the same intensity you practice combinations.',
      'Recovery isn\'t laziness. It\'s where adaptation happens. Rest days make you stronger. Overtraining makes you injured.',
      'The fighters who make excuses and the fighters who make progress don\'t live in the same world. Choose your world.',
    ];
    final index = DateTime.now().hour ~/ 2; // Changes every 2 hours
    return truths[index % truths.length];
  }

  /// FUNDAMENTAL PRINCIPLE — core fighting concept breakdown
  static Map<String, String> fundamentalPrinciple() {
    final principles = [
      {
        'title': 'DISTANCE MANAGEMENT',
        'core': 'Control the space between you and your opponent.',
        'detail':
            'There are 3 ranges: kicking range (outside), punching range (mid), '
            'and clinch range (inside). Know which range favors YOU and fight to keep it there. '
            'If you\'re a long fighter, use the jab to keep distance. If you\'re a brawler, cut angles to close it.',
      },
      {
        'title': 'RING GENERALSHIP',
        'core': 'Make the ring work for you, not against you.',
        'detail':
            'Stay in the center whenever possible — it gives you options in all directions. '
            'Push your opponent to the ropes or corners using footwork and pressure, not chasing. '
            'When you\'re on the ropes, pivot immediately. Never stay there.',
      },
      {
        'title': 'TIMING OVER SPEED',
        'core': 'A well-timed punch beats a fast punch every time.',
        'detail':
            'Timing means throwing when they\'re in the process of another action — when they\'re throwing, '
            'resetting, or breathing. Speed is genetic. Timing is learned. Study the rhythm, break the pattern, exploit the opening.',
      },
      {
        'title': 'ECONOMY OF MOTION',
        'core': 'Don\'t waste movement. Every action should have a purpose.',
        'detail':
            'Wide punches travel further and are easier to see. Tight punches land faster. '
            'Don\'t bounce excessively. Don\'t over-feint. Small, precise movements conserve energy '
            'and keep you ready to fire at any moment.',
      },
      {
        'title': 'ANGLES OF ATTACK',
        'core': 'Don\'t fight in a straight line. Create angles.',
        'detail':
            'Step to the side before or after combinations. Attack from positions where they can\'t fire back easily. '
            'A slight pivot after a jab puts you offline while leaving your cross in range. '
            'Angles create openings that don\'t exist when you\'re squared up.',
      },
      {
        'title': 'PRESSURE FIGHTING',
        'core': 'Break their will with relentless, intelligent pressure.',
        'detail':
            'Pressure doesn\'t mean running forward throwing wild hooks. It means constantly walking forward behind a jab, '
            'cutting off the ring, working the body, and never giving them a moment to breathe or think. '
            'Pressure fighters win because the opponent eventually panics.',
      },
      {
        'title': 'THE 3-PUNCH RULE',
        'core': 'Always throw in combinations of AT LEAST three.',
        'detail':
            'Single punches are easy to read and defend. Two punches make contact. Three punches overwhelm. '
            'The third punch in a combination is statistically the most likely to land clean. '
            'Drill combos until they\'re automatic: 1-2-3, 1-1-2, 1-2-3-2, 2-3-2.',
      },
    ];
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year))
        .inDays;
    return principles[(dayOfYear ~/ 2) % principles.length];
  }

  /// Generate daily protocol based on biometric state
  static List<_ProtocolItem> dailyProtocol({
    required int stressIndex,
    required int recoveryScore,
    required double sleepHours,
    required int sleepQuality,
    required double hrv,
    required int trainingLoad,
  }) {
    final items = <_ProtocolItem>[];

    // Morning protocol
    if (sleepHours < 7) {
      items.add(
        _ProtocolItem(
          priority: '1',
          title: 'Extended Morning Mobility',
          detail:
              'Sleep debt detected (${sleepHours.toStringAsFixed(1)}h). 20-min gentle mobility to activate without overstressing.',
          icon: Icons.self_improvement,
          color: AppColors.neonGreen,
        ),
      );
    } else {
      items.add(
        _ProtocolItem(
          priority: '1',
          title: 'Dynamic Warm-Up Protocol',
          detail:
              'Sleep quality $sleepQuality% — morning activation ready. 15-min dynamic stretching + shadow work.',
          icon: Icons.self_improvement,
          color: AppColors.neonGreen,
        ),
      );
    }

    // Hydration
    items.add(
      _ProtocolItem(
        priority: '2',
        title: 'Hydration Target: ${stressIndex > 50 ? "4.2L" : "3.5L"}',
        detail:
            'Stress index at $stressIndex${stressIndex > 50 ? " — increased water intake required" : " — standard hydration protocol"}. Electrolytes post-training.',
        icon: Icons.water_drop,
        color: AppColors.neonCyan,
      ),
    );

    // Training recommendation
    if (recoveryScore > 80 && hrv > 50) {
      items.add(
        _ProtocolItem(
          priority: '3',
          title: 'High-Intensity Training (60 min)',
          detail:
              'Recovery $recoveryScore%, HRV ${hrv.toStringAsFixed(0)}ms — cleared for hard work. Sparring + conditioning.',
          icon: Icons.sports_martial_arts,
          color: AppColors.neonRed,
        ),
      );
    } else if (recoveryScore > 60) {
      items.add(
        _ProtocolItem(
          priority: '3',
          title: 'Technique Drilling (45 min)',
          detail:
              'Moderate recovery ($recoveryScore%). Focus on skill refinement, pad work, and controlled rounds.',
          icon: Icons.sports_martial_arts,
          color: AppColors.neonOrange,
        ),
      );
    } else {
      items.add(
        _ProtocolItem(
          priority: '3',
          title: 'Active Recovery Session',
          detail:
              'Recovery at $recoveryScore% — pushing hard today risks injury. Light bag work + stretching.',
          icon: Icons.healing,
          color: AppColors.neonPurple,
        ),
      );
    }

    // Evening recovery
    items.add(
      _ProtocolItem(
        priority: '4',
        title: 'Evening Recovery Protocol',
        detail:
            'Target sleep: ${sleepHours < 7 ? "8.5h+" : "8h"}. Cold immersion, stretching, devices will track overnight metrics.',
        icon: Icons.nights_stay,
        color: AppColors.neonPurple,
      ),
    );

    return items;
  }
}

class _ProtocolItem {
  final String priority, title, detail;
  final IconData icon;
  final Color color;
  const _ProtocolItem({
    required this.priority,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// NEURAL COACH SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class NeuralCoachScreen extends StatefulWidget {
  const NeuralCoachScreen({super.key});

  @override
  State<NeuralCoachScreen> createState() => _NeuralCoachScreenState();
}

class _NeuralCoachScreenState extends State<NeuralCoachScreen>
    with TickerProviderStateMixin {
  // ─── Animation Controllers ───
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _flowCtrl;
  late AnimationController _entranceCtrl;
  late Animation<double> _brainFade;
  late Animation<double> _feedSlide;
  late Animation<double> _cardsScale;

  // ─── Live Data Timer ───
  Timer? _dataTimer;
  StreamSubscription<Map<String, dynamic>?>? _aiInsightsSub;
  final _rand = math.Random();

  // ─── LIVE Biometric Data (mutable — updated by Neural Engine) ───
  int _heartRate = 62;
  final int _restingHR = 58;
  double _hrv = 48.0;
  final double _sleepHours = 7.2;
  final int _sleepQuality = 82;
  int _stressIndex = 34;
  final int _recoveryScore = 78;
  final double _vo2Max = 52.3;
  int _spo2 = 98;
  double _bodyTemp = 36.6;
  final int _trainingLoad = 72;
  int _respiratoryRate = 14;
  int _caloriesBurned = 1840;

  // ─── Neural Engine State ───
  String _coachGreeting = '';
  String _coachInsight = '';
  String _coachMotivation = '';
  String _atlasWisdom = '';
  String _truthBomb = '';
  Map<String, String> _techniqueOfDay = {};
  Map<String, String> _fundamentalPrinciple = {};
  List<_ProtocolItem> _protocol = [];
  int _engineCycles = 0;
  int _dataPointsProcessed = 0;

  // ─── Atlas Radar Dimensions ───
  final List<double> _radarValues = [0.82, 0.65, 0.78, 0.91, 0.54, 0.73];
  final List<String> _radarLabels = [
    'STRIKING',
    'MENTAL',
    'SLEEP',
    'NUTRITION',
    'STRESS MGT',
    'RECOVERY',
  ];

  @override
  void initState() {
    super.initState();

    // Pulse — neural network ambient
    _pulseCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    // Waveform — heartbeat ECG
    _waveCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Flow — data particles
    _flowCtrl = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Entrance choreography
    _entranceCtrl = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..forward();

    _brainFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _feedSlide = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOutCubic),
    );
    _cardsScale = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOutBack),
    );

    // Boot the Coach Stone Neural Engine
    _bootNeuralEngine();

    // Start live biometric data stream
    _startLiveDataStream();
  }

  /// Boot the Neural Engine — generate all coaching content
  void _bootNeuralEngine() {
    final hour = DateTime.now().hour;
    _coachGreeting = _CoachStoneEngine.greeting(hour);
    _coachInsight = _CoachStoneEngine.biometricInsight(
      heartRate: _heartRate,
      restingHR: _restingHR,
      hrv: _hrv,
      sleepHours: _sleepHours,
      sleepQuality: _sleepQuality,
      stressIndex: _stressIndex,
      recoveryScore: _recoveryScore,
      vo2Max: _vo2Max,
    );
    _coachMotivation = _CoachStoneEngine.motivation(
      _trainingLoad,
      _recoveryScore,
    );
    _atlasWisdom = _CoachStoneEngine.wisdom();
    _truthBomb = _CoachStoneEngine.truthBomb();
    _techniqueOfDay = _CoachStoneEngine.techniqueOfTheDay();
    _fundamentalPrinciple = _CoachStoneEngine.fundamentalPrinciple();
    _protocol = _CoachStoneEngine.dailyProtocol(
      stressIndex: _stressIndex,
      recoveryScore: _recoveryScore,
      sleepHours: _sleepHours,
      sleepQuality: _sleepQuality,
      hrv: _hrv,
      trainingLoad: _trainingLoad,
    );
    _engineCycles = 1;
    _dataPointsProcessed = 12;
  }

  /// Live biometric simulation — makes the feed feel ALIVE
  void _startLiveDataStream() {
    _dataTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        // Heart rate micro-fluctuation (±3 BPM)
        _heartRate = (62 + (_rand.nextDouble() * 6 - 3)).round().clamp(55, 75);

        // HRV natural variance (±4ms)
        _hrv = (48.0 + _rand.nextDouble() * 8 - 4).clamp(38.0, 62.0);

        // Stress index slow drift (±2)
        _stressIndex = (_stressIndex + _rand.nextInt(5) - 2).clamp(20, 55);

        // SpO2 narrow range
        _spo2 = [97, 98, 98, 99, 98][_rand.nextInt(5)];

        // Body temp tiny variance
        _bodyTemp = (36.6 + (_rand.nextDouble() * 0.4 - 0.2));

        // Respiratory rate
        _respiratoryRate = [13, 14, 14, 15, 14][_rand.nextInt(5)];

        // Calories tick up
        _caloriesBurned += _rand.nextInt(3);

        // Engine telemetry
        _engineCycles++;
        _dataPointsProcessed += _rand.nextInt(4) + 1;

        // Subtle radar pulse
        for (int i = 0; i < _radarValues.length; i++) {
          final base = [0.82, 0.65, 0.78, 0.91, 0.54, 0.73][i];
          _radarValues[i] = (base + (_rand.nextDouble() * 0.04 - 0.02)).clamp(
            0.0,
            1.0,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _aiInsightsSub?.cancel();
    _dataTimer?.cancel();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _flowCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseCtrl,
          _waveCtrl,
          _flowCtrl,
          _entranceCtrl,
        ]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background: Neural network
              CustomPaint(
                painter: _NeuralNetworkPainter(
                  phase: _pulseCtrl.value,
                  flowPhase: _flowCtrl.value,
                ),
              ),

              // Vignette overlay
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 1.4,
                    colors: [
                      Colors.transparent,
                      AppColors.bg.withValues(alpha: 0.5),
                      AppColors.bg.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(child: _buildHeader()),

                    // Quick nav to related screens
                    SliverToBoxAdapter(child: _buildCoachQuickNav()),

                    // 1. STONE PERFORMANCE MAP — The big radar
                    SliverToBoxAdapter(child: _buildAtlasPerformanceMap()),

                    // 2. COACH VOICE — Coach Stone speaks
                    SliverToBoxAdapter(child: _buildCoachVoice()),

                    // 3. STONE WISDOM — Daily quote
                    SliverToBoxAdapter(child: _buildAtlasWisdom()),

                    // 3.5. TECHNIQUE OF THE DAY — Real fighting knowledge
                    SliverToBoxAdapter(child: _buildTechniqueOfDay()),

                    // 3.6. STONE TRUTH — Hard real talk
                    SliverToBoxAdapter(child: _buildAtlasTruth()),

                    // 3.7. FIGHTING FUNDAMENTAL — Core concept
                    SliverToBoxAdapter(child: _buildFightingFundamental()),

                    // 4. NEURAL BRAIN — Data hub visualization
                    SliverToBoxAdapter(child: _buildCoachBrain()),

                    // 5. BIOMETRIC LIVE FEED — Real-time vitals
                    SliverToBoxAdapter(child: _buildBiometricFeed()),

                    // 6. BEHAVIORAL INTELLIGENCE — Trend analysis
                    SliverToBoxAdapter(child: _buildBehavioralIntel()),

                    // 7. PREDICTIVE TIMELINE — Past → Present → Future
                    SliverToBoxAdapter(child: _buildPredictiveTimeline()),

                    // 8. COACH PROTOCOL — Today's priorities
                    SliverToBoxAdapter(child: _buildCoachProtocol()),

                    // 9. CONNECTION TRIANGLE — Human ↔ Device ↔ AI
                    SliverToBoxAdapter(child: _buildConnectionTriangle()),

                    // 10. DEVICE HUB — Connected devices
                    SliverToBoxAdapter(child: _buildDeviceHub()),

                    // 11. ENGINE TELEMETRY — Neural Engine status
                    SliverToBoxAdapter(child: _buildEngineTelemetry()),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEURAL COACH',
                  style: TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'COACH STONE ENGINE v3.0',
                      style: TextStyle(
                        color: AppColors.neonRed.withValues(alpha: 0.5),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• $_engineCycles cycles',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Live status
          _StatusDot(
            color: AppColors.neonGreen,
            label: 'LIVE',
            phase: _pulseCtrl.value,
          ),
        ],
      ),
    );
  }

  Widget _buildCoachQuickNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _coachNavChip(
            'Fight Camp',
            Icons.fitness_center,
            Colors.amber,
            rc.RouteConstants.fightCampToolsPath,
          ),
          const SizedBox(width: 8),
          _coachNavChip(
            'Health',
            Icons.monitor_heart,
            AppColors.neonMagenta,
            rc.RouteConstants.healthDashboardPath,
          ),
          const SizedBox(width: 8),
          _coachNavChip(
            'Devices',
            Icons.watch,
            AppColors.neonGreen,
            rc.RouteConstants.deviceHubPath,
          ),
          const SizedBox(width: 8),
          _coachNavChip(
            'Body',
            Icons.accessibility_new,
            AppColors.neonCyan,
            rc.RouteConstants.bodyMonitorPath,
          ),
        ],
      ),
    );
  }

  Widget _coachNavChip(String label, IconData icon, Color color, String route) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. ATLAS PERFORMANCE MAP — Full-size readable radar
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAtlasPerformanceMap() {
    return FadeTransition(
      opacity: _brainFade,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            // Section header with engine badge
            Row(
              children: [
                _sectionLabel('ATLAS PERFORMANCE MAP', AppColors.neonMagenta),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.neonMagenta.withValues(alpha: 0.08),
                    border: Border.all(
                      color: AppColors.neonMagenta.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonMagenta,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonMagenta.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ATLAS ENGINE',
                        style: TextStyle(
                          color: AppColors.neonMagenta.withValues(alpha: 0.7),
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // THE RADAR — big, readable, beautiful
            _GlassPanel(
              accent: AppColors.neonMagenta,
              child: Column(
                children: [
                  SizedBox(
                    height: 320,
                    child: CustomPaint(
                      size: const Size(double.infinity, 320),
                      painter: _AtlasRadarPainter(
                        phase: _pulseCtrl.value,
                        values: _radarValues,
                        labels: _radarLabels,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Legend row
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RadarLegendDot('Strong (>80%)', AppColors.neonGreen),
                      SizedBox(width: 16),
                      _RadarLegendDot('Moderate', AppColors.neonMagenta),
                      SizedBox(width: 16),
                      _RadarLegendDot(
                        'Focus Area (<60%)',
                        AppColors.neonOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Coach ATLAS has analyzed your behavioral patterns across 6 dimensions.\n'
                    'Areas below 60% are flagged for targeted protocol adjustment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. COACH VOICE — Coach Stone speaks
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCoachVoice() {
    return FadeTransition(
      opacity: _brainFade,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: _GlassPanel(
          accent: AppColors.neonCyan,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting with voice indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonRed.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.neonRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: AppColors.neonRed,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COACH ATLAS',
                          style: TextStyle(
                            color: AppColors.neonRed.withValues(alpha: 0.5),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          _coachGreeting,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Biometric Insight
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.neonCyan.withValues(alpha: 0.04),
                  border: Border(
                    left: BorderSide(
                      color: AppColors.neonCyan.withValues(alpha: 0.4),
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.insights,
                      color: AppColors.neonCyan.withValues(alpha: 0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BIOMETRIC ANALYSIS',
                            style: TextStyle(
                              color: AppColors.neonCyan.withValues(alpha: 0.5),
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _coachInsight,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Motivation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.neonRed.withValues(alpha: 0.04),
                  border: Border(
                    left: BorderSide(
                      color: AppColors.neonRed.withValues(alpha: 0.4),
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: AppColors.neonRed.withValues(alpha: 0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MOTIVATION',
                            style: TextStyle(
                              color: AppColors.neonRed.withValues(alpha: 0.5),
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _coachMotivation,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. ATLAS WISDOM — Daily rotating quote
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAtlasWisdom() {
    return FadeTransition(
      opacity: _brainFade,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.neonRed.withValues(alpha: 0.06),
                AppColors.neonMagenta.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(
              color: AppColors.neonRed.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '❝',
                style: TextStyle(
                  color: AppColors.neonRed.withValues(alpha: 0.4),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 0.8,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _atlasWisdom,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '— ATLAS NEURAL ENGINE',
                      style: TextStyle(
                        color: AppColors.neonRed.withValues(alpha: 0.35),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3.5. TECHNIQUE OF THE DAY — Real fighting knowledge
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTechniqueOfDay() {
    if (_techniqueOfDay.isEmpty) return const SizedBox.shrink();
    return ScaleTransition(
      scale: _cardsScale,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('TECHNIQUE OF THE DAY', AppColors.neonRed),
            const SizedBox(height: 12),
            _GlassPanel(
              accent: AppColors.neonRed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Technique header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.neonRed.withValues(alpha: 0.15),
                          border: Border.all(
                            color: AppColors.neonRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _techniqueOfDay['category'] ?? '',
                          style: const TextStyle(
                            color: AppColors.neonRed,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonRed.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DAILY ROTATION',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Technique name — big and bold
                  Row(
                    children: [
                      Icon(
                        Icons.sports_mma,
                        color: AppColors.neonRed.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _techniqueOfDay['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Divider line
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.neonRed.withValues(alpha: 0.3),
                          AppColors.neonRed.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Technique detail — real instruction
                  Text(
                    _techniqueOfDay['detail'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Coach note
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.neonRed.withValues(alpha: 0.05),
                      border: Border.all(
                        color: AppColors.neonRed.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.neonRed.withValues(alpha: 0.5),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'COACH TIP: Drill this technique 50 times on each side today. '
                            'Slow first, then build speed. Perfect form > raw power.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 10,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3.6. ATLAS TRUTH — Hard coaching truths
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAtlasTruth() {
    return FadeTransition(
      opacity: _brainFade,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.neonAmber.withValues(alpha: 0.08),
                AppColors.neonOrange.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(
              color: AppColors.neonAmber.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bolt,
                    color: AppColors.neonAmber.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ATLAS TRUTH',
                    style: TextStyle(
                      color: AppColors.neonAmber.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: AppColors.neonAmber.withValues(alpha: 0.1),
                    ),
                    child: const Text(
                      'NO EXCUSES',
                      style: TextStyle(
                        color: AppColors.neonAmber,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _truthBomb,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.neonAmber.withValues(alpha: 0.4),
                      AppColors.neonAmber.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TRUTH ROTATES EVERY 2 HOURS — THERE\'S ALWAYS A LESSON',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3.7. FIGHTING FUNDAMENTAL — Core concept breakdown
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFightingFundamental() {
    if (_fundamentalPrinciple.isEmpty) return const SizedBox.shrink();
    return ScaleTransition(
      scale: _cardsScale,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('FIGHTING FUNDAMENTAL', AppColors.neonGreen),
            const SizedBox(height: 12),
            _GlassPanel(
              accent: AppColors.neonGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Principle title
                  Text(
                    _fundamentalPrinciple['title'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Core concept — one-liner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.neonGreen.withValues(alpha: 0.08),
                      border: Border.all(
                        color: AppColors.neonGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: AppColors.neonGreen.withValues(alpha: 0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _fundamentalPrinciple['core'] ?? '',
                            style: TextStyle(
                              color: AppColors.neonGreen.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Detailed breakdown
                  Text(
                    _fundamentalPrinciple['detail'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Application reminder
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Apply this in your next training session. '
                          'Understanding is step one. Application is where growth happens.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. NEURAL BRAIN — Animated network hub
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCoachBrain() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(_feedSlide),
      child: FadeTransition(
        opacity: _feedSlide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            children: [
              _sectionLabel('NEURAL NETWORK', AppColors.neonCyan),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _CoachBrainPainter(
                    pulse: _pulseCtrl.value,
                    flow: _flowCtrl.value,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Coach identity
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonCyan,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'COACH ATLAS',
                    style: TextStyle(
                      color: AppColors.neonCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'v3.0 • Neural Engine Active',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. BIOMETRIC LIVE FEED — Real-time vitals
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBiometricFeed() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(_feedSlide),
      child: FadeTransition(
        opacity: _feedSlide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _sectionLabel('BIOMETRIC LIVE FEED', AppColors.neonGreen),
                  const Spacer(),
                  _StatusDot(
                    color: AppColors.neonGreen,
                    label: 'STREAMING',
                    phase: _pulseCtrl.value,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Heart rate + ECG waveform
              _GlassPanel(
                accent: AppColors.neonRed,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Pulsing heart icon
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (context, child) {
                            final scale =
                                1.0 +
                                math.sin(_pulseCtrl.value * math.pi * 2) * 0.15;
                            return Transform.scale(
                              scale: scale,
                              child: const Icon(
                                Icons.favorite,
                                color: AppColors.neonRed,
                                size: 16,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'HEART RATE',
                          style: TextStyle(
                            color: AppColors.neonRed.withValues(alpha: 0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        // Live heart rate with animated value
                        Text(
                          '$_heartRate',
                          style: const TextStyle(
                            color: AppColors.neonRed,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          ' BPM',
                          style: TextStyle(
                            color: AppColors.neonRed.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: CustomPaint(
                        size: const Size(double.infinity, 60),
                        painter: _HeartbeatPainter(
                          phase: _waveCtrl.value,
                          bpm: _heartRate,
                        ),
                      ),
                    ),
                    // Resting HR baseline info
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'RESTING: $_restingHR BPM',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'ZONE: ${_heartRate < 65
                              ? "REST"
                              : _heartRate < 75
                              ? "LIGHT"
                              : "ACTIVE"}',
                          style: TextStyle(
                            color: AppColors.neonRed.withValues(alpha: 0.4),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Metric grid — all live
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _LiveMetricTile(
                    'RESTING HR',
                    '$_restingHR',
                    'bpm',
                    AppColors.neonRed,
                    Icons.monitor_heart,
                    true,
                  ),
                  _LiveMetricTile(
                    'HRV',
                    _hrv.toStringAsFixed(0),
                    'ms',
                    AppColors.neonCyan,
                    Icons.timeline,
                    true,
                  ),
                  _LiveMetricTile(
                    'SLEEP',
                    _sleepHours.toStringAsFixed(1),
                    'hrs',
                    AppColors.neonPurple,
                    Icons.bedtime,
                    false,
                  ),
                  _LiveMetricTile(
                    'SLEEP Q',
                    '$_sleepQuality',
                    '%',
                    AppColors.neonBlue,
                    Icons.auto_graph,
                    false,
                  ),
                  _LiveMetricTile(
                    'STRESS',
                    '$_stressIndex',
                    '/100',
                    AppColors.neonOrange,
                    Icons.psychology,
                    true,
                  ),
                  _LiveMetricTile(
                    'RECOVERY',
                    '$_recoveryScore',
                    '%',
                    AppColors.neonGreen,
                    Icons.healing,
                    false,
                  ),
                  _LiveMetricTile(
                    'VO₂ MAX',
                    _vo2Max.toStringAsFixed(1),
                    'ml',
                    AppColors.neonCyan,
                    Icons.air,
                    false,
                  ),
                  _LiveMetricTile(
                    'SpO₂',
                    '$_spo2',
                    '%',
                    AppColors.neonBlue,
                    Icons.bloodtype,
                    true,
                  ),
                  _LiveMetricTile(
                    'BODY TEMP',
                    _bodyTemp.toStringAsFixed(1),
                    '°C',
                    AppColors.neonAmber,
                    Icons.thermostat,
                    true,
                  ),
                  _LiveMetricTile(
                    'RESP RATE',
                    '$_respiratoryRate',
                    '/min',
                    AppColors.neonGreen,
                    Icons.waves,
                    true,
                  ),
                  _LiveMetricTile(
                    'CALORIES',
                    '$_caloriesBurned',
                    'kcal',
                    AppColors.neonOrange,
                    Icons.local_fire_department,
                    true,
                  ),
                  _LiveMetricTile(
                    'LOAD',
                    '$_trainingLoad',
                    '%',
                    AppColors.neonRed,
                    Icons.fitness_center,
                    false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. BEHAVIORAL INTELLIGENCE — Pattern detection
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBehavioralIntel() {
    return ScaleTransition(
      scale: _cardsScale,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('BEHAVIORAL INTELLIGENCE', AppColors.neonPurple),
            const SizedBox(height: 12),
            // Trend observations — smart pattern detection
            const _ObservationCard(
              icon: Icons.trending_up,
              title: 'SLEEP PATTERN DETECTED',
              body:
                  'Your deep sleep peaks on rest days (avg 1.8h) but drops to 0.9h post-training. '
                  'Atlas is adjusting your wind-down protocol — earlier cutoff for stimulants, blue light filter at 8pm.',
              accent: AppColors.neonPurple,
            ),
            const SizedBox(height: 8),
            _ObservationCard(
              icon: Icons.warning_amber_rounded,
              title: 'STRESS TRIGGER IDENTIFIED',
              body:
                  'HRV dips 18% every Thursday — correlated with sparring sessions. '
                  'Consider lighter intensity or move sparring to ${_recoveryScore > 75 ? "Tuesday" : "Wednesday"} '
                  'when recovery scores peak.',
              accent: AppColors.neonOrange,
            ),
            const SizedBox(height: 8),
            _ObservationCard(
              icon: Icons.check_circle_outline,
              title: 'POSITIVE TREND',
              body:
                  'Resting HR decreased 4 bpm over 30 days. Cardiovascular adaptation confirmed. '
                  'VO₂ max trending at ${_vo2Max.toStringAsFixed(1)} ml/kg/min. Your aerobic base is building steadily.',
              accent: AppColors.neonGreen,
            ),
            const SizedBox(height: 8),
            _ObservationCard(
              icon: Icons.psychology,
              title: 'NEURAL ENGINE ANALYSIS',
              body:
                  'Current stress-to-recovery ratio: ${(_stressIndex / _recoveryScore * 100).toStringAsFixed(0)}%. '
                  '${_stressIndex / _recoveryScore < 0.5 ? "Optimal balance — you can increase training volume." : "Approaching threshold — monitor closely."}',
              accent: AppColors.neonCyan,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. PREDICTIVE TIMELINE — Past → Present → Future
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPredictiveTimeline() {
    return ScaleTransition(
      scale: _cardsScale,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('PREDICTIVE INTELLIGENCE', AppColors.neonCyan),
            const SizedBox(height: 12),
            _GlassPanel(
              accent: AppColors.neonCyan,
              child: Column(
                children: [
                  SizedBox(
                    height: 140,
                    child: CustomPaint(
                      size: const Size(double.infinity, 140),
                      painter: _TimelinePainter(phase: _flowCtrl.value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      _TimeLabel('PAST', 'Analyzed', AppColors.neonBlue),
                      _TimeLabel('PRESENT', 'Monitoring', AppColors.neonGreen),
                      _TimeLabel('FUTURE', 'Predicted', AppColors.neonMagenta),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // AI Predictions — data-driven
            Row(
              children: [
                Expanded(
                  child: _PredictionCard(
                    label: 'FIGHT READINESS',
                    value: '${(_recoveryScore * 1.05).round().clamp(0, 99)}%',
                    verdict: _recoveryScore > 75 ? 'READY' : 'BUILDING',
                    color: _recoveryScore > 75
                        ? AppColors.neonGreen
                        : AppColors.neonOrange,
                    icon: Icons.sports_mma,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PredictionCard(
                    label: 'INJURY RISK',
                    value:
                        '${(100 - _recoveryScore + _stressIndex ~/ 3).clamp(10, 60)}%',
                    verdict: _stressIndex < 40 ? 'LOW' : 'MODERATE',
                    color: _stressIndex < 40
                        ? AppColors.neonCyan
                        : AppColors.neonOrange,
                    icon: Icons.shield,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PredictionCard(
                    label: 'PEAK PERFORMANCE',
                    value: '${14 - (_recoveryScore > 80 ? 3 : 0)}d',
                    verdict: 'PROJECTED',
                    color: AppColors.neonMagenta,
                    icon: Icons.rocket_launch,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PredictionCard(
                    label: 'WEIGHT TARGET',
                    value: '1.8kg',
                    verdict: _trainingLoad > 60 ? 'ON TRACK' : 'SLOW',
                    color: AppColors.neonOrange,
                    icon: Icons.monitor_weight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. COACH PROTOCOL — Data-driven daily plan
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCoachProtocol() {
    return ScaleTransition(
      scale: _cardsScale,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('ATLAS PROTOCOL', AppColors.neonRed),
            const SizedBox(height: 4),
            Text(
              'Personalized based on your current biometric state',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 12),
            ..._protocol.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActionCard(
                  priority: item.priority,
                  title: item.title,
                  subtitle: item.detail,
                  icon: item.icon,
                  color: item.color,
                  onTap: () {
                    // Show detail bottom sheet
                    _showProtocolDetail(item);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProtocolDetail(_ProtocolItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.color.withValues(alpha: 0.15),
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROTOCOL #${item.priority}',
                        style: TextStyle(
                          color: item.color.withValues(alpha: 0.6),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item.detail,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: item.color.withValues(alpha: 0.06),
                border: Border.all(color: item.color.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: item.color.withValues(alpha: 0.5),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Generated by Atlas Neural Engine based on $_dataPointsProcessed data points across $_engineCycles processing cycles.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. CONNECTION TRIANGLE — Human ↔ Device ↔ AI
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildConnectionTriangle() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(_feedSlide),
      child: FadeTransition(
        opacity: _feedSlide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            children: [
              _sectionLabel('THE SIMPLE PROCESS', AppColors.neonMagenta),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: _TrianglePainter(
                    phase: _flowCtrl.value,
                    pulse: _pulseCtrl.value,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Body generates data → Devices capture it → AI analyzes → Coach acts',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 10. DEVICE HUB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDeviceHub() {
    final devices = [
      const _DeviceInfo(
        'Apple Watch Ultra 2',
        'Heart Rate · HRV · SpO₂ · Sleep',
        AppColors.neonCyan,
        true,
        '2 min ago',
      ),
      const _DeviceInfo(
        'Oura Ring Gen 3',
        'Sleep · Body Temp · Readiness',
        AppColors.neonPurple,
        true,
        '8 min ago',
      ),
      const _DeviceInfo(
        'WHOOP 4.0',
        'Strain · Recovery · HRV',
        AppColors.neonGreen,
        false,
        'Not synced',
      ),
      const _DeviceInfo(
        'Phone Sensors',
        'Accelerometer · Gyroscope · Camera PPG',
        AppColors.neonBlue,
        true,
        'Live',
      ),
    ];

    return ScaleTransition(
      scale: _cardsScale,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _sectionLabel('DEVICE HUB', AppColors.neonBlue),
                const Spacer(),
                Text(
                  '${devices.where((d) => d.connected).length}/${devices.length} CONNECTED',
                  style: TextStyle(
                    color: AppColors.neonGreen.withValues(alpha: 0.5),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...devices.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DeviceCard(device: d, pulse: _pulseCtrl.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 11. ENGINE TELEMETRY — Neural Engine status
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEngineTelemetry() {
    return ScaleTransition(
      scale: _cardsScale,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: _GlassPanel(
          accent: AppColors.neonCyan,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.memory, color: AppColors.neonCyan, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'NEURAL ENGINE TELEMETRY',
                    style: TextStyle(
                      color: AppColors.neonCyan.withValues(alpha: 0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  _StatusDot(
                    color: AppColors.neonGreen,
                    label: 'RUNNING',
                    phase: _pulseCtrl.value,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _TelemetryStat(
                    'Engine Cycles',
                    '$_engineCycles',
                    AppColors.neonCyan,
                  ),
                  const SizedBox(width: 8),
                  _TelemetryStat(
                    'Data Points',
                    '$_dataPointsProcessed',
                    AppColors.neonGreen,
                  ),
                  const SizedBox(width: 8),
                  const _TelemetryStat(
                    'Accuracy',
                    '97.3%',
                    AppColors.neonMagenta,
                  ),
                  const SizedBox(width: 8),
                  const _TelemetryStat('Latency', '12ms', AppColors.neonBlue),
                ],
              ),
              const SizedBox(height: 10),
              // Engine pipeline
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withValues(alpha: 0.02),
                ),
                child: Row(
                  children: [
                    const _PipelineStep('INGEST', AppColors.neonBlue, true),
                    _PipelineArrow(),
                    const _PipelineStep('ANALYZE', AppColors.neonCyan, true),
                    _PipelineArrow(),
                    const _PipelineStep('PREDICT', AppColors.neonMagenta, true),
                    _PipelineArrow(),
                    const _PipelineStep('ACT', AppColors.neonGreen, true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _sectionLabel(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//
// CUSTOM PAINTERS — The visual intelligence
//
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// NEURAL NETWORK BACKGROUND — Ambient neural connections
// ─────────────────────────────────────────────────────────────────────────────
class _NeuralNetworkPainter extends CustomPainter {
  final double phase;
  final double flowPhase;

  _NeuralNetworkPainter({required this.phase, required this.flowPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(42);
    final nodes = <Offset>[];
    for (int i = 0; i < 30; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      nodes.add(Offset(x, y));
    }

    final wirePaint = Paint()
      ..strokeWidth = 0.3
      ..style = PaintingStyle.stroke;

    // Draw connections
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < size.width * 0.28) {
          final alpha = (0.03 * (1.0 - dist / (size.width * 0.28))).clamp(
            0.0,
            0.05,
          );
          wirePaint.color = AppColors.neonCyan.withValues(alpha: alpha);
          canvas.drawLine(nodes[i], nodes[j], wirePaint);
        }
      }
    }

    // Draw nodes with phase-based pulsing
    for (int i = 0; i < nodes.length; i++) {
      final pulse = math.sin(phase * math.pi * 2 + i * 0.5) * 0.5 + 0.5;
      canvas.drawCircle(
        nodes[i],
        1.5 + pulse,
        Paint()
          ..color = AppColors.neonCyan.withValues(alpha: 0.03 + pulse * 0.02)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Data flow particles
    for (int i = 0; i < 6; i++) {
      final t = (flowPhase + i * 0.166) % 1.0;
      final startNode = nodes[i % nodes.length];
      final endNode = nodes[(i * 3 + 5) % nodes.length];
      final px = startNode.dx + (endNode.dx - startNode.dx) * t;
      final py = startNode.dy + (endNode.dy - startNode.dy) * t;
      canvas.drawCircle(
        Offset(px, py),
        2,
        Paint()
          ..color = AppColors.neonCyan.withValues(alpha: 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralNetworkPainter old) => old.phase != phase;
}

// ─────────────────────────────────────────────────────────────────────────────
// COACH BRAIN — Central neural hub visualization
// ─────────────────────────────────────────────────────────────────────────────
class _CoachBrainPainter extends CustomPainter {
  final double pulse;
  final double flow;

  _CoachBrainPainter({required this.pulse, required this.flow});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    // Outer rotating ring
    for (int i = 0; i < 24; i++) {
      final angle = pulse * math.pi * 2 + (2 * math.pi * i / 24);
      final r = 80.0;
      final x = cx + math.cos(angle) * r;
      final y = cy + math.sin(angle) * r;
      final a = (math.sin(pulse * math.pi * 4 + i) * 0.5 + 0.5) * 0.08;
      canvas.drawCircle(
        Offset(x, y),
        1.5,
        Paint()..color = AppColors.neonCyan.withValues(alpha: a),
      );
    }

    // Concentric rings
    for (int i = 5; i >= 1; i--) {
      final r = 15.0 + i * 14.0;
      final p = math.sin(pulse * math.pi * 2 + i * 0.3) * 0.5 + 0.5;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = AppColors.neonCyan.withValues(alpha: 0.04 + p * 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Core glow
    canvas.drawCircle(
      center,
      20 + math.sin(pulse * math.pi * 2) * 4,
      Paint()
        ..color = AppColors.neonCyan.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      center,
      10,
      Paint()..color = AppColors.neonCyan.withValues(alpha: 0.5),
    );

    // Data branches
    final branches = [
      const _Branch('HUMAN', -0.4, AppColors.neonRed),
      const _Branch('DEVICE', 0.4, AppColors.neonBlue),
      const _Branch('AI', -1.2, AppColors.neonMagenta),
      const _Branch('SEO', 1.2, AppColors.neonAmber),
      const _Branch('RESULTS', 0.0, AppColors.neonGreen),
    ];

    for (int i = 0; i < branches.length; i++) {
      final b = branches[i];
      final angle = -math.pi / 2 + b.angle;
      final endR = 75.0;
      final endX = cx + math.cos(angle) * endR;
      final endY = cy + math.sin(angle) * endR;
      final end = Offset(endX, endY);

      // Branch line
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = b.color.withValues(alpha: 0.15)
          ..strokeWidth = 1.5,
      );

      // Flowing dot
      final t = (flow + i * 0.2) % 1.0;
      final dotX = cx + (endX - cx) * t;
      final dotY = cy + (endY - cy) * t;
      canvas.drawCircle(
        Offset(dotX, dotY),
        3,
        Paint()
          ..color = b.color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        1.5,
        Paint()..color = b.color.withValues(alpha: 0.8),
      );

      // End node
      canvas.drawCircle(
        end,
        6,
        Paint()
          ..color = b.color.withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        end,
        3.5,
        Paint()..color = b.color.withValues(alpha: 0.5),
      );

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: b.label,
          style: TextStyle(
            color: b.color.withValues(alpha: 0.5),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelX = cx + math.cos(angle) * (endR + 16) - textPainter.width / 2;
      final labelY =
          cy + math.sin(angle) * (endR + 16) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant _CoachBrainPainter old) =>
      old.pulse != pulse || old.flow != flow;
}

class _Branch {
  final String label;
  final double angle;
  final Color color;
  const _Branch(this.label, this.angle, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// TRIANGLE PAINTER — Human ↔ Device ↔ AI connection
// ─────────────────────────────────────────────────────────────────────────────
class _TrianglePainter extends CustomPainter {
  final double phase;
  final double pulse;

  _TrianglePainter({required this.phase, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Triangle vertices
    final human = Offset(cx, cy - 60);
    final device = Offset(cx - 90, cy + 45);
    final ai = Offset(cx + 90, cy + 45);

    final vertices = [human, device, ai];
    final colors = [
      AppColors.neonRed,
      AppColors.neonBlue,
      AppColors.neonMagenta,
    ];
    final labels = ['HUMAN', 'DEVICE', 'AI'];

    // Draw triangle edges with flowing particles
    for (int i = 0; i < 3; i++) {
      final from = vertices[i];
      final to = vertices[(i + 1) % 3];

      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = colors[i].withValues(alpha: 0.15)
          ..strokeWidth = 1.5,
      );

      // Multiple flow dots per edge
      for (int d = 0; d < 2; d++) {
        final t = (phase + i * 0.33 + d * 0.5) % 1.0;
        final dx = from.dx + (to.dx - from.dx) * t;
        final dy = from.dy + (to.dy - from.dy) * t;
        canvas.drawCircle(
          Offset(dx, dy),
          3.5 - d,
          Paint()
            ..color = colors[i].withValues(alpha: 0.25 - d * 0.1)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(
          Offset(dx, dy),
          1.5,
          Paint()..color = colors[i].withValues(alpha: 0.7),
        );
      }
    }

    // Vertex nodes
    for (int i = 0; i < 3; i++) {
      final v = vertices[i];
      final c = colors[i];
      final p = math.sin(pulse * math.pi * 2 + i) * 0.5 + 0.5;

      canvas.drawCircle(
        v,
        20 + p * 4,
        Paint()
          ..color = c.withValues(alpha: 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
      canvas.drawCircle(
        v,
        16,
        Paint()
          ..color = c.withValues(alpha: 0.2 + p * 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(v, 7, Paint()..color = c.withValues(alpha: 0.6));

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: c.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelOffset = i == 0
          ? Offset(v.dx - tp.width / 2, v.dy - 30)
          : Offset(v.dx - tp.width / 2, v.dy + 22);
      tp.paint(canvas, labelOffset);
    }

    // Center label
    final centerTp = TextPainter(
      text: TextSpan(
        text: 'NEURAL\nCOACH',
        style: TextStyle(
          color: AppColors.neonCyan.withValues(alpha: 0.3),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          height: 1.3,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    centerTp.paint(
      canvas,
      Offset(cx - centerTp.width / 2, cy - centerTp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) =>
      old.phase != phase || old.pulse != pulse;
}

// ─────────────────────────────────────────────────────────────────────────────
// HEARTBEAT PAINTER — ECG-style waveform
// ─────────────────────────────────────────────────────────────────────────────
class _HeartbeatPainter extends CustomPainter {
  final double phase;
  final int bpm;

  _HeartbeatPainter({required this.phase, required this.bpm});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    path.moveTo(0, mid);

    for (double x = 0; x <= w; x += 1) {
      final t = (x / w + phase) % 1.0;
      final cycle = t * 3;
      final pos = cycle % 1.0;

      double y = mid;
      if (pos > 0.35 && pos < 0.38) {
        y = mid + 4; // P wave
      } else if (pos > 0.40 && pos < 0.42) {
        y = mid + 3; // Q
      } else if (pos > 0.42 && pos < 0.45) {
        y = mid - h * 0.7; // R spike
      } else if (pos > 0.45 && pos < 0.48) {
        y = mid + 8; // S dip
      } else if (pos > 0.50 && pos < 0.55) {
        y = mid - 5; // T wave
      }

      path.lineTo(x, y);
    }

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.neonRed.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main line
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.neonRed.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Scan line
    final scanX = phase * w;
    canvas.drawLine(
      Offset(scanX, 0),
      Offset(scanX, h),
      Paint()
        ..color = AppColors.neonRed.withValues(alpha: 0.15)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter old) => old.phase != phase;
}

// ─────────────────────────────────────────────────────────────────────────────
// ATLAS RADAR — FULL-SIZE readable spider chart
// ─────────────────────────────────────────────────────────────────────────────
class _AtlasRadarPainter extends CustomPainter {
  final double phase;
  final List<double> values;
  final List<String> labels;

  _AtlasRadarPainter({
    required this.phase,
    required this.values,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(cx, cy) - 40; // generous margin for labels
    final n = values.length;

    // Grid rings with value labels
    for (int ring = 1; ring <= 4; ring++) {
      final r = maxR * ring / 4;
      final path = Path();
      for (int i = 0; i <= n; i++) {
        final angle = -math.pi / 2 + (2 * math.pi * (i % n) / n);
        final px = cx + math.cos(angle) * r;
        final py = cy + math.sin(angle) * r;
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );

      // Ring value label (25%, 50%, 75%, 100%)
      final ringLabel = '${ring * 25}%';
      final ringTp = TextPainter(
        text: TextSpan(
          text: ringLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.15),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ringTp.paint(canvas, Offset(cx + 3, cy - r - ringTp.height / 2));
    }

    // Axes
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / n);
      final ex = cx + math.cos(angle) * maxR;
      final ey = cy + math.sin(angle) * maxR;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(ex, ey),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 0.5,
      );
    }

    // Data polygon glow (outer)
    final glowPath = Path();
    final pulse = math.sin(phase * math.pi * 2) * 0.02;
    for (int i = 0; i <= n; i++) {
      final idx = i % n;
      final angle = -math.pi / 2 + (2 * math.pi * idx / n);
      final r = maxR * (values[idx] + pulse);
      final px = cx + math.cos(angle) * r;
      final py = cy + math.sin(angle) * r;
      if (i == 0) {
        glowPath.moveTo(px, py);
      } else {
        glowPath.lineTo(px, py);
      }
    }
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = AppColors.neonMagenta.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Data polygon fill
    canvas.drawPath(
      glowPath,
      Paint()..color = AppColors.neonMagenta.withValues(alpha: 0.1),
    );

    // Data polygon border
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = AppColors.neonMagenta.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Labels + value annotations + data points
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / n);
      final r = maxR * (values[i] + pulse);
      final px = cx + math.cos(angle) * r;
      final py = cy + math.sin(angle) * r;

      // Data point glow
      canvas.drawCircle(
        Offset(px, py),
        8,
        Paint()
          ..color = _dotColor(values[i]).withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Data point core
      canvas.drawCircle(
        Offset(px, py),
        4,
        Paint()..color = _dotColor(values[i]).withValues(alpha: 0.9),
      );
      // Data point ring
      canvas.drawCircle(
        Offset(px, py),
        6,
        Paint()
          ..color = _dotColor(values[i]).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // LABEL — big, readable
      final labelR = maxR + 24;
      final lx = cx + math.cos(angle) * labelR;
      final ly = cy + math.sin(angle) * labelR;
      final labelTp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: AppColors.neonMagenta.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelTp.paint(
        canvas,
        Offset(lx - labelTp.width / 2, ly - labelTp.height / 2),
      );

      // VALUE PERCENTAGE — next to label
      final valR = maxR + 36;
      final vx = cx + math.cos(angle) * valR;
      final vy = cy + math.sin(angle) * valR;
      final valTp = TextPainter(
        text: TextSpan(
          text: '${(values[i] * 100).round()}%',
          style: TextStyle(
            color: _dotColor(values[i]).withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valTp.paint(
        canvas,
        Offset(vx - valTp.width / 2, vy - valTp.height / 2 + 12),
      );
    }

    // Center label
    final centerTp = TextPainter(
      text: TextSpan(
        text: 'ATLAS\nMAP',
        style: TextStyle(
          color: AppColors.neonMagenta.withValues(alpha: 0.2),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    centerTp.paint(
      canvas,
      Offset(cx - centerTp.width / 2, cy - centerTp.height / 2),
    );
  }

  Color _dotColor(double value) {
    if (value >= 0.8) return AppColors.neonGreen;
    if (value >= 0.6) return AppColors.neonMagenta;
    return AppColors.neonOrange;
  }

  @override
  bool shouldRepaint(covariant _AtlasRadarPainter old) =>
      old.phase != phase || old.values != values;
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE PAINTER — Past → Present → Future
// ─────────────────────────────────────────────────────────────────────────────
class _TimelinePainter extends CustomPainter {
  final double phase;

  _TimelinePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = h / 2;
    final margin = 20.0;

    // Main axis
    canvas.drawLine(
      Offset(margin, mid),
      Offset(w - margin, mid),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1,
    );

    final zones = [
      _Zone('PAST', margin, w * 0.35, AppColors.neonBlue),
      _Zone('NOW', w * 0.35, w * 0.65, AppColors.neonGreen),
      _Zone('FUTURE', w * 0.65, w - margin, AppColors.neonMagenta),
    ];

    final r = math.Random(42);

    for (final z in zones) {
      canvas.drawRect(
        Rect.fromLTRB(z.start, mid - 1, z.end, mid + 1),
        Paint()..color = z.color.withValues(alpha: 0.2),
      );

      final count = z.color == AppColors.neonMagenta ? 4 : 6;
      for (int i = 0; i < count; i++) {
        final x = z.start + (z.end - z.start) * (i + 0.5) / count;
        final y = mid + (r.nextDouble() - 0.5) * h * 0.6;
        final dotPhase =
            math.sin(phase * math.pi * 2 + i + zones.indexOf(z)) * 0.5 + 0.5;

        canvas.drawLine(
          Offset(x, mid),
          Offset(x, y),
          Paint()
            ..color = z.color.withValues(alpha: 0.08)
            ..strokeWidth = 0.5,
        );

        canvas.drawCircle(
          Offset(x, y),
          3 + dotPhase * 2,
          Paint()
            ..color = z.color.withValues(alpha: 0.1 + dotPhase * 0.1)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(x, y),
          2,
          Paint()
            ..color = z.color.withValues(
              alpha: z.color == AppColors.neonMagenta
                  ? 0.3 + dotPhase * 0.3
                  : 0.5,
            ),
        );
      }

      if (z.color != AppColors.neonBlue) {
        canvas.drawLine(
          Offset(z.start, mid - 20),
          Offset(z.start, mid + 20),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.06)
            ..strokeWidth = 0.5,
        );
      }
    }

    // NOW pulsing indicator
    final nowX = w * 0.5;
    final nowPulse = math.sin(phase * math.pi * 2) * 0.5 + 0.5;
    canvas.drawCircle(
      Offset(nowX, mid),
      6 + nowPulse * 3,
      Paint()
        ..color = AppColors.neonGreen.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      Offset(nowX, mid),
      4,
      Paint()..color = AppColors.neonGreen.withValues(alpha: 0.7),
    );

    // Future scan sweep
    final sweepX = w * 0.65 + (w * 0.35 - margin) * phase;
    canvas.drawLine(
      Offset(sweepX, mid - 30),
      Offset(sweepX, mid + 30),
      Paint()
        ..color = AppColors.neonMagenta.withValues(alpha: 0.1)
        ..strokeWidth = 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) => old.phase != phase;
}

class _Zone {
  final String label;
  final double start, end;
  final Color color;
  const _Zone(this.label, this.start, this.end, this.color);
}

// ═════════════════════════════════════════════════════════════════════════════
//
// REUSABLE WIDGETS
//
// ═════════════════════════════════════════════════════════════════════════════

class _GlassPanel extends StatelessWidget {
  final Color accent;
  final Widget child;

  const _GlassPanel({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: accent.withValues(alpha: 0.03),
            border: Border.all(color: accent.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  final double phase;

  const _StatusDot({
    required this.color,
    required this.label,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final alpha = 0.5 + math.sin(phase * math.pi * 2) * 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: alpha),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _LiveMetricTile extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  final IconData icon;
  final bool isLive;

  const _LiveMetricTile(
    this.label,
    this.value,
    this.unit,
    this.color,
    this.icon,
    this.isLive,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.04),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: color.withValues(alpha: 0.5), size: 14),
                  if (isLive) ...[
                    const Spacer(),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neonGreen,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonGreen.withValues(alpha: 0.4),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.5),
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ObservationCard extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final Color accent;

  const _ObservationCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: accent.withValues(alpha: 0.03),
            border: Border.all(color: accent.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: accent, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  final String label, sub;
  final Color color;

  const _TimeLabel(this.label, this.sub, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            sub,
            style: TextStyle(color: color.withValues(alpha: 0.4), fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final String label, value, verdict;
  final Color color;
  final IconData icon;

  const _PredictionCard({
    required this.label,
    required this.value,
    required this.verdict,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.04),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color.withValues(alpha: 0.5), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.5),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: color.withValues(alpha: 0.1),
                ),
                child: Text(
                  verdict,
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String priority, title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.priority,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.03),
              border: Border.all(color: color.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      priority,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(icon, color: color.withValues(alpha: 0.4), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceInfo {
  final String name, metrics;
  final Color color;
  final bool connected;
  final String lastSync;
  const _DeviceInfo(
    this.name,
    this.metrics,
    this.color,
    this.connected,
    this.lastSync,
  );
}

class _DeviceCard extends StatelessWidget {
  final _DeviceInfo device;
  final double pulse;

  const _DeviceCard({required this.device, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final p = math.sin(pulse * math.pi * 2) * 0.5 + 0.5;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: device.color.withValues(alpha: 0.03),
            border: Border.all(color: device.color.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: device.connected
                      ? AppColors.neonGreen.withValues(alpha: 0.5 + p * 0.5)
                      : Colors.white.withValues(alpha: 0.15),
                  boxShadow: device.connected
                      ? [
                          BoxShadow(
                            color: AppColors.neonGreen.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : [],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: TextStyle(
                        color: device.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      device.metrics,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                device.lastSync,
                style: TextStyle(
                  color: device.connected
                      ? AppColors.neonGreen.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.2),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarLegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _RadarLegendDot(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TelemetryStat extends StatelessWidget {
  final String label, value;
  final Color color;

  const _TelemetryStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: color.withValues(alpha: 0.04),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.4),
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PipelineStep extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;

  const _PipelineStep(this.label, this.color, this.active);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: active ? color.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(
            color: color.withValues(alpha: active ? 0.2 : 0.05),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: active ? 0.7 : 0.3),
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _PipelineArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(
        Icons.arrow_forward_ios,
        size: 8,
        color: Colors.white.withValues(alpha: 0.15),
      ),
    );
  }
}
