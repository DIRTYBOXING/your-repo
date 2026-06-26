// ═══════════════════════════════════════════════════════════════════════════
// ROLE-BASED DASHBOARD CONTROLLER
// ═══════════════════════════════════════════════════════════════════════════
// Personalized dashboard data for each DFC user role:
//   • Fighter — training, health, fights, career stats
//   • Coach — athlete roster, team performance, scheduling
//   • Gym — member management, classes, revenue
//   • Promoter — events, fighters, sales, streaming
//   • Fan — feed, favorites, predictions, social
//
// Feeds data to role-specific dashboard UIs.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dfc_event_bus.dart';
import 'atlas_2_intelligence.dart';

/// User roles in DFC
enum DFCRole { fighter, coach, gym, promoter, fan, admin }

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER DASHBOARD DATA
/// ═══════════════════════════════════════════════════════════════════════════
class FighterDashboardData {
  // Profile
  final String fighterId;
  final String displayName;
  final String photoUrl;
  final String weightClass;
  final int proRecord; // wins-losses-draws as count

  // Health & Readiness
  final double readinessScore; // 0-100
  final double recoveryScore;
  final int hoursSlept;
  final int restingHR;
  final String readinessEmoji;

  // Training
  final int trainingDaysThisWeek;
  final double weeklyLoadScore;
  final String currentPhase; // base, build, peak, taper, recovery
  final DateTime? nextSession;
  final String? nextSessionType;

  // Upcoming Fight
  final DateTime? nextFightDate;
  final String? opponent;
  final String? eventName;
  final int? daysUntilFight;

  // Career Stats
  final int wins;
  final int losses;
  final int draws;
  final int knockouts;
  final int submissions;
  final String fightStyle;

  // Financials
  final double totalEarnings;
  final double pendingPayouts;
  final int sponsorDeals;

  // Social
  final int followers;
  final int fanMessages;
  final int postLikes;

  // Insights from ATLAS
  final List<String> atlasInsights;

  FighterDashboardData({
    required this.fighterId,
    required this.displayName,
    this.photoUrl = '',
    this.weightClass = '',
    this.proRecord = 0,
    this.readinessScore = 85,
    this.recoveryScore = 80,
    this.hoursSlept = 7,
    this.restingHR = 60,
    this.readinessEmoji = '😴',
    this.trainingDaysThisWeek = 0,
    this.weeklyLoadScore = 0,
    this.currentPhase = 'base',
    this.nextSession,
    this.nextSessionType,
    this.nextFightDate,
    this.opponent,
    this.eventName,
    this.daysUntilFight,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.knockouts = 0,
    this.submissions = 0,
    this.fightStyle = 'All-Around',
    this.totalEarnings = 0,
    this.pendingPayouts = 0,
    this.sponsorDeals = 0,
    this.followers = 0,
    this.fanMessages = 0,
    this.postLikes = 0,
    this.atlasInsights = const [],
  });

  String get record => '$wins-$losses${draws > 0 ? '-$draws' : ''}';
  double get winRate => (wins + losses) > 0 ? wins / (wins + losses) * 100 : 0;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// COACH DASHBOARD DATA
/// ═══════════════════════════════════════════════════════════════════════════
class CoachDashboardData {
  final String coachId;
  final String displayName;
  final String photoUrl;
  final String gymAffiliation;

  // Roster
  final int totalAthletes;
  final List<AthleteSnapshot> athletes;
  final int athletesInCamp;
  final int athletesRecovering;

  // Today's Schedule
  final List<SessionSnapshot> todaySessions;
  final int sessionsCompleted;
  final int sessionsRemaining;

  // Team Performance
  final int teamWinsThisYear;
  final int teamLossesThisYear;
  final double teamWinRate;
  final String teamMood;

  // Upcoming
  final List<UpcomingFightSnapshot> upcomingFights;

  // Revenue
  final double monthlyRevenue;
  final double pendingInvoices;

  // Insights
  final List<String> atlasInsights;

