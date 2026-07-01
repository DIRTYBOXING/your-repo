import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// LIVE STREAM HUB — Central streaming dashboard.
/// Live events · Stream health · Viewer analytics · Ingest status
class LiveStreamHubScreen extends StatefulWidget {
  const LiveStreamHubScreen({super.key});

  @override
  State<LiveStreamHubScreen> createState() => _LiveStreamHubScreenState();
}

class _LiveStreamHubScreenState extends State<LiveStreamHubScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Row(
          children: [
            Icon(Icons.cell_tower, color: DesignTokens.neonRed, size: 22),
            SizedBox(width: 8),
            Text(
              'LIVE STREAM HUB',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: DesignTokens.neonRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DesignTokens.neonRed.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: DesignTokens.neonRed, size: 8),
                SizedBox(width: 6),
                Text(
                  '2 LIVE',
                  style: TextStyle(
                    color: DesignTokens.neonRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── GLOBAL VIEWER BANNER ──
          _viewerBanner(),
          const SizedBox(height: 16),

          // ── ACTIVE STREAMS ──
          const Text(
            'ACTIVE STREAMS',
            style: TextStyle(
              color: DesignTokens.neonRed,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          _streamCard(
            'BKFC Fight Night — Hepi vs Wisniewski',
            'LIVE',
            DesignTokens.neonRed,
            viewers: 14200,
            bitrate: '4.2 Mbps',
            uptime: '01:32:14',
            protocol: 'LL-HLS',
            health: 0.96,
          ),
          _streamCard(
            'Undercard — BK Bau vs Tanaka',
            'LIVE',
            DesignTokens.neonRed,
            viewers: 6800,
            bitrate: '3.8 Mbps',
            uptime: '00:48:22',
            protocol: 'LL-HLS',
            health: 0.92,
          ),
          _streamCard(
            'Corner Cam — VIP Test',
            'STANDBY',
            DesignTokens.neonAmber,
            viewers: 0,
            bitrate: '—',
            uptime: '—',
            protocol: 'SRT',
            health: 1.0,
          ),
          const SizedBox(height: 16),

          // ── INGEST STATUS ──
          const Text(
            'INGEST STATUS',
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          _ingestRow(
            'SRT Origin — Primary',
            'HEALTHY',
            DesignTokens.neonGreen,
            'srt://origin:9999',
          ),
          _ingestRow(
            'SRT Origin — Backup',
            'STANDBY',
            DesignTokens.neonAmber,
            'srt://origin-b:9999',
          ),
          _ingestRow(
            'FFmpeg Transcoder',
            'ACTIVE',
            DesignTokens.neonGreen,
            'veryfast / x264',
          ),
          _ingestRow(
            'NGINX LL-HLS Muxer',
            'ACTIVE',
            DesignTokens.neonGreen,
            '1s segments / fmp4',
          ),
          const SizedBox(height: 16),

          // ── QUALITY METRICS ──
          const Text(
            'QUALITY METRICS — MAIN CARD',
            style: TextStyle(
              color: DesignTokens.neonGold,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          _metricBar('Latency', '1.8s', 0.18, DesignTokens.neonGreen),
          _metricBar('Bitrate Stability', '96%', 0.96, DesignTokens.neonCyan),
          _metricBar('Frame Drops', '0.2%', 0.02, DesignTokens.neonGreen),
          _metricBar('Buffer Health', '98%', 0.98, DesignTokens.neonGreen),
          _metricBar('CDN Cache Hit', '94%', 0.94, DesignTokens.neonCyan),
          _metricBar('Viewer Error Rate', '0.4%', 0.04, DesignTokens.neonGreen),
          const SizedBox(height: 16),

          // ── UPCOMING STREAMS ──
          const Text(
            'UPCOMING STREAMS',
            style: TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          _upcomingCard(
            'BKFC 66 — Gold Coast',
            'May 10, 2026 · 19:00 AEST',
            'Pre-production',
          ),
          _upcomingCard(
            'Townsville Fight Week',
            'Jun 14, 2026 · 18:00 AEST',
            'Planning',
          ),
          _upcomingCard(
            'Auckland Showcase',
            'Jul 22, 2026 · 20:00 NZST',
            'Confirmed',
          ),
        ],
      ),
    );
  }

  Widget _viewerBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonRed.withValues(alpha: 0.08),
            DesignTokens.neonMagenta.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignTokens.neonRed.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _viewerStat(
            'TOTAL VIEWERS',
            '21,000',
            DesignTokens.neonRed,
            Icons.people,
          ),
          const SizedBox(width: 16),
          _viewerStat(
            'PEAK TODAY',
            '24,812',
            DesignTokens.neonGold,
            Icons.trending_up,
          ),
          const SizedBox(width: 16),
          _viewerStat(
            'ACTIVE STREAMS',
            '2',
            DesignTokens.neonGreen,
            Icons.cell_tower,
          ),
          const SizedBox(width: 16),
          _viewerStat('REGIONS', '4', DesignTokens.neonCyan, Icons.public),
        ],
      ),
    );
  }

  Widget _viewerStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.6), size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white30,
              fontWeight: FontWeight.w700,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _streamCard(
    String title,
    String status,
    Color statusColor, {
    required int viewers,
    required String bitrate,
    required String uptime,
    required String protocol,
    required double health,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, color: statusColor, size: 8),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _streamStat(
                'VIEWERS',
                viewers > 0 ? _formatK(viewers) : '—',
                DesignTokens.neonCyan,
              ),
              _streamStat('BITRATE', bitrate, DesignTokens.neonGreen),
              _streamStat('UPTIME', uptime, Colors.white38),
              _streamStat('PROTOCOL', protocol, DesignTokens.neonAmber),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'HEALTH',
                style: TextStyle(
                  color: Colors.white30,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: health,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      health > 0.9
                          ? DesignTokens.neonGreen
                          : DesignTokens.neonAmber,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(health * 100).toInt()}%',
                style: TextStyle(
                  color: health > 0.9
                      ? DesignTokens.neonGreen
                      : DesignTokens.neonAmber,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _streamStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white24,
              fontWeight: FontWeight.w700,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingestRow(String name, String status, Color color, String detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Colors.white24,
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBar(String label, String value, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              valueColor: AlwaysStoppedAnimation<Color>(
                color.withValues(alpha: 0.6),
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _upcomingCard(String title, String date, String stage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, color: Colors.white24, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              stage.toUpperCase(),
              style: const TextStyle(
                color: Colors.white30,
                fontWeight: FontWeight.w700,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatK(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
