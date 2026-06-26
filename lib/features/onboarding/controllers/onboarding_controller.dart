import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/social_onboarding_service.dart';

/// Handles the five-step onboarding journey (including intro video).
class OnboardingController extends ChangeNotifier {
  OnboardingController({
    required this.authService,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance {
    selectedRole = authService.userModel?.role;
  }

  final AuthService authService;
  final FirebaseFirestore firestore;

  int currentStep = 0;
  static const int totalSteps = 5; // Now includes video intro step

  UserRole? selectedRole;
  final Set<String> selectedIntents = {};
  final Set<String> preferredPractices = {};
  final Set<String> opportunityInterests = {};
  double mindLoad = 5;
  double bodyLoad = 5;
  double soulLoad = 5;
  String storyIntro = '';

  bool termsAccepted = false;
  bool updatesOptIn = true;
  bool isSaving = false;
  String? errorMessage;

  List<String> get intentOptions => const [
    'Win belts',
    'Build community',
    'Monetize skills',
    'Heal & reset',
    'Teach and mentor',
    'Alternative therapy trials',
  ];

  List<String> get practiceOptions => const [
    'Breathwork',
    'Cold therapy',
    'Mindful nutrition',
    'AI coach check-ins',
    'Journaling',
    'Mobility protocols',
  ];

  List<String> get opportunityOptions => const [
    'Promotions',
    'Brand collaborations',
    'Teaching slots',
    'Alternative therapy pilots',
    'Streaming features',
  ];

  static const List<UserRole> primaryRoles = [
    UserRole.fighter,
    UserRole.promoter,
    UserRole.gym,
    UserRole.fan,
  ];

  UserRole get activeRole =>
      selectedRole ?? authService.userModel?.role ?? UserRole.fan;

  List<UserRole> get roleOptions {
    if (selectedRole != null && !primaryRoles.contains(selectedRole)) {
      return [...primaryRoles, selectedRole!];
    }
    return primaryRoles;
  }

  List<String> get adaptiveIntentOptions {
    switch (activeRole) {
      case UserRole.fighter:
        return const [
          'Get booked on stronger cards',
          'Build fight-week presence',
          'Attract sponsors',
          'Grow my highlight reel',
          'Find the right gym support',
          'Stay visible between bouts',
        ];
      case UserRole.promoter:
        return const [
          'Fill cards faster',
          'Sell more tickets',
          'Spot reliable talent',
          'Run cleaner event launches',
          'Activate sponsors',
          'Build regional momentum',
        ];
      case UserRole.gym:
        return const [
          'Recruit new members',
          'Showcase fighters',
          'Publish training culture',
          'Book seminars and sparring',
          'Strengthen local reputation',
          'Create safer pathways',
        ];
      case UserRole.fan:
        return const [
          'Follow rising fighters',
          'Track live events',
          'Support local gyms',
          'Join the community',
          'Discover fight stories',
          'Back favorite promotions',
        ];
      default:
        return intentOptions;
    }
  }

  List<String> get adaptivePracticeOptions {
    switch (activeRole) {
      case UserRole.fighter:
        return const [
          'Recovery protocols',
          'Weight-cut planning',
          'Mobility work',
          'Mental reset blocks',
          'Coach review sessions',
          'Clip study',
        ];
      case UserRole.promoter:
        return const [
          'Fight-week planning',
          'Venue ops checklists',
          'Sponsor outreach',
          'Content scheduling',
          'Talent scouting',
          'Post-event review',
        ];
      case UserRole.gym:
        return const [
          'Class programming',
          'Coach rotations',
          'Member check-ins',
          'Recovery education',
          'Safeguarding routines',
          'Talent development',
        ];
      case UserRole.fan:
        return const [
          'Event alerts',
          'Watchlist tracking',
          'Community discussions',
          'Fantasy picks',
          'Training inspiration',
          'Local event discovery',
        ];
      default:
        return practiceOptions;
    }
  }

  List<String> get adaptiveOpportunityOptions {
    switch (activeRole) {
      case UserRole.fighter:
        return const [
          'Fight offers',
          'Sponsor introductions',
          'Media features',
          'Gym placements',
          'Highlight promotion',
        ];
      case UserRole.promoter:
        return const [
          'Main-event talent',
          'Production partners',
          'Sponsor inventory',
          'Venue leads',
          'PPV growth support',
        ];
      case UserRole.gym:
        return const [
          'Member referrals',
          'Fighter placements',
          'Seminar bookings',
          'Coach hiring',
          'Community partnerships',
        ];
      case UserRole.fan:
        return const [
          'Priority event drops',
          'Collector perks',
          'Meet-and-greet alerts',
          'Fan missions',
          'Local fight nights',
        ];
      default:
        return opportunityOptions;
    }
  }

  String get roleStepTitle {
    switch (activeRole) {
      case UserRole.fighter:
        return 'Build your fight identity';
      case UserRole.promoter:
        return 'Set your promotion lane';
      case UserRole.gym:
        return 'Define your gym presence';
      case UserRole.fan:
        return 'Shape your fight network';
      default:
        return 'Choose your lane';
    }
  }

  String get roleStepSubtitle {
    switch (activeRole) {
      case UserRole.fighter:
        return 'We will tune the app around bookings, visibility, and career momentum.';
      case UserRole.promoter:
        return 'We will tune the app around cards, talent, launch pressure, and partnerships.';
      case UserRole.gym:
        return 'We will tune the app around members, culture, fighter development, and trust.';
      case UserRole.fan:
        return 'We will tune the app around discovery, community, and the fighters you want to follow.';
      default:
        return 'Your role changes what DFC prioritizes first.';
    }
  }

  String get loadStepTitle {
    switch (activeRole) {
      case UserRole.fighter:
        return 'Calibrate camp load';
      case UserRole.promoter:
        return 'Calibrate event-week load';
      case UserRole.gym:
        return 'Calibrate gym load';
      case UserRole.fan:
        return 'Calibrate your watchlist load';
      default:
        return 'Calibrate today\'s load';
    }
  }

  String get opportunityStepTitle {
    switch (activeRole) {
      case UserRole.fighter:
        return 'What opportunities should chase you?';
      case UserRole.promoter:
        return 'What resources should DFC surface for you?';
      case UserRole.gym:
        return 'What growth doors should open first?';
      case UserRole.fan:
        return 'What should the app put in front of you?';
      default:
        return 'What doors should we open?';
    }
  }

  String get storyPromptHint {
    switch (activeRole) {
      case UserRole.fighter:
        return 'What headline should describe this stage of your career?';
      case UserRole.promoter:
        return 'What is the story behind your next event run or promotion push?';
      case UserRole.gym:
        return 'What should people feel when they discover your gym?';
      case UserRole.fan:
        return 'What kind of fight world are you here to follow and support?';
      default:
        return 'Give us the headline or emotion driving this season.';
    }
  }

  bool get canContinue {
    switch (currentStep) {
      case 0: // Video intro - always can continue
        return true;
      case 1: // Role & Intent selection
        return selectedRole != null && selectedIntents.isNotEmpty;
      case 2: // Load calibration
        return true;
      case 3: // Opportunities
        return opportunityInterests.isNotEmpty || storyIntro.isNotEmpty;
      case 4: // Consent
        return termsAccepted;
      default:
        return false;
    }
  }

  bool get isLastStep => currentStep == totalSteps - 1;

  /// Returns onboarding progress as a value between 0 and 1.
  double get progress => (currentStep + 1) / totalSteps;

  void selectRole(UserRole role) {
    selectedRole = role;
    notifyListeners();
  }

  void toggleIntent(String intent) {
    if (selectedIntents.contains(intent)) {
      selectedIntents.remove(intent);
    } else {
      selectedIntents.add(intent);
    }
    notifyListeners();
  }

  void togglePractice(String practice) {
    if (preferredPractices.contains(practice)) {
      preferredPractices.remove(practice);
    } else {
      preferredPractices.add(practice);
    }
    notifyListeners();
  }

  void toggleOpportunity(String opportunity) {
    if (opportunityInterests.contains(opportunity)) {
      opportunityInterests.remove(opportunity);
    } else {
      opportunityInterests.add(opportunity);
    }
    notifyListeners();
  }

  void updateMindLoad(double value) {
    mindLoad = value;
    notifyListeners();
  }

  void updateBodyLoad(double value) {
    bodyLoad = value;
    notifyListeners();
  }

  void updateSoulLoad(double value) {
    soulLoad = value;
    notifyListeners();
  }

  void updateStoryIntro(String value) {
    storyIntro = value;
    notifyListeners();
  }

  void setTermsAccepted(bool value) {
    termsAccepted = value;
    notifyListeners();
  }

  void setUpdatesOptIn(bool value) {
    updatesOptIn = value;
    notifyListeners();
  }

  void nextStep() {
    if (currentStep < totalSteps - 1) {
      currentStep += 1;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep -= 1;
      notifyListeners();
    }
  }

  Future<bool> completeOnboarding() async {
    if (isSaving) return false;

    // In guest mode, skip Firestore writes entirely
    if (AppConstants.guestMode) {
      isSaving = true;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
      isSaving = false;
      notifyListeners();
      return true;
    }

    final uid = authService.firebaseUser?.uid;
    if (uid == null) {
      errorMessage = 'No authenticated user found.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'selectedRole':
            (selectedRole ?? authService.userModel?.role ?? UserRole.fan).name,
        'intents': selectedIntents.toList(),
        'preferredPractices': preferredPractices.toList(),
        'opportunityInterests': opportunityInterests.toList(),
        'mindLoad': mindLoad,
        'bodyLoad': bodyLoad,
        'soulLoad': soulLoad,
        'storyIntro': storyIntro,
        'updatesOptIn': updatesOptIn,
        'completedAt': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection(AppConstants.onboardingCollection)
          .doc(uid)
          .set(payload, SetOptions(merge: true));

      final metadata = Map<String, dynamic>.from(
        authService.userModel?.metadata ?? {},
      );
      metadata['onboarding'] = payload;

      // NOTE: Do NOT write 'role' here — Firestore security rules block
      // role changes on user updates to prevent privilege escalation.
      // The role was already set at registration.
      await firestore.collection(AppConstants.usersCollection).doc(uid).update({
        'onboardingCompleted': true,
        'metadata': metadata,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await authService.refreshUserProfile();

      // Pre-warm friend suggestions now that onboarding data is saved
      unawaited(SocialOnboardingService().prewarmSuggestions());

      return true;
    } catch (e) {
      // If Firestore write fails, still let user proceed —
      // mark onboarding completed locally so they aren't trapped
      debugPrint('Onboarding save failed: $e — allowing user to proceed');
      authService.markOnboardingCompletedLocally();
      return true;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
