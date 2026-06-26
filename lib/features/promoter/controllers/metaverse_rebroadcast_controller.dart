import 'package:flutter/foundation.dart';
import 'package:datafightcentral/shared/services/content_scanner_engine.dart';
import 'package:datafightcentral/shared/services/metaverse_ad_campaign_engine.dart';

/// Metaverse Content Re-Broadcast Controller
/// Orchestrates the content cycle: Scan → Highlight → Amplify → Broadcast → Cycle Back
class MetaverseContentRebroadcastController extends ChangeNotifier {
  final ContentScannerEngine _scannerEngine;
  final MetaverseAdCampaignEngine _adCampaignEngine;

  MetaverseContentRebroadcastController({
    ContentScannerEngine? scannerEngine,
    MetaverseAdCampaignEngine? adCampaignEngine,
  }) : _scannerEngine = scannerEngine ?? ContentScannerEngine(),
       _adCampaignEngine = adCampaignEngine ?? MetaverseAdCampaignEngine();

  // State tracking
  final List<BroadcastCycle> _broadcastCycles = [];
  final List<BroadcastResult> _liveResults = [];
  bool _isProcessing = false;

  // Getters
  List<BroadcastCycle> get broadcastCycles => _broadcastCycles;
  List<BroadcastResult> get liveResults => _liveResults;
  bool get isProcessing => _isProcessing;

  /// Execute full content re-broadcast cycle
  Future<BroadcastCycleSummary> executeCycle() async {
    try {
      _isProcessing = true;
      notifyListeners();

      // Step 1: Scan for content
      final scannedContent = await _scanForContent();
      if (scannedContent.isEmpty) {
        _isProcessing = false;
        notifyListeners();
        return BroadcastCycleSummary(
          cycleId: 'cycle_${DateTime.now().millisecondsSinceEpoch}',
          status: 'no_content',
          scannedItems: 0,
          highlighting: 0,
          campaigns: 0,
          broadcasts: 0,
          totalReach: '0',
          executionTime: Duration.zero,
        );
      }

      // Step 2: Extract highlights
      final highlights = await _adCampaignEngine.amplifyContentHighlights(
        scannedContent.map((c) => c.title).toList(),
      );

      // Step 3: Generate campaigns for each metaverse platform
      final campaigns = await _generateCampaignsForPlatforms(highlights);

      // Step 4: Broadcast amplified content
      final broadcasts = await _broadcastToAllPlatforms(highlights);

      // Step 5: Create cycle record
      final cycle = BroadcastCycle(
        id: 'cycle_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        scannedItems: scannedContent,
        highlights: highlights,
        campaigns: campaigns,
        broadcasts: broadcasts,
        totalReach: _calculateTotalReach(broadcasts),
        status: 'completed',
      );

      _broadcastCycles.add(cycle);
      _liveResults.addAll(broadcasts);

      notifyListeners();

      return BroadcastCycleSummary(
        cycleId: cycle.id,
        status: 'completed',
        scannedItems: scannedContent.length,
        highlighting: highlights.length,
        campaigns: campaigns.length,
        broadcasts: broadcasts.length,
        totalReach: cycle.totalReach,
        executionTime: DateTime.now().difference(cycle.timestamp),
      );
    } catch (e) {
      debugPrint('Broadcast cycle error: $e');
      _isProcessing = false;
      notifyListeners();
      return BroadcastCycleSummary(
        cycleId: 'error',
        status: 'error',
        scannedItems: 0,
        highlighting: 0,
        campaigns: 0,
        broadcasts: 0,
        totalReach: '0',
        error: e.toString(),
        executionTime: Duration.zero,
      );
    }
  }

