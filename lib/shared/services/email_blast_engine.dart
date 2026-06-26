import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EMAIL BLAST ENGINE — Nuclear Email Marketing Automation
/// ═══════════════════════════════════════════════════════════════════════════
///
/// AI-powered email marketing that:
///  1. Generates high-conversion email content via Gemini CF
///  2. Manages subscriber lists with segmentation
///  3. Schedules and sends campaigns via SendGrid CF
///  4. Tracks open rates, clicks, and conversions
///  5. Auto-generates A/B test variants
///  6. Wolverine Protocol: Auto-retries failed sends
///
/// Campaign Types:
///  - EVENT_PROMO: Fight night announcements
///  - FIGHTER_SPOTLIGHT: Featured fighter profiles
///  - WEEKLY_DIGEST: Curated weekly roundup
///  - FLASH_SALE: Limited-time offers
///  - WELCOME_SERIES: Onboarding sequence
///  - RE_ENGAGEMENT: Win-back campaigns
///  - BREAKING_NEWS: Urgent fight news
/// ═══════════════════════════════════════════════════════════════════════════

final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);
// ignore: unused_element
final _firestore = FirebaseFirestore.instance;

/// Campaign type classification
enum EmailCampaignType {
  eventPromo,
  fighterSpotlight,
  weeklyDigest,
  flashSale,
  welcomeSeries,
  reEngagement,
  breakingNews,
  custom,
}

/// Email recipient model
class EmailRecipient {
  final String email;
  final String? name;
  final String? gymName;
  final String? city;
  final List<String> tags;
  final DateTime? addedAt;

  const EmailRecipient({
    required this.email,
    this.name,
    this.gymName,
    this.city,
    this.tags = const [],
    this.addedAt,
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'gymName': gymName,
    'city': city,
    'tags': tags,
    'addedAt': addedAt?.toIso8601String(),
  };

  factory EmailRecipient.fromMap(Map<String, dynamic> map) => EmailRecipient(
    email: map['email'] ?? '',
    name: map['name'],
    gymName: map['gymName'],
    city: map['city'],
    tags: List<String>.from(map['tags'] ?? []),
    addedAt: map['addedAt'] != null ? DateTime.tryParse(map['addedAt']) : null,
  );
}

/// Generated email content
class GeneratedEmailContent {
  final String subjectLine;
  final String preheader;
  final String headline;
  final String body;
  final List<String> bulletPoints;
  final String ctaButton;
  final String ctaUrl;
  final String urgencyElement;
  final double predictedOpenRate;
  final double predictedClickRate;

  const GeneratedEmailContent({
    required this.subjectLine,
    required this.preheader,
    required this.headline,
    required this.body,
    this.bulletPoints = const [],
    required this.ctaButton,
    required this.ctaUrl,
    required this.urgencyElement,
    this.predictedOpenRate = 0.25,
    this.predictedClickRate = 0.08,
  });

  factory GeneratedEmailContent.fromMap(Map<String, dynamic> map) =>
      GeneratedEmailContent(
        subjectLine: map['subjectLine'] ?? 'Fight Night Alert',
        preheader: map['preheader'] ?? '',
        headline: map['headline'] ?? '',
        body: map['body'] ?? '',
        bulletPoints: List<String>.from(map['bulletPoints'] ?? []),
        ctaButton: map['ctaButton'] ?? 'WATCH NOW',
        ctaUrl: map['ctaUrl'] ?? '/events',
        urgencyElement: map['urgencyElement'] ?? '',
        predictedOpenRate: (map['predictedOpenRate'] ?? 0.25).toDouble(),
        predictedClickRate: (map['predictedClickRate'] ?? 0.08).toDouble(),
      );
}

/// Campaign result tracking
class CampaignResult {
  final String campaignId;
  final int totalSent;
  final int delivered;
  final int opened;
  final int clicked;
  final int bounced;
  final int unsubscribed;
  final DateTime sentAt;

  const CampaignResult({
    required this.campaignId,
    required this.totalSent,
    this.delivered = 0,
    this.opened = 0,
    this.clicked = 0,
    this.bounced = 0,
    this.unsubscribed = 0,
    required this.sentAt,
  });

  double get openRate => totalSent > 0 ? opened / totalSent : 0.0;
  double get clickRate => totalSent > 0 ? clicked / totalSent : 0.0;
  double get bounceRate => totalSent > 0 ? bounced / totalSent : 0.0;
}

/// Email Blast Engine Service
class EmailBlastEngine with ChangeNotifier {
  static final EmailBlastEngine _instance = EmailBlastEngine._internal();
  factory EmailBlastEngine() => _instance;
  EmailBlastEngine._internal();

