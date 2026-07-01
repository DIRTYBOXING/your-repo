import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PLANNER SCREEN - Monthly/Weekly calendar and goal tracking
/// For: Fighters, Coaches - Training camps, events, recovery days
/// ═══════════════════════════════════════════════════════════════════════════
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      floatingActionButton: FloatingActionButton(
        heroTag: 'planner_add_event_fab',
        onPressed: _showAddEventSheet,
        backgroundColor: AppTheme.neonCyan,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildAppBar(),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCalendarTab(),
              _buildAgendaTab(),
              _buildGoalsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.primaryBackground,
      expandedHeight: 130,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fight Planner',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Schedule & Goals',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.today, color: Colors.white),
          onPressed: () => setState(() => _selectedDate = DateTime.now()),
        ),
        IconButton(
          icon: const Icon(Icons.sync, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Syncing calendar...'),
                backgroundColor: Colors.teal,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.neonCyan,
        labelColor: AppTheme.neonCyan,
        unselectedLabelColor: Colors.white54,
        tabs: const [
          Tab(
            icon: Icon(Icons.calendar_view_month, size: 18),
            text: 'Calendar',
          ),
          Tab(icon: Icon(Icons.view_agenda, size: 18), text: 'Agenda'),
          Tab(icon: Icon(Icons.flag, size: 18), text: 'Goals'),
        ],
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// CALENDAR TAB - Monthly view with fight events
  /// ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => setState(() {
                  if (_selectedMonth == 1) {
                    _selectedMonth = 12;
                    _selectedYear--;
                  } else {
                    _selectedMonth--;
                  }
                }),
              ),
              Text(
                '${_getMonthName(_selectedMonth)} $_selectedYear',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () => setState(() {
                  if (_selectedMonth == 12) {
                    _selectedMonth = 1;
                    _selectedYear++;
                  } else {
                    _selectedMonth++;
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Day Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          _buildCalendarGrid(),
          const SizedBox(height: 24),

          // Selected Date Events
          Text(
            'Events on ${_formatDate(_selectedDate)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._getEventsForDate(_selectedDate).map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEventCard(event),
            ),
          ),
          if (_getEventsForDate(_selectedDate).isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      color: Colors.white38,
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No events scheduled',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedYear, _selectedMonth);
    final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final startPadding = firstDay.weekday % 7;
    final totalDays = lastDay.day + startPadding;
    final rows = (totalDays / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (col) {
            final dayNum = row * 7 + col - startPadding + 1;
            if (dayNum < 1 || dayNum > lastDay.day) {
              return const SizedBox(width: 40, height: 40);
            }
            final date = DateTime(_selectedYear, _selectedMonth, dayNum);
            final isToday = _isToday(date);
            final isSelected = _isSameDay(date, _selectedDate);
            final hasEvent = _hasEvent(date);

            return GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.neonCyan.withValues(alpha: 0.3)
                      : isToday
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppTheme.neonCyan, width: 2)
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$dayNum',
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.neonCyan
                            : isToday
                            ? Colors.white
                            : Colors.white70,
                        fontWeight: isToday || isSelected
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                    if (hasEvent)
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getEventColor(date),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// AGENDA TAB - List view of upcoming events
  /// ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAgendaTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today Section
          _buildAgendaSection('Today', Colors.green, [
            {
              'time': '6:00 AM',
              'title': 'Morning Cardio',
              'type': 'Training',
              'location': 'Home Gym',
            },
            {
              'time': '10:00 AM',
              'title': 'Strength Training',
              'type': 'Training',
              'location': 'City Gym',
            },
            {
              'time': '3:00 PM',
              'title': 'Sparring Session',
              'type': 'Sparring',
              'location': 'Fight Academy',
            },
          ]),
          const SizedBox(height: 24),

          // Tomorrow
          _buildAgendaSection('Tomorrow', Colors.blue, [
            {
              'time': '8:00 AM',
              'title': 'Recovery Session',
              'type': 'Recovery',
              'location': 'Physio Clinic',
            },
            {
              'time': '2:00 PM',
              'title': 'Boxing Technique',
              'type': 'Training',
              'location': 'Boxing Gym',
            },
          ]),
          const SizedBox(height: 24),

          // This Week
          _buildAgendaSection('This Week', Colors.purple, [
            {
              'time': 'Feb 8',
              'title': 'Weigh-In',
              'type': 'Event',
              'location': 'Fight Venue',
            },
            {
              'time': 'Feb 9',
              'title': 'FIGHT NIGHT',
              'type': 'Fight',
              'location': 'Tampa, FL',
            },
          ]),
          const SizedBox(height: 24),

          // Camp Overview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.2),
                  Colors.orange.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sports_mma, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Fight Camp Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCampStat('Days Left', '4', Colors.red),
                    _buildCampStat('Sessions', '42/48', Colors.orange),
                    _buildCampStat('Recovery', '92%', Colors.green),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.87,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '87% Camp Complete',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAgendaSection(
    String title,
    Color color,
    List<Map<String, String>> events,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...events.map(
          (event) => Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    event['time']!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: _getTypeColor(event['type']!),
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              event['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(
                                  event['type']!,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                event['type']!,
                                style: TextStyle(
                                  color: _getTypeColor(event['type']!),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white38,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event['location']!,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// GOALS TAB - Track fight camp and personal goals
  /// ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGoalsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Goal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.2),
                  Colors.orange.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Primary Goal',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Win BKFC Welterweight Title',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fight Date: February 9, 2026',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preparation Progress',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 0.92,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '92%',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sub-Goals
          const Text(
            'Sub-Goals',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildGoalItem(
            'Make weight (77 kg / 170 lbs)',
            0.85,
            'Current: 78.2 kg / 172.5 lbs',
            Colors.orange,
            Icons.monitor_weight,
          ),
          const SizedBox(height: 12),
          _buildGoalItem(
            'Complete all sparring sessions',
            0.95,
            '19/20 sessions done',
            Colors.green,
            Icons.sports_mma,
          ),
          const SizedBox(height: 12),
          _buildGoalItem(
            'Master new combo routine',
            0.75,
            '6/8 techniques learned',
            Colors.blue,
            Icons.school,
          ),
          const SizedBox(height: 12),
          _buildGoalItem(
            'Improve cardio endurance',
            0.88,
            'VO2 max: 52 ml/kg/min',
            Colors.red,
            Icons.favorite,
          ),
          const SizedBox(height: 24),

          // Add Goal Button
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Track your goals using the wellness categories above'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Goal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.neonCyan,
              side: const BorderSide(color: AppTheme.neonCyan),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Long-term Goals
          const Text(
            'Long-term Goals',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildLongTermGoal('Become BKFC Champion', '2026', Colors.amber),
          const SizedBox(height: 8),
          _buildLongTermGoal('10-0 Professional Record', '2027', Colors.purple),
          const SizedBox(height: 8),
          _buildLongTermGoal('Open Training Gym', '2028', Colors.teal),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildGoalItem(
    String title,
    double progress,
    String detail,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLongTermGoal(String title, String year, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              year,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _getTypeColor(event['type']), width: 4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getTypeColor(event['type']).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTypeIcon(event['type']),
              color: _getTypeColor(event['type']),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      event['time'],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    if (event['location'] != null) ...[
                      const Text(
                        ' • ',
                        style: TextStyle(color: Colors.white24),
                      ),
                      Text(
                        event['location'],
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getTypeColor(event['type']).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              event['type'],
              style: TextStyle(
                color: _getTypeColor(event['type']),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEventSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Event',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildEventTypeButton(
                  'Training',
                  Icons.fitness_center,
                  Colors.blue,
                ),
                _buildEventTypeButton('Sparring', Icons.sports_mma, Colors.red),
                _buildEventTypeButton('Recovery', Icons.spa, Colors.green),
                _buildEventTypeButton(
                  'Fight',
                  Icons.emoji_events,
                  Colors.amber,
                ),
                _buildEventTypeButton(
                  'Weigh-In',
                  Icons.monitor_weight,
                  Colors.orange,
                ),
                _buildEventTypeButton('Other', Icons.more_horiz, Colors.purple),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeButton(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasEvent(DateTime date) {
    // Simulated events
    final events = [8, 9, 10, 15, 22];
    return events.contains(date.day) && date.month == DateTime.now().month;
  }

  Color _getEventColor(DateTime date) {
    if (date.day == 9) return Colors.red; // Fight day
    if (date.day == 8) return Colors.orange; // Weigh-in
    return Colors.blue; // Training
  }

  List<Map<String, dynamic>> _getEventsForDate(DateTime date) {
    if (date.day == 8 && date.month == DateTime.now().month) {
      return [
        {
          'title': 'Official Weigh-In',
          'time': '12:00 PM',
          'type': 'Weigh-In',
          'location': 'Fight Venue',
        },
        {
          'title': 'Media Day',
          'time': '3:00 PM',
          'type': 'Media',
          'location': 'Hotel Conference Room',
        },
      ];
    }
    if (date.day == 9 && date.month == DateTime.now().month) {
      return [
        {
          'title': 'BKFC Title Fight',
          'time': '9:00 PM',
          'type': 'Fight',
          'location': 'Tampa, FL',
        },
      ];
    }
    return [];
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Training':
        return Colors.blue;
      case 'Sparring':
        return Colors.red;
      case 'Recovery':
        return Colors.green;
      case 'Fight':
        return Colors.amber;
      case 'Weigh-In':
        return Colors.orange;
      case 'Media':
        return Colors.purple;
      case 'Event':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Training':
        return Icons.fitness_center;
      case 'Sparring':
        return Icons.sports_mma;
      case 'Recovery':
        return Icons.spa;
      case 'Fight':
        return Icons.emoji_events;
      case 'Weigh-In':
        return Icons.monitor_weight;
      case 'Media':
        return Icons.videocam;
      default:
        return Icons.event;
    }
  }
}
