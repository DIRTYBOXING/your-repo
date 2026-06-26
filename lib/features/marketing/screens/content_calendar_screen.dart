import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';

/// Content Calendar Screen — Visual week view for scheduling.
/// Queries posts, events, and news by date range, color-coded by type.
class ContentCalendarScreen extends StatefulWidget {
  const ContentCalendarScreen({super.key});

  @override
  State<ContentCalendarScreen> createState() => _ContentCalendarScreenState();
}

class _ContentCalendarScreenState extends State<ContentCalendarScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DateTime _weekStart = _getWeekStart(DateTime.now());
  Map<String, List<_CalendarItem>> _dayItems = {};
  bool _loading = true;

  static DateTime _getWeekStart(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - diff);
  }

  @override
  void initState() {
    super.initState();
    _loadWeek();
  }

  Future<void> _loadWeek() async {
    setState(() => _loading = true);
    final weekEnd = _weekStart.add(const Duration(days: 7));
    final startTs = Timestamp.fromDate(_weekStart);
    final endTs = Timestamp.fromDate(weekEnd);

    final items = <_CalendarItem>[];

    try {
      // Posts
      final postsSnap = await _db
          .collection('posts')
          .where('createdAt', isGreaterThanOrEqualTo: startTs)
          .where('createdAt', isLessThan: endTs)
          .orderBy('createdAt')
          .limit(50)
          .get();
      for (final doc in postsSnap.docs) {
        final d = doc.data();
        items.add(
          _CalendarItem(
            id: doc.id,
            title:
                d['title'] ??
                d['content']?.toString().substring(
                  0,
                  (d['content']?.toString().length ?? 0) > 40
                      ? 40
                      : d['content']?.toString().length ?? 0,
                ) ??
                'Post',
            type: 'post',
            date: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            color: AppTheme.neonCyan,
          ),
        );
      }

      // Events
      final eventsSnap = await _db
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: startTs)
          .where('date', isLessThan: endTs)
          .orderBy('date')
          .limit(100)
          .get();
      for (final doc in eventsSnap.docs) {
        final d = doc.data();
        items.add(
          _CalendarItem(
            id: doc.id,
            title: d['title'] ?? d['name'] ?? 'Event',
            type: 'event',
            date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
            color: AppTheme.neonOrange,
          ),
        );
      }

      // News articles
      final newsSnap = await _db
          .collection('news_articles')
          .where('publishedAt', isGreaterThanOrEqualTo: startTs)
          .where('publishedAt', isLessThan: endTs)
          .orderBy('publishedAt')
          .limit(100)
          .get();
      for (final doc in newsSnap.docs) {
        final d = doc.data();
        items.add(
          _CalendarItem(
            id: doc.id,
            title: d['title'] ?? 'News',
            type: 'news',
            date: (d['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            color: AppTheme.neonMagenta,
          ),
        );
      }

      // Social engine posts
      final socialSnap = await _db
          .collection('social_engine_posts')
          .where('createdAt', isGreaterThanOrEqualTo: startTs)
          .where('createdAt', isLessThan: endTs)
          .orderBy('createdAt')
          .limit(100)
          .get();
      for (final doc in socialSnap.docs) {
        final d = doc.data();
        items.add(
          _CalendarItem(
            id: doc.id,
            title: d['title'] ?? d['platform'] ?? 'Social',
            type: 'social',
            date: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            color: AppTheme.neonPurple,
          ),
        );
      }
    } catch (_) {}

    // Group by day key
    final grouped = <String, List<_CalendarItem>>{};
    for (int i = 0; i < 7; i++) {
      final day = _weekStart.add(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';
      grouped[key] = [];
    }
    for (final item in items) {
      final key = '${item.date.year}-${item.date.month}-${item.date.day}';
      grouped[key]?.add(item);
    }

    if (mounted) {
      setState(() {
        _dayItems = grouped;
        _loading = false;
      });
    }
  }

  void _prevWeek() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    _loadWeek();
  }

  void _nextWeek() {
    _weekStart = _weekStart.add(const Duration(days: 7));
    _loadWeek();
  }

  void _goToToday() {
    _weekStart = _getWeekStart(DateTime.now());
    _loadWeek();
  }

  @override
  Widget build(BuildContext context) {
    final dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('CONTENT CALENDAR'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: const Color(0xFFFF6B6B),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: AppTheme.neonCyan),
            onPressed: _goToToday,
          ),
        ],
      ),
      body: Column(
        children: [
          // Week header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: AppTheme.cardBackground,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: _prevWeek,
                ),
                Text(
                  '${_weekStart.day}/${_weekStart.month} — ${_weekStart.add(const Duration(days: 6)).day}/${_weekStart.add(const Duration(days: 6)).month}/${_weekStart.year}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: _nextWeek,
                ),
              ],
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _legendDot('Post', AppTheme.neonCyan),
                _legendDot('Event', AppTheme.neonOrange),
                _legendDot('News', AppTheme.neonMagenta),
                _legendDot('Social', AppTheme.neonPurple),
              ],
            ),
          ),
          // Calendar grid
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonCyan),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final day = _weekStart.add(Duration(days: index));
                      final key = '${day.year}-${day.month}-${day.day}';
                      final items = _dayItems[key] ?? [];
                      final isToday =
                          DateTime.now().year == day.year &&
                          DateTime.now().month == day.month &&
                          DateTime.now().day == day.day;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday
                              ? Border.all(color: AppTheme.neonCyan, width: 1.5)
                              : Border.all(
                                  color: AppTheme.cardBackground.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  dayNames[index],
                                  style: TextStyle(
                                    color: isToday
                                        ? AppTheme.neonCyan
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${day.day}/${day.month}',
                                  style: TextStyle(
                                    color: isToday
                                        ? AppTheme.neonCyan
                                        : AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                if (items.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.neonCyan.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${items.length}',
                                      style: const TextStyle(
                                        color: AppTheme.neonCyan,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (items.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: item.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'No content',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

class _CalendarItem {
  final String id;
  final String title;
  final String type;
  final DateTime date;
  final Color color;
  _CalendarItem({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.color,
  });
}
