import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/global_distribution_service.dart';

/// Global Distribution Screen — platform channel toggles, regional coverage,
/// and live distribution log. Two tabs: Channels (per-platform controls) / Regions.
class GlobalDistributionScreen extends StatefulWidget {
  const GlobalDistributionScreen({super.key});

  @override
  State<GlobalDistributionScreen> createState() =>
      _GlobalDistributionScreenState();
}

class _GlobalDistributionScreenState extends State<GlobalDistributionScreen>
    with SingleTickerProviderStateMixin {
  final _svc = GlobalDistributionService();
  late TabController _tabs;

  List<DistributionChannelConfig> _configs = [];
  List<DistributionLogEntry> _logs = [];
  bool _loadingConfigs = true;
  bool _loadingLogs = true;
  final Set<String> _syncing = {};

  static const _platformIcons = <String, IconData>{
    'instagram': Icons.camera_alt,
    'facebook': Icons.facebook,
    'youtube': Icons.play_circle_filled,
    'tiktok': Icons.music_note,
    'whatsapp': Icons.message,
  };

  static const _platformColors = <String, Color>{
    'instagram': Color(0xFFE1306C),
    'facebook': Color(0xFF1877F2),
    'youtube': Color(0xFFFF0000),
    'tiktok': Color(0xFF00F2EA),
    'whatsapp': Color(0xFF25D366),
  };

  static const _regionNames = <String, String>{
    'US': 'United States',
    'AU': 'Australia',
    'GB': 'United Kingdom',
    'EU': 'Europe',
    'IN': 'India',
    'PK': 'Pakistan',
    'PH': 'Philippines',
    'NG': 'Nigeria',
    'BR': 'Brazil',
    'JP': 'Japan',
    'AE': 'UAE / Middle East',
    'ZA': 'South Africa',
    'TH': 'Thailand',
    'PB': 'Punjab (India)',
    'PF': 'Pacific Islands',
    'FJ': 'Fiji',
    'WS': 'Samoa',
    'TO': 'Tonga',
    'PG': 'Papua New Guinea',
    'NZ': 'New Zealand',
    'MX': 'Mexico',
    'CO': 'Colombia',
    'AR': 'Argentina',
    'PE': 'Peru',
    'CL': 'Chile',
    'KE': 'Kenya',
    'GH': 'Ghana',
    'ET': 'Ethiopia',
    'CM': 'Cameroon',
    'SG': 'Singapore',
    'MY': 'Malaysia',
    'ID': 'Indonesia',
  };

  static const _regionFlags = <String, String>{
    'US': '🇺🇸',
    'AU': '🇦🇺',
    'GB': '🇬🇧',
    'EU': '🇪🇺',
    'IN': '🇮🇳',
    'PK': '🇵🇰',
    'PH': '🇵🇭',
    'NG': '🇳🇬',
    'BR': '🇧🇷',
    'JP': '🇯🇵',
    'AE': '🇦🇪',
    'ZA': '🇿🇦',
    'TH': '🇹🇭',
    'PB': '🇮🇳',
    'PF': '🌏',
    'FJ': '🇫🇯',
    'WS': '🇼🇸',
    'TO': '🇹🇴',
    'PG': '🇵🇬',
    'NZ': '🇳🇿',
    'MX': '🇲🇽',
    'CO': '🇨🇴',
    'AR': '🇦🇷',
    'PE': '🇵🇪',
    'CL': '🇨🇱',
    'KE': '🇰🇪',
    'GH': '🇬🇭',
    'ET': '🇪🇹',
    'CM': '🇨🇲',
    'SG': '🇸🇬',
    'MY': '🇲🇾',
    'ID': '🇮🇩',
  };

  // ── Regional broadcast networks per market ─────────────────────────────────
  // These are the TV/streaming gaps the Promotion Engine targets.
  // Once a promoter shares content, DFC routes it to the right networks.
  static const _broadcastNetworks = <String, List<_BroadcastChannel>>{
    'IN': [
      _BroadcastChannel('Sony Sports TEN', 'sports', 'sony-ten.com'),
      _BroadcastChannel('Star Sports India', 'sports', 'hotstar.com'),
      _BroadcastChannel('Zee Sports', 'sports', 'zeesports.com'),
      _BroadcastChannel('JioCinema', 'streaming', 'jiocinema.com'),
      _BroadcastChannel('Voot Sports', 'streaming', 'voot.com'),
    ],
    'PB': [
      _BroadcastChannel('PTC Punjabi', 'regional', 'ptcnetwork.com'),
      _BroadcastChannel('Zee Punjabi', 'regional', 'zeepunjabi.com'),
      _BroadcastChannel('MH One Sports', 'regional', 'mhone.in'),
      _BroadcastChannel('Punjab Kesari TV', 'regional', 'punjabkesari.in'),
    ],
    'PF': [
      _BroadcastChannel('TVNZ Pacific', 'free-to-air', 'tvnz.co.nz'),
      _BroadcastChannel('Pacific Beat (ABC)', 'news', 'abc.net.au/pacific'),
      _BroadcastChannel('Niu FM', 'radio', 'niufm.com'),
      _BroadcastChannel(
        'Sky Pacific',
        'satellite',
        'skypacific.com.fj',
        gap: true,
      ),
    ],
    'NZ': [
      _BroadcastChannel('Sky Sport NZ', 'sports', 'skysport.co.nz'),
      _BroadcastChannel('TVNZ 1', 'free-to-air', 'tvnz.co.nz'),
      _BroadcastChannel('Stuff Circuit', 'streaming', 'stuff.co.nz'),
      _BroadcastChannel('Whakaata Māori', 'indigenous', 'maoritelevision.com'),
    ],
    'AU': [
      _BroadcastChannel('Kayo Sports', 'streaming', 'kayosports.com.au'),
      _BroadcastChannel('Foxtel Event Ch', 'sports', 'foxtel.com.au'),
      _BroadcastChannel('9Now Sports', 'free-to-air', '9now.com.au'),
      _BroadcastChannel('NITV (NITIS)', 'indigenous', 'nitv.org.au'),
      _BroadcastChannel('SBS Sports', 'multicultural', 'sbs.com.au'),
    ],
    'BR': [
      _BroadcastChannel('Combate (GloboPlay)', 'sports', 'combate.com'),
      _BroadcastChannel('ESPN Brasil', 'sports', 'espnbrasil.com.br'),
      _BroadcastChannel('SporTV', 'sports', 'sportv.globo.com'),
      _BroadcastChannel('BandSports', 'sports', 'band.com.br/bandsports'),
    ],
    'MX': [
      _BroadcastChannel('TUDN (Univision)', 'sports', 'tudn.com'),
      _BroadcastChannel('ESPN Latinoamérica', 'sports', 'espndeportes.com'),
      _BroadcastChannel('Fox Sports Latam', 'sports', 'foxsportsla.com'),
    ],
    'AR': [
      _BroadcastChannel('TyC Sports', 'sports', 'tycsports.com'),
      _BroadcastChannel('ESPN Argentina', 'sports', 'espndeportes.com'),
      _BroadcastChannel('DirecTV Sports', 'satellite', 'directvsports.com'),
    ],
    'NG': [
      _BroadcastChannel('SuperSport Africa', 'sports', 'supersport.com'),
      _BroadcastChannel('Channels TV', 'news', 'channelstv.com'),
      _BroadcastChannel('Arise TV', 'news', 'arise.tv'),
      _BroadcastChannel('FilmHouse Cinemas', 'events', 'filmhouseng.com'),
    ],
    'ZA': [
      _BroadcastChannel('SuperSport', 'sports', 'supersport.com'),
      _BroadcastChannel('SABC Sport', 'free-to-air', 'sabc.co.za'),
      _BroadcastChannel('eNCA', 'news', 'enca.com'),
    ],
    'KE': [
      _BroadcastChannel('SuperSport East Africa', 'sports', 'supersport.com'),
      _BroadcastChannel('Citizen TV Kenya', 'news', 'citizentv.co.ke'),
      _BroadcastChannel('K24 TV', 'news', 'k24tv.co.ke'),
    ],
    'AE': [
      _BroadcastChannel('Abu Dhabi Sports', 'sports', 'adtv.ae'),
      _BroadcastChannel('beIN Sports MENA', 'sports', 'beinsports.com'),
      _BroadcastChannel('OSN Sports', 'satellite', 'osn.com'),
    ],
    'SG': [
      _BroadcastChannel('beIN Sports Asia', 'sports', 'beinsports.com'),
      _BroadcastChannel('ONE Championship HD', 'sports', 'onefc.com'),
      _BroadcastChannel('mediacorp toggle', 'streaming', 'toggle.sg'),
    ],
    'ID': [
      _BroadcastChannel('Vision+ Sports', 'streaming', 'visionplus.id'),
      _BroadcastChannel('RCTI+', 'free-to-air', 'rctiplus.com'),
      _BroadcastChannel('Vidio Sports', 'streaming', 'vidio.com'),
    ],
    'JP': [
      _BroadcastChannel('ABEMA Fighting', 'streaming', 'abema.tv'),
      _BroadcastChannel('RIZIN LIVE', 'streaming', 'rizinff.com'),
      _BroadcastChannel('J-Sports', 'cable', 'jsports.co.jp'),
      _BroadcastChannel('Fuji TV Next', 'cable', 'fujitv-next.com'),
    ],
    'US': [
      _BroadcastChannel('ESPN+ / UFC PPV', 'sports', 'espnplus.com'),
      _BroadcastChannel('TrillerTV', 'streaming', 'trillertv.com'),
      _BroadcastChannel('Univision/TUDN', 'spanish', 'tudn.com'),
      _BroadcastChannel('Telemundo Sports', 'spanish', 'telemundo.com'),
      _BroadcastChannel(
        'Amazon Prime Video',
        'streaming',
        'amazon.com/primevideo',
      ),
    ],
    'PH': [
      _BroadcastChannel('ONE Championship TV', 'sports', 'onefc.com'),
      _BroadcastChannel('CNN Philippines', 'news', 'cnnphilippines.com'),
      _BroadcastChannel('Tap (Sports5)', 'streaming', 'tap.tv'),
    ],
  };

  static const _extraPlatformIcons = <String, IconData>{
    'twitter': Icons.tag,
    'reddit': Icons.forum,
  };

  static const _extraPlatformColors = <String, Color>{
    'twitter': Color(0xFF1DA1F2),
    'reddit': Color(0xFFFF4500),
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final cfgs = await _svc.getChannelConfigs();
    final logs = await _svc.getRecentLogs(limit: 15);
    if (mounted) {
      setState(() {
        _configs = cfgs;
        _logs = logs;
        _loadingConfigs = false;
        _loadingLogs = false;
      });
    }
  }

  Future<void> _togglePlatform(DistributionChannelConfig cfg) async {
    final newEnabled = !cfg.enabled;
    setState(() {
      _configs = _configs
          .map(
            (c) => c.platform == cfg.platform
                ? c.copyWith(enabled: newEnabled)
                : c,
          )
          .toList();
    });
    await _svc.setEnabled(cfg.platform, enabled: newEnabled);
  }

  Future<void> _syncNow(String platform) async {
    if (_syncing.contains(platform)) return;
    setState(() => _syncing.add(platform));
    await Future.delayed(const Duration(seconds: 2)); // simulate sync
    await _svc.recordSync(platform, 5);
    final logs = await _svc.getRecentLogs(limit: 15);
    if (mounted) {
      setState(() {
        _syncing.remove(platform);
        _logs = logs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        title: const Text(
          'Global Distribution Engine',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.neonCyan),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
            onPressed: () {
              setState(() {
                _loadingConfigs = true;
                _loadingLogs = true;
              });
              _loadData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: Colors.white38,
          indicatorColor: AppTheme.neonCyan,
          tabs: const [
            Tab(text: 'CHANNELS'),
            Tab(text: 'REGIONS'),
            Tab(text: 'BROADCAST'),
            Tab(text: 'LOGS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildChannelsTab(),
          _buildRegionsTab(),
          _buildBroadcastTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  // ── TAB 1: Platform channel toggles ─────────────────────────────────────────

  Widget _buildChannelsTab() {
    if (_loadingConfigs) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.neonCyan),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChannelHeader(),
        const SizedBox(height: 16),
        ..._configs.map(_buildChannelCard),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChannelHeader() {
    final activeCount = _configs.where((c) => c.enabled).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonMagenta.withValues(alpha: 0.12),
            AppTheme.neonCyan.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonMagenta.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cell_tower, color: AppTheme.neonMagenta, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DISTRIBUTION CHANNELS',
                  style: TextStyle(
                    color: AppTheme.neonMagenta,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$activeCount of ${_configs.length} platforms active',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.neonGreen.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '$activeCount LIVE',
              style: const TextStyle(
                color: AppTheme.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelCard(DistributionChannelConfig cfg) {
    final color = _platformColors[cfg.platform] ?? AppTheme.neonCyan;
    final icon = _platformIcons[cfg.platform] ?? Icons.public;
    final isSyncing = _syncing.contains(cfg.platform);
    final lastSync = cfg.lastSync;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cfg.enabled
            ? color.withValues(alpha: 0.07)
            : const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cfg.enabled ? color.withValues(alpha: 0.4) : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalize(cfg.platform),
                      style: TextStyle(
                        color: cfg.enabled ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (lastSync != null)
                      Text(
                        'Last sync: ${_formatAgo(lastSync)} · ${cfg.itemsSynced} items',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      )
                    else
                      const Text(
                        'Never synced',
                        style: TextStyle(color: Colors.white24, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Switch(
                value: cfg.enabled,
                onChanged: (_) => _togglePlatform(cfg),
                activeThumbColor: color,
                inactiveThumbColor: Colors.white24,
                inactiveTrackColor: Colors.white10,
              ),
            ],
          ),
          if (cfg.enabled) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: isSyncing ? null : () => _syncNow(cfg.platform),
                  icon: isSyncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.neonCyan,
                          ),
                        )
                      : const Icon(
                          Icons.sync,
                          size: 16,
                          color: AppTheme.neonCyan,
                        ),
                  label: Text(
                    isSyncing ? 'Syncing…' : 'Sync Now',
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── TAB 2: Regional breakdown ────────────────────────────────────────────────

  Widget _buildRegionsTab() {
    final regions = _svc.getAllRegionPlatforms();
    final codes = regions.keys.toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRegionHeader(codes.length),
        const SizedBox(height: 16),
        ...codes.map((c) => _buildRegionCard(c, regions[c]!)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRegionHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.12),
            AppTheme.neonMagenta.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.language, color: AppTheme.neonCyan, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DFC GLOBAL REACH',
                style: TextStyle(
                  color: AppTheme.neonCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                '$count regions mapped',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.neonGreen.withValues(alpha: 0.4),
              ),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: AppTheme.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(String code, List<String> platforms) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _regionFlags[code] ?? '🌍',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Text(
                _regionNames[code] ?? code,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                code,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: platforms.map(_buildPlatformChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformChip(String platform) {
    final color =
        _platformColors[platform] ??
        _extraPlatformColors[platform] ??
        AppTheme.neonCyan;
    final icon =
        _platformIcons[platform] ??
        _extraPlatformIcons[platform] ??
        Icons.public;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            _capitalize(platform),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: Distribution logs ─────────────────────────────────────────────────

  Widget _buildLogsTab() {
    if (_loadingLogs) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.neonCyan),
      );
    }
    if (_logs.isEmpty) {
      return const Center(
        child: Text(
          'No distribution logs yet.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLogHeader(),
        const SizedBox(height: 12),
        ..._logs.map(_buildLogEntry),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLogHeader() {
    return Row(
      children: [
        const Icon(Icons.receipt_long, color: AppTheme.neonCyan, size: 18),
        const SizedBox(width: 8),
        const Text(
          'DISTRIBUTION LOG',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.3,
          ),
        ),
        const Spacer(),
        Text(
          '${_logs.length} entries',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLogEntry(DistributionLogEntry log) {
    final color = _platformColors[log.platform] ?? AppTheme.neonCyan;
    final icon = _platformIcons[log.platform] ?? Icons.public;
    final statusColor = log.hasErrors
        ? AppTheme.neonMagenta
        : AppTheme.neonGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: log.hasErrors
              ? AppTheme.neonMagenta.withValues(alpha: 0.3)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capitalize(log.platform),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (log.hasErrors)
                  Text(
                    log.errors.first,
                    style: const TextStyle(
                      color: AppTheme.neonMagenta,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  log.hasErrors ? 'WARN' : '${log.itemsSynced} synced',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatAgo(log.timestamp),
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TAB 3: Broadcast networks + gap detection ────────────────────────────────

  Widget _buildBroadcastTab() {
    final gapCount = _broadcastNetworks.values
        .expand((list) => list)
        .where((c) => c.gap)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Gap summary banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.neonMagenta.withValues(alpha: 0.15),
                AppTheme.neonCyan.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.neonMagenta.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.radar, color: AppTheme.neonMagenta, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROMOTION ENGINE — GAP DETECTION',
                      style: TextStyle(
                        color: AppTheme.neonMagenta,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$gapCount untapped channels identified. '
                      'Share your event to DFC and we route it to these networks automatically.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // One section per region
        ..._broadcastNetworks.entries.map((entry) {
          final code = entry.key;
          final channels = entry.value;
          final flag = _regionFlags[code] ?? '🌐';
          final name = _regionNames[code] ?? code;
          final gapChannels = channels.where((c) => c.gap).length;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: gapChannels > 0
                    ? AppTheme.neonCyan.withValues(alpha: 0.25)
                    : Colors.white10,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                colorScheme: Theme.of(
                  context,
                ).colorScheme.copyWith(surface: const Color(0xFF0D1B2A)),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                leading: Text(flag, style: const TextStyle(fontSize: 22)),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (gapChannels > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.neonCyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.neonCyan.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '$gapChannels gaps',
                          style: const TextStyle(
                            color: AppTheme.neonCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  '${channels.length} channels · '
                  '${channels.where((c) => !c.gap).length} active',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                children: channels.map(_buildChannelRow).toList(),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChannelRow(_BroadcastChannel ch) {
    final isGap = ch.gap;
    final statusColor = isGap ? AppTheme.neonMagenta : AppTheme.neonGreen;
    final typeIcon = switch (ch.type) {
      'sports' => Icons.sports_kabaddi,
      'streaming' => Icons.play_circle_outline,
      'free-to-air' => Icons.tv,
      'satellite' => Icons.satellite_alt,
      'regional' => Icons.location_on,
      'indigenous' => Icons.diversity_3,
      'multicultural' => Icons.public,
      'news' => Icons.newspaper,
      'radio' => Icons.radio,
      'cable' => Icons.cable,
      'spanish' => Icons.translate,
      'events' => Icons.event,
      _ => Icons.broadcast_on_home,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(typeIcon, color: statusColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ch.name,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                Text(
                  ch.domain,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              isGap ? 'GAP ▲' : 'ACTIVE',
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _BroadcastChannel {
  final String name;
  final String type;
  final String domain;
  final bool gap; // true = DFC has no relationship yet → opportunity

  const _BroadcastChannel(
    this.name,
    this.type,
    this.domain, {
    this.gap = false,
  });
}