  CoachDashboardData({
    required this.coachId,
    required this.displayName,
    this.photoUrl = '',
    this.gymAffiliation = '',
    this.totalAthletes = 0,
    this.athletes = const [],
    this.athletesInCamp = 0,
    this.athletesRecovering = 0,
    this.todaySessions = const [],
    this.sessionsCompleted = 0,
    this.sessionsRemaining = 0,
    this.teamWinsThisYear = 0,
    this.teamLossesThisYear = 0,
    this.teamWinRate = 0,
    this.teamMood = '💪',
    this.upcomingFights = const [],
    this.monthlyRevenue = 0,
    this.pendingInvoices = 0,
    this.atlasInsights = const [],
  });
}

class AthleteSnapshot {
  final String id;
  final String name;
  final String photoUrl;
  final double readiness;
  final String status; // training, fight-camp, recovering, injured
  final DateTime? nextSession;

  AthleteSnapshot({
    required this.id,
    required this.name,
    this.photoUrl = '',
    this.readiness = 80,
    this.status = 'training',
    this.nextSession,
  });
}

class SessionSnapshot {
  final String id;
  final String title;
  final DateTime time;
  final String type; // striking, grappling, conditioning, sparring
  final List<String> athleteIds;
  final bool completed;

  SessionSnapshot({
    required this.id,
    required this.title,
    required this.time,
    required this.type,
    this.athleteIds = const [],
    this.completed = false,
  });
}

class UpcomingFightSnapshot {
  final String athleteId;
  final String athleteName;
  final String opponent;
  final DateTime date;
  final String event;
  final int daysAway;

