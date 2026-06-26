import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/regional_where_to_watch.dart';

/// Event Detail Screen - Promotion Engine
/// Event → Fight Card → Where to Watch CTAs → External destination
/// We amplify. We don't intercept.
class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final String eventName;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  // Demo event data - would come from Firestore
  final Map<String, dynamic> _event = {
    'name': 'Hex Fight Series 27: Collision',
    'date': 'March 14, 2026',
    'time': '7:00 PM AEDT',
    'venue': 'Festival Hall',
    'city': 'Melbourne, Australia',
    'promoter': 'Hex Fight Series',
    'promoterVerified': true,
    'posterUrl': null,
    'isPpv': true,
    'isLive': false,
    'ticketUrl': 'https://hexfightseries.com.au/tickets',
    'doorsOpen': '5:00 PM',
    'mainCardTime': '8:00 PM',
  };

  // Fight card
  final List<Map<String, dynamic>> _fightCard = [
    {
      'isMainEvent': true,
      'fighterA': 'Jack Della Maddalena',
      'fighterB': 'Marcus Torres',
      'recordA': '17-2',
      'recordB': '25-7',
      'weightClass': 'Middleweight',
      'title': 'Title Fight',
    },
    {
      'isMainEvent': false,
      'fighterA': 'Casey O\'Neill',
      'fighterB': 'Molly McCann',
      'recordA': '10-2',
      'recordB': '14-5',
      'weightClass': 'Strawweight',
      'title': null,
    },
    {
      'isMainEvent': false,
      'fighterA': 'Mako Tua',
      'fighterB': 'Tyson Pedro',
      'recordA': '15-8',
      'recordB': '10-4',
      'weightClass': 'Heavyweight',
      'title': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildEventHeader(),
                const SizedBox(height: 20),

                // Where to Watch — region-aware
                if (_event['isPpv'] == true) ...[
                  _buildSectionHeader('Where to Watch', Icons.live_tv),
                  const SizedBox(height: 12),
                  const RegionalWhereToWatch(
                    eventPlatforms: ['DFC', 'FITE'],
                    eventCountry: 'AU',
                  ),
                  const SizedBox(height: 8),
                  _buildDisclaimer(),
                  const SizedBox(height: 24),
                ],

                // Tickets
                _buildSectionHeader('Get Tickets', Icons.confirmation_number),
                const SizedBox(height: 12),
                _buildTicketCard(),
                const SizedBox(height: 24),

                // Fight Card
                _buildSectionHeader('Fight Card', Icons.sports_mma),
                const SizedBox(height: 12),
                ..._fightCard.map(
                  (fight) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildFightCard(fight),
                  ),
                ),
                const SizedBox(height: 24),

                // Event Details
                _buildSectionHeader('Event Details', Icons.info_outline),
                const SizedBox(height: 12),
                _buildEventDetails(),
                const SizedBox(height: 24),

                // Promoter Info
                _buildSectionHeader('Promoted By', Icons.business),
                const SizedBox(height: 12),
                _buildPromoterCard(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      // Alert toggle FAB
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'event_detail_alert_fab',
        onPressed: _toggleAlert,
        backgroundColor: AppTheme.neonCyan,
        icon: const Icon(Icons.notifications_active, color: Colors.white),
        label: const Text(
          'Get Alerts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryBackground,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), AppTheme.primaryBackground],
            ),
          ),
          child: Stack(
            children: [
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.neonCyan.withValues(alpha: 0.2),
                      AppTheme.neonMagenta.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
              // Event branding
              Center(
                child: Icon(
                  Icons.sports_mma,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              // Live badge
              if (_event['isLive'] == true)
                Positioned(
                  top: 60,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'LIVE NOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event name
        Text(
          _event['name'] as String,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Date & Time
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppTheme.neonCyan,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _event['date'] as String,
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: AppTheme.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _event['time'] as String,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Venue
        Row(
          children: [
            const Icon(Icons.location_on, color: AppTheme.textMuted, size: 16),
            const SizedBox(width: 6),
            Text(
              '${_event['venue']} • ${_event['city']}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.neonCyan, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.textMuted, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'You will be redirected to an external provider. DataFight Central does not sell or host this content.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard() {
    return Material(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _launchUrl(_event['ticketUrl'] as String),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.neonGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.confirmation_number,
                  color: AppTheme.neonGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buy Tickets',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Attend the event in person',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Get Tickets',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFightCard(Map<String, dynamic> fight) {
    final isMain = fight['isMainEvent'] as bool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: isMain
            ? Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Column(
        children: [
          if (isMain) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '⭐ MAIN EVENT',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (fight['title'] != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neonMagenta.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fight['title'] as String,
                style: const TextStyle(
                  color: AppTheme.neonMagenta,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              // Fighter A
              Expanded(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.surfaceColor,
                      child: Icon(
                        Icons.person,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fight['fighterA'] as String,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      fight['recordA'] as String,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // VS
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              // Fighter B
              Expanded(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.surfaceColor,
                      child: Icon(
                        Icons.person,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fight['fighterB'] as String,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      fight['recordB'] as String,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fight['weightClass'] as String,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.door_front_door,
            'Doors Open',
            _event['doorsOpen'] as String,
          ),
          const Divider(color: AppTheme.surfaceColor, height: 20),
          _buildDetailRow(
            Icons.play_circle,
            'Main Card',
            _event['mainCardTime'] as String,
          ),
          const Divider(color: AppTheme.surfaceColor, height: 20),
          _buildDetailRow(
            Icons.location_on,
            'Venue',
            _event['venue'] as String,
          ),
          const Divider(color: AppTheme.surfaceColor, height: 20),
          _buildDetailRow(Icons.place, 'City', _event['city'] as String),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPromoterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.15),
            child: const Icon(Icons.business, color: AppTheme.neonCyan),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _event['promoter'] as String,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (_event['promoterVerified'] == true) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        color: AppTheme.neonCyan,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const Text(
                  'Event Promoter',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Promoter profiles — browse promoters from the Explore tab'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.neonCyan),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'View Profile',
              style: TextStyle(color: AppTheme.neonCyan, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 10),
            Text('Alerts enabled for this event!'),
          ],
        ),
        backgroundColor: AppTheme.neonCyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }
}
