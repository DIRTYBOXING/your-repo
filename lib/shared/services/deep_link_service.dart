import 'dart:async';
import 'package:flutter/foundation.dart';

/// Deep link routing targets.
enum DeepLinkTarget {
  event,
  fighter,
  post,
  profile,
  ppv,
  gym,
  article,
  invite,
  unknown,
}

/// A parsed deep link with route info.
class ParsedDeepLink {
  final DeepLinkTarget target;
  final String? id;
  final Map<String, String> queryParams;
  final String rawUri;

  const ParsedDeepLink({
    required this.target,
    this.id,
    this.queryParams = const {},
    required this.rawUri,
  });
}

/// Handles incoming deep links / universal links so shared fight URLs
/// open directly in the app instead of the browser.
///
/// Supports:
/// - datafightcentral.com/event/{id}
/// - datafightcentral.com/fighter/{id}
/// - datafightcentral.com/post/{id}
/// - datafightcentral.com/ppv/{id}
/// - datafightcentral.com/invite/{code}
class DeepLinkService extends ChangeNotifier {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  bool _isInitialized = false;
  ParsedDeepLink? _pendingLink;
  final List<ParsedDeepLink> _linkHistory = [];
  StreamSubscription? _linkSub;

  // Callback for when a deep link is received and needs routing
  void Function(ParsedDeepLink link)? onLinkReceived;

  // ── Getters ───────────────────────────────────────────────────────────
  bool get isInitialized => _isInitialized;
  ParsedDeepLink? get pendingLink => _pendingLink;
  List<ParsedDeepLink> get linkHistory => List.unmodifiable(_linkHistory);

  // ── Init ──────────────────────────────────────────────────────────────

  /// Initialize deep link handling. Call in app startup.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Handle cold start (app opened from a link)
    await _handleInitialLink();

    // Handle links while app is running
    _listenForLinks();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _handleInitialLink() async {
    // On web, check window.location
    if (kIsWeb) {
      _handleWebUrl();
      return;
    }

    // On native, app_links package handles initial URI
    // This is wired when the package is configured in AndroidManifest/Info.plist
    // For now, the framework handles initial URI via onGenerateRoute or GoRouter
  }

  void _handleWebUrl() {
    // On web, the URL is already handled by GoRouter's URL strategy
    // This method exists for explicit link tracking/analytics
  }

  void _listenForLinks() {
    // app_links stream subscription would go here for native platforms
    // On web, GoRouter handles URL changes automatically
  }

  // ── Link Parsing ──────────────────────────────────────────────────────

  /// Parse a URL string into a routable deep link.
  ParsedDeepLink parseLink(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      if (segments.isEmpty) {
        return ParsedDeepLink(target: DeepLinkTarget.unknown, rawUri: url);
      }

      final targetStr = segments.first.toLowerCase();
      final id = segments.length > 1 ? segments[1] : null;

      DeepLinkTarget target;
      switch (targetStr) {
        case 'event':
        case 'events':
          target = DeepLinkTarget.event;
          break;
        case 'fighter':
        case 'fighters':
          target = DeepLinkTarget.fighter;
          break;
        case 'post':
        case 'posts':
          target = DeepLinkTarget.post;
          break;
        case 'profile':
        case 'user':
          target = DeepLinkTarget.profile;
          break;
        case 'ppv':
          target = DeepLinkTarget.ppv;
          break;
        case 'gym':
        case 'gyms':
          target = DeepLinkTarget.gym;
          break;
        case 'article':
        case 'articles':
        case 'blog':
          target = DeepLinkTarget.article;
          break;
        case 'invite':
        case 'join':
          target = DeepLinkTarget.invite;
          break;
        default:
          target = DeepLinkTarget.unknown;
      }

      return ParsedDeepLink(
        target: target,
        id: id,
        queryParams: uri.queryParameters,
        rawUri: url,
      );
    } catch (_) {
      return ParsedDeepLink(target: DeepLinkTarget.unknown, rawUri: url);
    }
  }

  /// Handle an incoming deep link — parse and route.
  void handleIncomingLink(String url) {
    final parsed = parseLink(url);
    _pendingLink = parsed;
    _linkHistory.add(parsed);
    notifyListeners();

    // Fire callback if registered
    onLinkReceived?.call(parsed);
  }

  /// Consume the pending link (called after routing completes).
  void consumePendingLink() {
    _pendingLink = null;
    notifyListeners();
  }

  // ── Link Generation ───────────────────────────────────────────────────

  static const String _baseUrl = 'https://datafightcentral.com';

  /// Generate a shareable link for an event.
  String eventLink(String eventId) => '$_baseUrl/event/$eventId';

  /// Generate a shareable link for a fighter profile.
  String fighterLink(String fighterId) => '$_baseUrl/fighter/$fighterId';

  /// Generate a shareable link for a post.
  String postLink(String postId) => '$_baseUrl/post/$postId';

  /// Generate a shareable link for a PPV event.
  String ppvLink(String ppvId) => '$_baseUrl/ppv/$ppvId';

  /// Generate a shareable link for a gym.
  String gymLink(String gymId) => '$_baseUrl/gym/$gymId';

  /// Generate an invite link with referral code.
  String inviteLink(String code) => '$_baseUrl/invite/$code';

  /// Generate a link for an article.
  String articleLink(String articleId) => '$_baseUrl/article/$articleId';

  // ── GoRouter Integration ──────────────────────────────────────────────

  /// Convert a ParsedDeepLink to a GoRouter path.
  String toRouterPath(ParsedDeepLink link) {
    switch (link.target) {
      case DeepLinkTarget.event:
        return '/event/${link.id ?? ''}';
      case DeepLinkTarget.fighter:
        return '/fighter/${link.id ?? ''}';
      case DeepLinkTarget.post:
        return '/post/${link.id ?? ''}';
      case DeepLinkTarget.profile:
        return '/profile/${link.id ?? ''}';
      case DeepLinkTarget.ppv:
        return '/ppv/${link.id ?? ''}';
      case DeepLinkTarget.gym:
        return '/gym/${link.id ?? ''}';
      case DeepLinkTarget.article:
        return '/article/${link.id ?? ''}';
      case DeepLinkTarget.invite:
        return '/invite/${link.id ?? ''}';
      case DeepLinkTarget.unknown:
        return '/';
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }
}