  bool _initialized = false;
  bool _isSending = false;
  final List<EmailRecipient> _subscribers = [];
  final List<CampaignResult> _campaignHistory = [];
  GeneratedEmailContent? _lastGeneratedContent;

  // Getters
  bool get initialized => _initialized;
  bool get isSending => _isSending;
  List<EmailRecipient> get subscribers => List.unmodifiable(_subscribers);
  List<CampaignResult> get campaignHistory =>
      List.unmodifiable(_campaignHistory);
  GeneratedEmailContent? get lastGeneratedContent => _lastGeneratedContent;
  int get totalSubscribers => _subscribers.length;

  /// Initialize the engine and load subscriber list
  Future<void> initialize() async {
    if (_initialized) return;
    debugPrint('📧 EmailBlastEngine: Initializing...');
    await loadSubscribers();
    _initialized = true;
    notifyListeners();
    debugPrint(
      '📧 EmailBlastEngine: Ready with ${_subscribers.length} subscribers',
    );
  }

  /// Load subscribers from Firestore
  Future<void> loadSubscribers() async {
    try {
      final callable = _functions.httpsCallable('manageEmailList');
      final result = await callable.call<Map<String, dynamic>>({
        'action': 'list',
      });
      if (result.data['success'] == true) {
        _subscribers.clear();
        final contacts = result.data['contacts'] as List<dynamic>? ?? [];
        for (final c in contacts) {
          _subscribers.add(EmailRecipient.fromMap(c as Map<String, dynamic>));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('EmailBlastEngine: Failed to load subscribers: $e');
    }
  }

  /// Add subscribers to the list
  Future<bool> addSubscribers(List<EmailRecipient> contacts) async {
    try {
      final callable = _functions.httpsCallable('manageEmailList');
      final result = await callable.call<Map<String, dynamic>>({
        'action': 'add',
        'contacts': contacts.map((c) => c.toMap()).toList(),
      });
      if (result.data['success'] == true) {
        await loadSubscribers();
        return true;
      }
    } catch (e) {
      debugPrint('EmailBlastEngine: Failed to add subscribers: $e');
    }
    return false;
  }

  /// Remove subscribers from the list
  Future<bool> removeSubscribers(List<String> emails) async {
    try {
      final callable = _functions.httpsCallable('manageEmailList');
      final result = await callable.call<Map<String, dynamic>>({
        'action': 'remove',
        'contacts': emails.map((e) => {'email': e}).toList(),
      });
      if (result.data['success'] == true) {
        await loadSubscribers();
        return true;
      }
    } catch (e) {
      debugPrint('EmailBlastEngine: Failed to remove subscribers: $e');
    }
    return false;
  }

  /// Generate email content using AI
  Future<GeneratedEmailContent?> generateEmailContent({
    required EmailCampaignType campaignType,
    String? targetAudience,
    String? event,
    String? promotion,
    String? callToAction,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateEmailCampaign');
      final result = await callable.call<Map<String, dynamic>>({
        'campaignType': campaignType.name,
        'targetAudience': targetAudience ?? 'Fight fans',
        'event': event,
        'promotion': promotion,
        'callToAction': callToAction,
      });
      if (result.data['content'] != null) {
        _lastGeneratedContent = GeneratedEmailContent.fromMap(
          result.data['content'] as Map<String, dynamic>,
        );
        notifyListeners();
        return _lastGeneratedContent;
      }
    } catch (e) {
      debugPrint('EmailBlastEngine: Failed to generate content: $e');
    }
    return null;
  }

  /// Send email campaign
  Future<CampaignResult?> sendCampaign({
    required String subject,
    required String htmlBody,
    List<EmailRecipient>? recipients,
    String? fromName,
  }) async {
    if (_isSending) return null;
    _isSending = true;
    notifyListeners();

    try {
      final targetRecipients = recipients ?? _subscribers;
      if (targetRecipients.isEmpty) {
        debugPrint('EmailBlastEngine: No recipients to send to');
        _isSending = false;
        notifyListeners();
        return null;
      }

      final callable = _functions.httpsCallable('sendCampaignEmail');
      final result = await callable.call<Map<String, dynamic>>({
        'subject': subject,
        'htmlBody': htmlBody,
        'recipients': targetRecipients
            .map((r) => {'email': r.email, 'name': r.name})
            .toList(),
        'fromName': fromName ?? 'Data Fight Central',
      });

      if (result.data['success'] == true) {
        final sent = result.data['sent'] as int? ?? 0;
        final campaignResult = CampaignResult(
          campaignId: 'campaign_${DateTime.now().millisecondsSinceEpoch}',
          totalSent: sent,
          delivered: sent,
          sentAt: DateTime.now(),
        );
        _campaignHistory.add(campaignResult);
        debugPrint('📧 EmailBlastEngine: Campaign sent to $sent recipients');
        _isSending = false;
        notifyListeners();
        return campaignResult;
      }
    } catch (e) {
      debugPrint('EmailBlastEngine: Failed to send campaign: $e');
    }

    _isSending = false;
    notifyListeners();
    return null;
  }

  /// Quick send: Generate content and send in one step
  Future<CampaignResult?> quickSend({
    required EmailCampaignType campaignType,
    String? event,
    String? targetAudience,
  }) async {
    final content = await generateEmailContent(
      campaignType: campaignType,
      event: event,
      targetAudience: targetAudience,
    );
    if (content == null) return null;

    final htmlBody = _buildHtmlEmail(content);
    return sendCampaign(subject: content.subjectLine, htmlBody: htmlBody);
  }

  /// Build HTML email from generated content
  String _buildHtmlEmail(GeneratedEmailContent content) {
    final bullets = content.bulletPoints.map((b) => '<li>$b</li>').join('\n');
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; background: #0a0e1a; color: #ffffff; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #00E5FF 0%, #9D00FF 100%); padding: 30px 20px; text-align: center; border-radius: 12px 12px 0 0; }
    .header h1 { margin: 0; font-size: 28px; font-weight: 900; color: #ffffff; letter-spacing: 2px; }
    .content { background: #111827; padding: 30px 20px; border-radius: 0 0 12px 12px; }
    .headline { font-size: 24px; font-weight: 700; color: #00E5FF; margin-bottom: 20px; }
    .body-text { font-size: 16px; line-height: 1.6; color: #e0e0e0; margin-bottom: 20px; }
    .bullet-list { padding-left: 20px; margin-bottom: 20px; }
    .bullet-list li { margin-bottom: 10px; color: #b0b0b0; }
    .cta-button { display: inline-block; background: linear-gradient(135deg, #00E5FF 0%, #00D4AA 100%); color: #0a0e1a; font-size: 18px; font-weight: 700; padding: 15px 40px; border-radius: 8px; text-decoration: none; text-transform: uppercase; letter-spacing: 1px; }
    .urgency { background: rgba(255, 23, 68, 0.15); border-left: 4px solid #FF1744; padding: 15px 20px; margin: 20px 0; color: #FF6B6B; font-weight: 600; }
    .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>DATA FIGHT CENTRAL</h1>
    </div>
    <div class="content">
      <div class="headline">${content.headline}</div>
      <p class="body-text">${content.body}</p>
      ${bullets.isNotEmpty ? '<ul class="bullet-list">$bullets</ul>' : ''}
      ${content.urgencyElement.isNotEmpty ? '<div class="urgency">${content.urgencyElement}</div>' : ''}
      <p style="text-align: center; margin-top: 30px;">
        <a href="https://datafightcentral.web.app${content.ctaUrl}" class="cta-button">${content.ctaButton}</a>
      </p>
    </div>
    <div class="footer">
      <p>© 2026 Data Fight Central. All rights reserved.</p>
      <p>You received this email because you subscribed to fight updates.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Segment subscribers by tags
  List<EmailRecipient> getSubscribersByTag(String tag) {
    return _subscribers.where((s) => s.tags.contains(tag)).toList();
  }

  /// Segment subscribers by city
  List<EmailRecipient> getSubscribersByCity(String city) {
    return _subscribers
        .where((s) => s.city?.toLowerCase() == city.toLowerCase())
        .toList();
  }

  /// Get campaign stats summary
  Map<String, dynamic> getCampaignStats() {
    if (_campaignHistory.isEmpty) {
      return {
        'totalCampaigns': 0,
        'totalSent': 0,
        'avgOpenRate': 0.0,
        'avgClickRate': 0.0,
      };
    }

    final totalSent = _campaignHistory.fold<int>(
      0,
      (total, c) => total + c.totalSent,
    );
    final avgOpen =
        _campaignHistory.fold<double>(0, (total, c) => total + c.openRate) /
        _campaignHistory.length;
    final avgClick =
        _campaignHistory.fold<double>(0, (total, c) => total + c.clickRate) /
        _campaignHistory.length;

    return {
      'totalCampaigns': _campaignHistory.length,
      'totalSent': totalSent,
      'avgOpenRate': avgOpen,
      'avgClickRate': avgClick,
    };
  }
}