  UpcomingFightSnapshot({
    required this.athleteId,
    required this.athleteName,
    required this.opponent,
    required this.date,
    required this.event,
    required this.daysAway,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// GYM DASHBOARD DATA
/// ═══════════════════════════════════════════════════════════════════════════
class GymDashboardData {
  final String gymId;
  final String gymName;
  final String logoUrl;
  final String location;

  // Membership
  final int totalMembers;
  final int activeMembersToday;
  final int newMembersThisMonth;
  final int churnedThisMonth;
  final double memberGrowthRate;

  // Classes
  final List<ClassSnapshot> todayClasses;
  final int classesCompleted;
  final int classesRemaining;
  final double avgClassAttendance;

  // Staff
  final int totalCoaches;
  final int coachesOnDuty;
  final List<StaffSnapshot> staff;

  // Financials
  final double monthlyRevenue;
  final double yearlyRevenue;
  final double pendingDues;
  final int activeSubscriptions;

  // Facilities
  final int occupancyNow;
  final int maxCapacity;
  final double occupancyPercent;

  // Events
  final List<GymEventSnapshot> upcomingEvents;

  // Insights
  final List<String> atlasInsights;

  GymDashboardData({
    required this.gymId,
    required this.gymName,
    this.logoUrl = '',
    this.location = '',
    this.totalMembers = 0,
    this.activeMembersToday = 0,
    this.newMembersThisMonth = 0,
    this.churnedThisMonth = 0,
    this.memberGrowthRate = 0,
    this.todayClasses = const [],
    this.classesCompleted = 0,
    this.classesRemaining = 0,
    this.avgClassAttendance = 0,
    this.totalCoaches = 0,
    this.coachesOnDuty = 0,
    this.staff = const [],
    this.monthlyRevenue = 0,
    this.yearlyRevenue = 0,
    this.pendingDues = 0,
    this.activeSubscriptions = 0,
    this.occupancyNow = 0,
    this.maxCapacity = 100,
    this.occupancyPercent = 0,
    this.upcomingEvents = const [],
    this.atlasInsights = const [],
  });
}

class ClassSnapshot {
  final String id;
  final String name;
  final String type;
  final DateTime time;
  final String coachName;
  final int enrolled;
  final int capacity;
  final bool completed;

  ClassSnapshot({
    required this.id,
    required this.name,
    required this.type,
    required this.time,
    required this.coachName,
    this.enrolled = 0,
    this.capacity = 20,
    this.completed = false,
  });
}

class StaffSnapshot {
  final String id;
  final String name;
  final String role;
  final bool onDuty;

  StaffSnapshot({
    required this.id,
    required this.name,
    required this.role,
    this.onDuty = false,
  });
}

class GymEventSnapshot {
  final String id;
  final String title;
  final DateTime date;
  final String type; // seminar, tournament, open-mat, etc.
  final int registered;

  GymEventSnapshot({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.registered = 0,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER DASHBOARD DATA
/// ═══════════════════════════════════════════════════════════════════════════
class PromoterDashboardData {
  final String promoterId;
  final String organizationName;
  final String logoUrl;

  // Events
  final List<PromotedEventSnapshot> upcomingEvents;
  final List<PromotedEventSnapshot> pastEvents;
  final int totalEventsThisYear;
  final int fightsPutOn;

  // Fighter Roster
  final int contractedFighters;
  final List<ContractedFighterSnapshot> topFighters;

  // Sales
  final double ticketSalesTotal;
  final double ppvRevenue;
  final double sponsorshipRevenue;
  final double merchandiseRevenue;
  final double totalRevenue;

  // Streaming
  final int liveViewersNow;
  final int peakViewersLast;
  final int totalSubscribers;

  // Matchmaking
  final List<PendingMatchup> pendingMatchups;
  final int matchupsConfirmed;

  // Insights
  final List<String> atlasInsights;

  PromoterDashboardData({
    required this.promoterId,
    required this.organizationName,
    this.logoUrl = '',
    this.upcomingEvents = const [],
    this.pastEvents = const [],
    this.totalEventsThisYear = 0,
    this.fightsPutOn = 0,
    this.contractedFighters = 0,
    this.topFighters = const [],
    this.ticketSalesTotal = 0,
    this.ppvRevenue = 0,
    this.sponsorshipRevenue = 0,
    this.merchandiseRevenue = 0,
    this.totalRevenue = 0,
    this.liveViewersNow = 0,
    this.peakViewersLast = 0,
    this.totalSubscribers = 0,
    this.pendingMatchups = const [],
    this.matchupsConfirmed = 0,
    this.atlasInsights = const [],
  });
}

class PromotedEventSnapshot {
  final String id;
  final String title;
  final DateTime date;
  final String venue;
  final int bouts;
  final int ticketsSold;
  final int capacity;
  final double revenue;
  final String status; // upcoming, live, completed, cancelled

  PromotedEventSnapshot({
    required this.id,
    required this.title,
    required this.date,
    required this.venue,
    this.bouts = 0,
    this.ticketsSold = 0,
    this.capacity = 5000,
    this.revenue = 0,
    this.status = 'upcoming',
  });
}

class ContractedFighterSnapshot {
  final String id;
  final String name;
  final String weightClass;
  final String record;
  final String status; // active, injured, retired

  ContractedFighterSnapshot({
    required this.id,
    required this.name,
    required this.weightClass,
    required this.record,
    this.status = 'active',
  });
}

class PendingMatchup {
  final String fighter1Id;
  final String fighter1Name;
  final String fighter2Id;
  final String fighter2Name;
  final String weightClass;
  final String eventId;
  final String status; // proposed, negotiating, confirmed

  PendingMatchup({
    required this.fighter1Id,
    required this.fighter1Name,
    required this.fighter2Id,
    required this.fighter2Name,
    required this.weightClass,
    required this.eventId,
    this.status = 'proposed',
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FAN DASHBOARD DATA
/// ═══════════════════════════════════════════════════════════════════════════
class FanDashboardData {
  final String fanId;
  final String displayName;
  final String photoUrl;

  // Favorites
  final List<FavoriteFighterSnapshot> favoriteFighters;
  final List<FavoriteEventSnapshot> favoriteEvents;
  final List<String> followedGyms;

  // Upcoming
  final List<UpcomingEventPreview> upcomingEvents;
  final int eventsOnCalendar;

  // Social
  final int friendCount;
  final int postsThisWeek;
  final int commentsThisWeek;
  final int reactionsReceived;

  // Predictions
  final int predictionsCorrect;
  final int predictionsTotal;
  final double predictionAccuracy;
  final int predictionStreak;
  final int leaderboardRank;

  // Watch History
  final int eventsWatched;
  final int minutesWatched;
  final String topWatchedFighter;

  // Rewards
  final int loyaltyPoints;
  final int badgesEarned;
  final String memberTier; // bronze, silver, gold, platinum

  // Insights
  final List<String> atlasInsights;

  FanDashboardData({
    required this.fanId,
    required this.displayName,
    this.photoUrl = '',
    this.favoriteFighters = const [],
    this.favoriteEvents = const [],
    this.followedGyms = const [],
    this.upcomingEvents = const [],
    this.eventsOnCalendar = 0,
    this.friendCount = 0,
    this.postsThisWeek = 0,
    this.commentsThisWeek = 0,
    this.reactionsReceived = 0,
    this.predictionsCorrect = 0,
    this.predictionsTotal = 0,
    this.predictionAccuracy = 0,
    this.predictionStreak = 0,
    this.leaderboardRank = 0,
    this.eventsWatched = 0,
    this.minutesWatched = 0,
    this.topWatchedFighter = '',
    this.loyaltyPoints = 0,
    this.badgesEarned = 0,
    this.memberTier = 'bronze',
    this.atlasInsights = const [],
  });
}

class FavoriteFighterSnapshot {
  final String id;
  final String name;
  final String photoUrl;
  final String record;
  final DateTime? nextFight;

  FavoriteFighterSnapshot({
    required this.id,
    required this.name,
    this.photoUrl = '',
    this.record = '',
    this.nextFight,
  });
}

class FavoriteEventSnapshot {
  final String id;
  final String title;
  final DateTime date;
  final bool hasPurchasedTicket;

  FavoriteEventSnapshot({
    required this.id,
    required this.title,
    required this.date,
    this.hasPurchasedTicket = false,
  });
}

class UpcomingEventPreview {
  final String id;
  final String title;
  final DateTime date;
  final String mainEvent;
  final int daysAway;
  final bool isOnCalendar;

  UpcomingEventPreview({
    required this.id,
    required this.title,
    required this.date,
    required this.mainEvent,
    required this.daysAway,
    this.isOnCalendar = false,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ROLE DASHBOARD CONTROLLER
/// ═══════════════════════════════════════════════════════════════════════════
class RoleDashboardController with EventBusEngine, ChangeNotifier {
  static final RoleDashboardController _instance =
      RoleDashboardController._internal();
  factory RoleDashboardController() => _instance;
  RoleDashboardController._internal();

  @override
  String get engineId => 'role_dashboard';
  @override
  EventCategory get engineCategory => EventCategory.content;

  final _db = FirebaseFirestore.instance;
  final _atlas = Atlas2Intelligence();

  // Current user context
  String? _userId;
  DFCRole? _userRole;

  // Cached dashboard data
  FighterDashboardData? _fighterData;
  CoachDashboardData? _coachData;
  GymDashboardData? _gymData;
  PromoterDashboardData? _promoterData;
  FanDashboardData? _fanData;

  bool _loading = false;
  String? _error;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> initialize(String userId) async {
    _userId = userId;

    // Determine user's role from Firestore
    final userDoc = await _db.collection('users').doc(userId).get();
    final roleString = userDoc.data()?['role'] as String? ?? 'fan';
    _userRole = _parseRole(roleString);

    // Subscribe to relevant events
    listenToEvents(category: engineCategory, onEvent: _handleContentEvent);

    // Load dashboard data
    await refresh();
  }

  DFCRole _parseRole(String roleString) {
    return DFCRole.values.firstWhere(
      (r) => r.name == roleString.toLowerCase(),
      orElse: () => DFCRole.fan,
    );
  }

  void _handleContentEvent(DFCEvent event) {
    // Refresh dashboard when relevant data changes
    if (event.type.contains('created') ||
        event.type.contains('updated') ||
        event.type.contains('completed')) {
      refresh();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REFRESH
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> refresh() async {
    if (_userId == null || _userRole == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      switch (_userRole!) {
        case DFCRole.fighter:
          _fighterData = await _loadFighterDashboard(_userId!);
          break;
        case DFCRole.coach:
          _coachData = await _loadCoachDashboard(_userId!);
          break;
        case DFCRole.gym:
          _gymData = await _loadGymDashboard(_userId!);
          break;
        case DFCRole.promoter:
          _promoterData = await _loadPromoterDashboard(_userId!);
          break;
        case DFCRole.fan:
        case DFCRole.admin:
          _fanData = await _loadFanDashboard(_userId!);
          break;
      }

      await emitEvent('dashboard.loaded', {
        'userId': _userId,
        'role': _userRole!.name,
      });
    } catch (e) {
      _error = e.toString();
      debugPrint('[RoleDashboard] Error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHTER DASHBOARD LOADER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<FighterDashboardData> _loadFighterDashboard(String fighterId) async {
    // Load fighter profile
    final fighterDoc = await _db.collection('fighters').doc(fighterId).get();
    final fighterData = fighterDoc.data() ?? {};

    // Load stats
    final statsDoc = await _db.collection('fighter_stats').doc(fighterId).get();
    final stats = statsDoc.data() ?? {};

    // Load health data
    final healthDoc = await _db
        .collection('fighter_health')
        .doc(fighterId)
        .get();
    final health = healthDoc.data() ?? {};

    // Load upcoming fight
    final upcomingFights = await _db
        .collection('fights')
        .where('fighters', arrayContains: fighterId)
        .where('date', isGreaterThan: Timestamp.now())
        .orderBy('date')
        .limit(1)
        .get();

    // Get ATLAS insights for this fighter
    final insights = _atlas.getInsightsForUser(fighterId);
    final insightSummaries = insights.take(5).map((i) => i.summary).toList();

    // Build dashboard data
    final nextFight = upcomingFights.docs.isNotEmpty
        ? upcomingFights.docs.first.data()
        : null;

    return FighterDashboardData(
      fighterId: fighterId,
      displayName: fighterData['displayName'] ?? 'Fighter',
      photoUrl: fighterData['photoUrl'] ?? '',
      weightClass: fighterData['weightClass'] ?? '',
      readinessScore: (health['readinessScore'] ?? 85).toDouble(),
      recoveryScore: (health['recoveryScore'] ?? 80).toDouble(),
      hoursSlept: health['hoursSlept'] ?? 7,
      restingHR: health['restingHR'] ?? 60,
      trainingDaysThisWeek: stats['trainingDaysThisWeek'] ?? 0,
      weeklyLoadScore: (stats['weeklyLoadScore'] ?? 0).toDouble(),
      currentPhase: stats['currentPhase'] ?? 'base',
      nextFightDate: nextFight != null
          ? (nextFight['date'] as Timestamp).toDate()
          : null,
      opponent: nextFight?['opponent'],
      eventName: nextFight?['eventName'],
      daysUntilFight: nextFight != null
          ? (nextFight['date'] as Timestamp)
                .toDate()
                .difference(DateTime.now())
                .inDays
          : null,
      wins: stats['wins'] ?? 0,
      losses: stats['losses'] ?? 0,
      draws: stats['draws'] ?? 0,
      knockouts: stats['knockouts'] ?? 0,
      submissions: stats['submissions'] ?? 0,
      fightStyle: fighterData['fightStyle'] ?? 'All-Around',
      totalEarnings: (stats['totalEarnings'] ?? 0).toDouble(),
      pendingPayouts: (stats['pendingPayouts'] ?? 0).toDouble(),
      sponsorDeals: stats['sponsorDeals'] ?? 0,
      followers: stats['followers'] ?? 0,
      fanMessages: stats['fanMessages'] ?? 0,
      postLikes: stats['postLikes'] ?? 0,
      atlasInsights: insightSummaries,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COACH DASHBOARD LOADER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<CoachDashboardData> _loadCoachDashboard(String coachId) async {
    final coachDoc = await _db.collection('coaches').doc(coachId).get();
    final coachData = coachDoc.data() ?? {};

    // Load athletes
    final athletesSnapshot = await _db
        .collection('fighters')
        .where('coachId', isEqualTo: coachId)
        .get();

    final athletes = athletesSnapshot.docs.map((doc) {
      final data = doc.data();
      return AthleteSnapshot(
        id: doc.id,
        name: data['displayName'] ?? 'Athlete',
        photoUrl: data['photoUrl'] ?? '',
        readiness: (data['readinessScore'] ?? 80).toDouble(),
        status: data['status'] ?? 'training',
      );
    }).toList();

    // Load today's sessions
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final sessionsSnapshot = await _db
        .collection('training_sessions')
        .where('coachId', isEqualTo: coachId)
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final sessions = sessionsSnapshot.docs.map((doc) {
      final data = doc.data();
      return SessionSnapshot(
        id: doc.id,
        title: data['title'] ?? 'Session',
        time: (data['time'] as Timestamp).toDate(),
        type: data['type'] ?? 'training',
        completed: data['completed'] ?? false,
      );
    }).toList();

    // Get ATLAS insights
    final insights = _atlas.getInsightsByDomain(SignalDomain.training);
    final insightSummaries = insights.take(5).map((i) => i.summary).toList();

    return CoachDashboardData(
      coachId: coachId,
      displayName: coachData['displayName'] ?? 'Coach',
      photoUrl: coachData['photoUrl'] ?? '',
      gymAffiliation: coachData['gymAffiliation'] ?? '',
      totalAthletes: athletes.length,
      athletes: athletes,
      athletesInCamp: athletes.where((a) => a.status == 'fight-camp').length,
      athletesRecovering: athletes
          .where((a) => a.status == 'recovering')
          .length,
      todaySessions: sessions,
      sessionsCompleted: sessions.where((s) => s.completed).length,
      sessionsRemaining: sessions.where((s) => !s.completed).length,
      teamWinsThisYear: coachData['teamWinsThisYear'] ?? 0,
      teamLossesThisYear: coachData['teamLossesThisYear'] ?? 0,
      monthlyRevenue: (coachData['monthlyRevenue'] ?? 0).toDouble(),
      atlasInsights: insightSummaries,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GYM DASHBOARD LOADER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<GymDashboardData> _loadGymDashboard(String gymId) async {
    final gymDoc = await _db.collection('gyms').doc(gymId).get();
    final gymData = gymDoc.data() ?? {};

    // Load membership stats
    final membersSnapshot = await _db
        .collection('gym_members')
        .where('gymId', isEqualTo: gymId)
        .where('status', isEqualTo: 'active')
        .get();

    // Load today's classes
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final classesSnapshot = await _db
        .collection('gym_classes')
        .where('gymId', isEqualTo: gymId)
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final classes = classesSnapshot.docs.map((doc) {
      final data = doc.data();
      return ClassSnapshot(
        id: doc.id,
        name: data['name'] ?? 'Class',
        type: data['type'] ?? 'general',
        time: (data['time'] as Timestamp).toDate(),
        coachName: data['coachName'] ?? '',
        enrolled: data['enrolled'] ?? 0,
        capacity: data['capacity'] ?? 20,
        completed: data['completed'] ?? false,
      );
    }).toList();

    // Get ATLAS insights
    final insights = _atlas.recentInsights
        .take(5)
        .map((i) => i.summary)
        .toList();

    return GymDashboardData(
      gymId: gymId,
      gymName: gymData['name'] ?? 'Gym',
      logoUrl: gymData['logoUrl'] ?? '',
      location: gymData['location'] ?? '',
      totalMembers: membersSnapshot.docs.length,
      todayClasses: classes,
      classesCompleted: classes.where((c) => c.completed).length,
      classesRemaining: classes.where((c) => !c.completed).length,
      monthlyRevenue: (gymData['monthlyRevenue'] ?? 0).toDouble(),
      maxCapacity: gymData['maxCapacity'] ?? 100,
      atlasInsights: insights,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROMOTER DASHBOARD LOADER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PromoterDashboardData> _loadPromoterDashboard(
    String promoterId,
  ) async {
    final promoterDoc = await _db.collection('promoters').doc(promoterId).get();
    final promoterData = promoterDoc.data() ?? {};

    // Load upcoming events
    final eventsSnapshot = await _db
        .collection('events')
        .where('promoterId', isEqualTo: promoterId)
        .where('date', isGreaterThan: Timestamp.now())
        .orderBy('date')
        .limit(10)
        .get();

    final events = eventsSnapshot.docs.map((doc) {
      final data = doc.data();
      return PromotedEventSnapshot(
        id: doc.id,
        title: data['title'] ?? 'Event',
        date: (data['date'] as Timestamp).toDate(),
        venue: data['venue'] ?? '',
        bouts: data['bouts'] ?? 0,
        ticketsSold: data['ticketsSold'] ?? 0,
        capacity: data['capacity'] ?? 5000,
        revenue: (data['revenue'] ?? 0).toDouble(),
        status: data['status'] ?? 'upcoming',
      );
    }).toList();

    // Load contracted fighters
    final fightersSnapshot = await _db
        .collection('fighter_contracts')
        .where('promoterId', isEqualTo: promoterId)
        .where('status', isEqualTo: 'active')
        .get();

    // Get ATLAS insights
    final insights = _atlas.getInsightsByDomain(SignalDomain.streaming);
    final insightSummaries = insights.take(5).map((i) => i.summary).toList();

    return PromoterDashboardData(
      promoterId: promoterId,
      organizationName: promoterData['organizationName'] ?? 'Promotion',
      logoUrl: promoterData['logoUrl'] ?? '',
      upcomingEvents: events,
      totalEventsThisYear: promoterData['eventsThisYear'] ?? 0,
      contractedFighters: fightersSnapshot.docs.length,
      ticketSalesTotal: (promoterData['ticketSalesTotal'] ?? 0).toDouble(),
      ppvRevenue: (promoterData['ppvRevenue'] ?? 0).toDouble(),
      sponsorshipRevenue: (promoterData['sponsorshipRevenue'] ?? 0).toDouble(),
      totalRevenue: (promoterData['totalRevenue'] ?? 0).toDouble(),
      atlasInsights: insightSummaries,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAN DASHBOARD LOADER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<FanDashboardData> _loadFanDashboard(String fanId) async {
    final userDoc = await _db.collection('users').doc(fanId).get();
    final userData = userDoc.data() ?? {};

    // Load favorites
    final favoritesDoc = await _db
        .collection('user_favorites')
        .doc(fanId)
        .get();
    final favorites = favoritesDoc.data() ?? {};
    final favoriteFighterIds = List<String>.from(favorites['fighters'] ?? []);

    // Load favorite fighters details
    final favoriteFighters = <FavoriteFighterSnapshot>[];
    for (final fid in favoriteFighterIds.take(5)) {
      final fighterDoc = await _db.collection('fighters').doc(fid).get();
      if (fighterDoc.exists) {
        final data = fighterDoc.data()!;
        favoriteFighters.add(
          FavoriteFighterSnapshot(
            id: fid,
            name: data['displayName'] ?? 'Fighter',
            photoUrl: data['photoUrl'] ?? '',
            record: '${data['wins'] ?? 0}-${data['losses'] ?? 0}',
          ),
        );
      }
    }

    // Load predictions
    final predictionsDoc = await _db
        .collection('user_predictions')
        .doc(fanId)
        .get();
    final predictions = predictionsDoc.data() ?? {};

    // Get upcoming events
    final eventsSnapshot = await _db
        .collection('events')
        .where('date', isGreaterThan: Timestamp.now())
        .orderBy('date')
        .limit(5)
        .get();

    final upcomingEvents = eventsSnapshot.docs.map((doc) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      return UpcomingEventPreview(
        id: doc.id,
        title: data['title'] ?? 'Event',
        date: date,
        mainEvent: data['mainEvent'] ?? '',
        daysAway: date.difference(DateTime.now()).inDays,
      );
    }).toList();

    return FanDashboardData(
      fanId: fanId,
      displayName: userData['displayName'] ?? 'Fan',
      photoUrl: userData['photoUrl'] ?? '',
      favoriteFighters: favoriteFighters,
      upcomingEvents: upcomingEvents,
      friendCount: userData['friendCount'] ?? 0,
      predictionsCorrect: predictions['correct'] ?? 0,
      predictionsTotal: predictions['total'] ?? 0,
      predictionAccuracy:
          predictions['total'] != null && predictions['total'] > 0
          ? (predictions['correct'] ?? 0) / predictions['total'] * 100
          : 0,
      predictionStreak: predictions['streak'] ?? 0,
      leaderboardRank: predictions['rank'] ?? 0,
      loyaltyPoints: userData['loyaltyPoints'] ?? 0,
      badgesEarned: userData['badges']?.length ?? 0,
      memberTier: userData['memberTier'] ?? 'bronze',
      atlasInsights: [
        'Check out upcoming events!',
        'Your prediction streak is growing!',
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  bool get loading => _loading;
  String? get error => _error;
  DFCRole? get currentRole => _userRole;

  FighterDashboardData? get fighterDashboard => _fighterData;
  CoachDashboardData? get coachDashboard => _coachData;
  GymDashboardData? get gymDashboard => _gymData;
  PromoterDashboardData? get promoterDashboard => _promoterData;
  FanDashboardData? get fanDashboard => _fanData;

  /// Get the appropriate dashboard data based on role
  dynamic get currentDashboard {
    switch (_userRole) {
      case DFCRole.fighter:
        return _fighterData;
      case DFCRole.coach:
        return _coachData;
      case DFCRole.gym:
        return _gymData;
      case DFCRole.promoter:
        return _promoterData;
      case DFCRole.fan:
      case DFCRole.admin:
      case null:
        return _fanData;
    }
  }

  @override
  void dispose() {
    disposeEngineSubscriptions();
    super.dispose();
  }
}