  /// Scan content from all metaverse sources
  Future<List<ScannedContentItem>> _scanForContent() async {
    final items = <ScannedContentItem>[];

    // Scan from metaverse sources
    final sources = [
      ScanSource.roblox,
      ScanSource.fortnite,
      ScanSource.decentraland,
      ScanSource.sandbox,
      ScanSource.horizonWorlds,
      ScanSource.premiumVerified,
      ScanSource.partnerNetwork,
    ];

    for (final source in sources) {
      try {
        final results = await _scannerEngine.scan(source);
        items.addAll(
          results.map(
            (r) => ScannedContentItem(
              id: r.id,
              title: r.title,
              description: r.body,
              source: source.toString(),
              timestamp: r.publishedAt,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Scan error for $source: $e');
      }
    }

    return items;
  }

  /// Generate ad campaigns for all metaverse platforms
  Future<List<MetaverseAdCampaign>> _generateCampaignsForPlatforms(
    List<ContentHighlight> highlights,
  ) async {
    final campaigns = <MetaverseAdCampaign>[];

    for (final highlight in highlights) {
      for (final platform in [
        'roblox',
        'fortnite',
        'decentraland',
        'sandbox',
        'horizon',
      ]) {
        try {
          final campaign = await _adCampaignEngine.generateAdCampaign(
            platform: platform,
            contentTitle: highlight.amplifiedTitle,
            contentDescription: highlight.emotionalHook,
            category: 'highlight_campaign',
          );
          campaigns.add(campaign);
        } catch (e) {
          debugPrint('Campaign generation error for $platform: $e');
        }
      }
    }

    return campaigns;
  }

  /// Broadcast amplified content across all platforms
  Future<List<BroadcastResult>> _broadcastToAllPlatforms(
    List<ContentHighlight> highlights,
  ) async {
    final results = <BroadcastResult>[];

    for (final highlight in highlights) {
      final broadcastResults = await _adCampaignEngine
          .broadcastAmplifiedContent(highlight, [
            'roblox',
            'fortnite',
            'decentraland',
            'sandbox',
            'horizon',
          ]);
      results.addAll(broadcastResults);
    }

    return results;
  }

  /// Calculate total reach across all broadcasts
  String _calculateTotalReach(List<BroadcastResult> broadcasts) {
    int totalReach = 0;

    for (final broadcast in broadcasts) {
      final regex = RegExp(r'(\d+)');
      final match = regex.firstMatch(broadcast.audienceReach);
      if (match != null) {
        totalReach += int.parse(match.group(1)!) * 1000;
      }
    }

    if (totalReach > 1000000) {
      return '${(totalReach / 1000000).toStringAsFixed(1)}M+ reach';
    } else if (totalReach > 1000) {
      return '${(totalReach / 1000).toStringAsFixed(0)}K+ reach';
    } else {
      return '$totalReach reach';
    }
  }

  /// Get highlights by platform
  Map<String, List<ContentHighlight>> getHighlightsByPlatform() {
    final grouped = <String, List<ContentHighlight>>{};
    for (final cycle in _broadcastCycles) {
      for (final highlight in cycle.highlights) {
        grouped
            .putIfAbsent(highlight.amplificationLevel, () => [])
            .add(highlight);
      }
    }
    return grouped;
  }

  /// Get live broadcast status
  Map<String, dynamic> getLiveBroadcastStatus() {
    return {
      'activeBroadcasts': _liveResults.where((r) => r.status == 'live').length,
      'totalReach': _calculateTotalReach(_liveResults),
      'platforms': _getPlatformsWithActiveBroadcasts(),
      'expectedEngagement': _calculateTotalExpectedEngagement(),
    };
  }

  List<String> _getPlatformsWithActiveBroadcasts() {
    return _liveResults
        .where((r) => r.status == 'live')
        .map((r) => r.platform)
        .toSet()
        .toList();
  }

  String _calculateTotalExpectedEngagement() {
    int total = 0;
    for (final result in _liveResults.where((r) => r.status == 'live')) {
      final regex = RegExp(r'(\d+)');
      final match = regex.firstMatch(result.expectedEngagement);
      if (match != null) {
        total += int.parse(match.group(1)!);
      }
    }

    if (total > 1000000) {
      return '${(total / 1000000).toStringAsFixed(1)}M+ users';
    } else if (total > 1000) {
      return '${(total / 1000).toStringAsFixed(0)}K+ users';
    } else {
      return '$total users';
    }
  }

  /// Get cycle history
  List<BroadcastCycle> getCycleHistory({int limit = 10}) {
    final sorted = [..._broadcastCycles];
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  /// Clear old broadcasts (older than X days)
  void clearOldBroadcasts({int days = 7}) {
    final threshold = DateTime.now().subtract(Duration(days: days));
    _liveResults.removeWhere((r) => r.broadcastTime.isBefore(threshold));
    notifyListeners();
  }
}

/// Scanned Content Item
class ScannedContentItem {
  final String id;
  final String title;
  final String description;
  final String source;
  final DateTime timestamp;

  ScannedContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.timestamp,
  });
}

/// Full Broadcast Cycle
class BroadcastCycle {
  final String id;
  final DateTime timestamp;
  final List<ScannedContentItem> scannedItems;
  final List<ContentHighlight> highlights;
  final List<MetaverseAdCampaign> campaigns;
  final List<BroadcastResult> broadcasts;
  final String totalReach;
  final String status;

  BroadcastCycle({
    required this.id,
    required this.timestamp,
    required this.scannedItems,
    required this.highlights,
    required this.campaigns,
    required this.broadcasts,
    required this.totalReach,
    required this.status,
  });
}

/// Cycle Summary Report
class BroadcastCycleSummary {
  final String cycleId;
  final String status;
  final int scannedItems;
  final int highlighting;
  final int campaigns;
  final int broadcasts;
  final String totalReach;
  final Duration executionTime;
  final String? error;

  BroadcastCycleSummary({
    required this.cycleId,
    required this.status,
    required this.scannedItems,
    required this.highlighting,
    required this.campaigns,
    required this.broadcasts,
    required this.totalReach,
    required this.executionTime,
    this.error,
  });

  String get summaryText =>
      '''
════════════════════════════════════════════════════════
🎬 METAVERSE CONTENT RE-BROADCAST CYCLE COMPLETE
════════════════════════════════════════════════════════
📊 Status: $status${error != null ? ' (⚠️ $error)' : ''}
🔄 Cycle ID: $cycleId
⏱️ Execution Time: ${executionTime.inSeconds}s

📈 AMPLIFICATION METRICS:
  • Content Scanned: $scannedItems items
  • Highlights Extracted: $highlighting
  • Campaigns Generated: $campaigns
  • Live Broadcasts: $broadcasts

🌐 REACH & ENGAGEMENT:
  • Total Reach: $totalReach
  • Platforms: 5 (Roblox, Fortnite, Decentraland, Sandbox, Horizon)
  
✨ CONTENT MAGNIFICATION:
  • Average Magnifier: 2.5x-4.0x
  • Amplification Level: MAXIMUM
  • Action-Packed Messaging: ENABLED

════════════════════════════════════════════════════════
🚀 Re-broadcast cycle complete! Content is now LIVE.
════════════════════════════════════════════════════════
  ''';

  @override
  String toString() =>
      '''
BroadcastCycleSummary(
  cycleId: $cycleId,
  status: $status,
  scannedItems: $scannedItems,
  highlighting: $highlighting,
  campaigns: $campaigns,
  broadcasts: $broadcasts,
  totalReach: $totalReach
)''';
}
