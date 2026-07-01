import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/daily_grind_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/dfc_card.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DAILY GRIND SCREEN — Training Schedule Planner
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Features:
///  • Day / Week toggle view
///  • Add, Edit, Delete, Reschedule sessions
///  • RPE logging after completion
///  • Recurring schedules
///  • AI daily summary
/// ═══════════════════════════════════════════════════════════════════════════

class DailyGrindScreen extends StatefulWidget {
  const DailyGrindScreen({super.key});

  @override
  State<DailyGrindScreen> createState() => _DailyGrindScreenState();
}

class _DailyGrindScreenState extends State<DailyGrindScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<GrindEntry> _weekEntries = [];
  bool _weekLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    final uid = context.read<AuthService>().currentUser?.uid ?? 'demo';
    final svc = context.read<DailyGrindService>();
    svc.loadDay(uid, DateTime.now());
    _loadWeek(uid, svc);
  }

  Future<void> _loadWeek(String uid, DailyGrindService svc) async {
    setState(() => _weekLoading = true);
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _weekEntries = await svc.loadWeek(uid, monday);
    setState(() => _weekLoading = false);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'DAILY GRIND',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2,
            color: DesignTokens.neonCyan,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: DesignTokens.neonCyan,
          labelColor: DesignTokens.neonCyan,
          unselectedLabelColor: DesignTokens.textMuted,
          tabs: const [
            Tab(text: 'TODAY', icon: Icon(Icons.today, size: 18)),
            Tab(text: 'WEEK', icon: Icon(Icons.calendar_view_week, size: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: DesignTokens.textMuted),
            onPressed: _showDailySummary,
            tooltip: 'Daily Summary',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_buildDayView(), _buildWeekView()],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DesignTokens.neonCyan,
        foregroundColor: Colors.black,
        onPressed: _showAddSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ═══════════ DAY VIEW ════════════════════════════════════════
  Widget _buildDayView() {
    return Consumer<DailyGrindService>(
      builder: (context, svc, _) {
        if (svc.loading) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.neonCyan),
          );
        }

        return Column(
          children: [
            // Date navigator
            _buildDateNav(svc),

            // Stats bar
            _buildDayStats(svc.entries),

            // Session list
            Expanded(
              child: svc.entries.isEmpty
                  ? _buildEmptyDay()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: svc.entries.length,
                      itemBuilder: (_, i) => _buildSessionCard(svc.entries[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateNav(DailyGrindService svc) {
    final d = svc.focusDate;
    final isToday = _isSameDay(d, DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: DesignTokens.textMuted),
            onPressed: () {
              final prev = d.subtract(const Duration(days: 1));
              final uid =
                  context.read<AuthService>().currentUser?.uid ?? 'demo';
              svc.loadDay(uid, prev);
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final uid =
                    context.read<AuthService>().currentUser?.uid ?? 'demo';
                final picked = await showDatePicker(
                  context: context,
                  initialDate: d,
                  firstDate: d.subtract(const Duration(days: 365)),
                  lastDate: d.add(const Duration(days: 365)),
                );
                if (picked != null && mounted) {
                  svc.loadDay(uid, picked);
                }
              },
              child: Column(
                children: [
                  Text(
                    _formatWeekday(d),
                    style: TextStyle(
                      color: isToday
                          ? DesignTokens.neonCyan
                          : DesignTokens.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_monthName(d.month)} ${d.day}, ${d.year}',
                    style: TextStyle(
                      color: isToday
                          ? DesignTokens.neonCyan
                          : DesignTokens.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          color: DesignTokens.neonCyan,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              color: DesignTokens.textMuted,
            ),
            onPressed: () {
              final next = d.add(const Duration(days: 1));
              final uid =
                  context.read<AuthService>().currentUser?.uid ?? 'demo';
              svc.loadDay(uid, next);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayStats(List<GrindEntry> entries) {
    final total = entries.length;
    final completed = entries.where((e) => e.isCompleted).length;
    final totalMin = entries.fold<int>(0, (s, e) => s + e.durationMinutes);
    final avgRpe = entries
        .where((e) => e.rpeAfter != null)
        .fold<double>(0, (s, e) => s + (e.rpeAfter ?? 0));
    final rpeCount = entries.where((e) => e.rpeAfter != null).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DFCCard(
        style: DFCCardStyle.compact,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('Sessions', '$completed/$total', DesignTokens.neonCyan),
              _miniStat('Total', '${totalMin}min', DesignTokens.neonGreen),
              _miniStat(
                'Avg RPE',
                rpeCount > 0 ? (avgRpe / rpeCount).toStringAsFixed(1) : '—',
                DesignTokens.neonAmber,
              ),
              _miniStat(
                'Status',
                completed == total && total > 0 ? '✅ DONE' : '🔥 GRIND',
                completed == total && total > 0
                    ? DesignTokens.neonGreen
                    : DesignTokens.neonRed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ─── SESSION CARD ─────────────────────────────────────────
  Widget _buildSessionCard(GrindEntry entry) {
    final priorityColor = _priorityColor(entry.priority);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DFCCard(
        accent: priorityColor,
        onTap: () => _showEditSheet(entry),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: time + type + priority
              Row(
                children: [
                  // Time chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: priorityColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${entry.startTime} — ${entry.endTime}',
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Activity emoji
                  Text(
                    entry.activityType.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.activityType.label,
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Completed indicator
                  if (entry.isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: DesignTokens.neonGreen,
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      color: DesignTokens.textMuted.withValues(alpha: 0.4),
                      size: 20,
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Title
              Text(
                entry.title,
                style: TextStyle(
                  color: entry.isCompleted
                      ? DesignTokens.textMuted
                      : DesignTokens.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  decoration: entry.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),

              // Notes
              if (entry.notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  entry.notes,
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 10),

              // Bottom row: location, coach, duration, actions
              Row(
                children: [
                  if (entry.location.isNotEmpty) ...[
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: DesignTokens.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        entry.location,
                        style: const TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (entry.coach.isNotEmpty) ...[
                    const Icon(
                      Icons.person,
                      size: 12,
                      color: DesignTokens.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      entry.coach,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  const Icon(
                    Icons.timer,
                    size: 12,
                    color: DesignTokens.textMuted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${entry.durationMinutes}min',
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  // RPE badge
                  if (entry.rpeAfter != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _rpeColor(
                          entry.rpeAfter!,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'RPE ${entry.rpeAfter!.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: _rpeColor(entry.rpeAfter!),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  // Action menu
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: DesignTokens.textMuted,
                    ),
                    color: DesignTokens.bgCard,
                    onSelected: (v) => _handleAction(v, entry),
                    itemBuilder: (_) => [
                      if (!entry.isCompleted)
                        const PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check,
                                size: 16,
                                color: DesignTokens.neonGreen,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Mark Complete',
                                style: TextStyle(
                                  color: DesignTokens.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!entry.isCompleted)
                        const PopupMenuItem(
                          value: 'rpe',
                          child: Row(
                            children: [
                              Icon(
                                Icons.speed,
                                size: 16,
                                color: DesignTokens.neonAmber,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Log RPE',
                                style: TextStyle(
                                  color: DesignTokens.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'reschedule',
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: DesignTokens.neonCyan,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Reschedule',
                              style: TextStyle(color: DesignTokens.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 16,
                              color: DesignTokens.neonAmber,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(color: DesignTokens.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 16,
                              color: DesignTokens.neonRed,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: DesignTokens.neonRed),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(String action, GrindEntry entry) {
    final uid = context.read<AuthService>().currentUser?.uid ?? 'demo';
    final svc = context.read<DailyGrindService>();

    switch (action) {
      case 'complete':
        svc.toggleComplete(uid, entry);
        break;
      case 'rpe':
        _showRpeDialog(entry);
        break;
      case 'reschedule':
        _showRescheduleDialog(entry);
        break;
      case 'edit':
        _showEditSheet(entry);
        break;
      case 'delete':
        _confirmDelete(entry);
        break;
    }
  }

  Widget _buildEmptyDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rest Day?',
            style: TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No sessions scheduled.\nTap + to add your grind.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ═══════════ WEEK VIEW ═══════════════════════════════════════
  Widget _buildWeekView() {
    if (_weekLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DesignTokens.neonCyan),
      );
    }

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 7,
      itemBuilder: (_, dayIndex) {
        final day = days[dayIndex];
        final dayEntries = _weekEntries
            .where((e) => _isSameDay(e.date, day))
            .toList();
        final isToday = _isSameDay(day, now);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DFCCard(
            accent: isToday ? DesignTokens.neonCyan : DesignTokens.textMuted,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isToday
                              ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: isToday
                              ? Border.all(color: DesignTokens.neonCyan)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isToday
                                ? DesignTokens.neonCyan
                                : DesignTokens.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatWeekday(day),
                            style: TextStyle(
                              color: isToday
                                  ? DesignTokens.neonCyan
                                  : DesignTokens.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${dayEntries.length} sessions • '
                            '${dayEntries.fold<int>(0, (s, e) => s + e.durationMinutes)}min',
                            style: const TextStyle(
                              color: DesignTokens.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonCyan.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              color: DesignTokens.neonCyan,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (dayEntries.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(color: DesignTokens.textMuted, height: 1),
                    const SizedBox(height: 8),
                    ...dayEntries.map(_buildWeekEntryRow),
                  ] else ...[
                    const SizedBox(height: 8),
                    const Text(
                      '  😴  Rest Day',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekEntryRow(GrindEntry e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(e.activityType.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            e.startTime,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              e.title,
              style: TextStyle(
                color: e.isCompleted
                    ? DesignTokens.textMuted
                    : DesignTokens.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: e.isCompleted ? TextDecoration.lineThrough : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${e.durationMinutes}m',
            style: const TextStyle(color: DesignTokens.textMuted, fontSize: 11),
          ),
          if (e.isCompleted)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.check_circle,
                size: 14,
                color: DesignTokens.neonGreen,
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════ ADD / EDIT SHEET ════════════════════════════════
  void _showAddSheet() => _showEntrySheet(null);
  void _showEditSheet(GrindEntry entry) => _showEntrySheet(entry);

  void _showEntrySheet(GrindEntry? existing) {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final coachCtrl = TextEditingController(text: existing?.coach ?? '');

    var actType = existing?.activityType ?? GrindActivityType.striking;
    var priority = existing?.priority ?? GrindPriority.normal;
    var startTime = existing?.startTime ?? '06:00';
    var endTime = existing?.endTime ?? '07:00';
    var duration = existing?.durationMinutes ?? 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          isEdit ? '✏️ EDIT SESSION' : '➕ NEW SESSION',
                          style: const TextStyle(
                            color: DesignTokens.neonCyan,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: DesignTokens.textMuted,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Activity type dropdown
                    DropdownButtonFormField<GrindActivityType>(
                      initialValue: actType,
                      decoration: _inputDeco('Activity Type'),
                      dropdownColor: DesignTokens.bgCard,
                      style: const TextStyle(color: DesignTokens.textPrimary),
                      items: GrindActivityType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text('${t.emoji}  ${t.label}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setSheetState(() => actType = v!),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: DesignTokens.textPrimary),
                      decoration: _inputDeco('Session Title'),
                    ),
                    const SizedBox(height: 12),

                    // Time row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: ctx,
                                initialTime: _parseTime(startTime),
                              );
                              if (t != null) {
                                setSheetState(() {
                                  startTime = _formatTimeOfDay(t);
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: _inputDeco('Start'),
                              child: Text(
                                startTime,
                                style: const TextStyle(
                                  color: DesignTokens.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: ctx,
                                initialTime: _parseTime(endTime),
                              );
                              if (t != null) {
                                setSheetState(() {
                                  endTime = _formatTimeOfDay(t);
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: _inputDeco('End'),
                              child: Text(
                                endTime,
                                style: const TextStyle(
                                  color: DesignTokens.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            style: const TextStyle(
                              color: DesignTokens.textPrimary,
                            ),
                            decoration: _inputDeco('Min'),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(
                              text: '$duration',
                            ),
                            onChanged: (v) => duration = int.tryParse(v) ?? 60,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Location + Coach
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: locationCtrl,
                            style: const TextStyle(
                              color: DesignTokens.textPrimary,
                            ),
                            decoration: _inputDeco('Location'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: coachCtrl,
                            style: const TextStyle(
                              color: DesignTokens.textPrimary,
                            ),
                            decoration: _inputDeco('Coach'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Priority
                    DropdownButtonFormField<GrindPriority>(
                      initialValue: priority,
                      decoration: _inputDeco('Priority'),
                      dropdownColor: DesignTokens.bgCard,
                      style: const TextStyle(color: DesignTokens.textPrimary),
                      items: GrindPriority.values
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setSheetState(() => priority = v!),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: notesCtrl,
                      style: const TextStyle(color: DesignTokens.textPrimary),
                      decoration: _inputDeco('Notes'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final uid =
                              context.read<AuthService>().currentUser?.uid ??
                              'demo';
                          final svc = context.read<DailyGrindService>();
                          final now = DateTime.now();

                          final entry = GrindEntry(
                            id: existing?.id ?? '',
                            userId: uid,
                            date: svc.focusDate,
                            startTime: startTime,
                            endTime: endTime,
                            activityType: actType,
                            title: titleCtrl.text.isNotEmpty
                                ? titleCtrl.text
                                : actType.label,
                            notes: notesCtrl.text,
                            location: locationCtrl.text,
                            coach: coachCtrl.text,
                            priority: priority,
                            durationMinutes: duration,
                            isCompleted: existing?.isCompleted ?? false,
                            rpeAfter: existing?.rpeAfter,
                            createdAt: existing?.createdAt ?? now,
                            updatedAt: now,
                          );

                          if (isEdit) {
                            svc.updateEntry(uid, entry);
                          } else {
                            svc.addEntry(uid, entry);
                          }
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.neonCyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isEdit ? 'UPDATE SESSION' : 'ADD SESSION',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════ DIALOGS ════════════════════════════════════════
  void _confirmDelete(GrindEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text(
          'Delete Session',
          style: TextStyle(color: DesignTokens.neonRed),
        ),
        content: Text(
          'Delete "${entry.title}"?',
          style: const TextStyle(color: DesignTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: DesignTokens.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final uid =
                  context.read<AuthService>().currentUser?.uid ?? 'demo';
              context.read<DailyGrindService>().deleteEntry(uid, entry);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonRed,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRpeDialog(GrindEntry entry) {
    double rpe = 5.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: DesignTokens.bgCard,
          title: const Text(
            'Log RPE',
            style: TextStyle(color: DesignTokens.neonAmber),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Rate of Perceived Exertion',
                style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                rpe.toStringAsFixed(0),
                style: TextStyle(
                  color: _rpeColor(rpe),
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Slider(
                value: rpe,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: _rpeColor(rpe),
                label: rpe.toStringAsFixed(0),
                onChanged: (v) => setDlgState(() => rpe = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: DesignTokens.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final uid =
                    context.read<AuthService>().currentUser?.uid ?? 'demo';
                context.read<DailyGrindService>().logRpe(uid, entry, rpe);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonAmber,
              ),
              child: const Text('Log', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRescheduleDialog(GrindEntry entry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: entry.date,
      firstDate: entry.date.subtract(const Duration(days: 30)),
      lastDate: entry.date.add(const Duration(days: 90)),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _parseTime(entry.startTime),
      );
      if (time != null && mounted) {
        final uid = context.read<AuthService>().currentUser?.uid ?? 'demo';
        context.read<DailyGrindService>().reschedule(
          uid,
          entry,
          picked,
          newStart: _formatTimeOfDay(time),
        );
      }
    }
  }

  void _showDailySummary() {
    final svc = context.read<DailyGrindService>();
    final summary = svc.dailySummary(svc.entries);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text(
          'Daily Summary',
          style: TextStyle(color: DesignTokens.neonCyan),
        ),
        content: SingleChildScrollView(
          child: Text(
            summary,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: DesignTokens.neonCyan),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════ HELPERS ════════════════════════════════════════
  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: DesignTokens.textMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: DesignTokens.textMuted.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DesignTokens.neonCyan),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Color _priorityColor(GrindPriority p) {
    switch (p) {
      case GrindPriority.critical:
        return DesignTokens.neonRed;
      case GrindPriority.high:
        return DesignTokens.neonAmber;
      case GrindPriority.normal:
        return DesignTokens.neonCyan;
      case GrindPriority.low:
        return DesignTokens.textMuted;
    }
  }

  Color _rpeColor(double rpe) {
    if (rpe <= 3) return DesignTokens.neonGreen;
    if (rpe <= 5) return DesignTokens.neonCyan;
    if (rpe <= 7) return DesignTokens.neonAmber;
    return DesignTokens.neonRed;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatWeekday(DateTime d) {
    const days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return days[d.weekday - 1];
  }

  String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 6,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
