import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/fight_card_template.dart';
import '../../../shared/services/fight_card_template_service.dart';
import '../../../shared/services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MY FIGHT CARDS — List / Manage
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Shows saved fight cards + cards shared with the current user.
/// Tap to edit, preview, or delete.
///
/// ═══════════════════════════════════════════════════════════════════════════
class MyFightCardsScreen extends StatefulWidget {
  const MyFightCardsScreen({super.key});

  @override
  State<MyFightCardsScreen> createState() => _MyFightCardsScreenState();
}

class _MyFightCardsScreenState extends State<MyFightCardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    final svc = context.read<FightCardTemplateService>();
    await Future.wait([svc.loadMyCards(uid), svc.loadSharedWithMe(uid)]);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'FIGHT CARDS',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
        backgroundColor: AppTheme.secondaryBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.neonCyan,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'MY CARDS'),
            Tab(text: 'SHARED WITH ME'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.neonCyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'NEW CARD',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        onPressed: () => context.push('/fight-card-builder'),
      ),
      body: Consumer<FightCardTemplateService>(
        builder: (context, svc, _) {
          if (svc.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.neonCyan),
            );
          }

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _buildCardsList(svc.myCards, isOwner: true),
              _buildCardsList(svc.sharedWithMe, isOwner: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardsList(
    List<FightCardTemplate> cards, {
    required bool isOwner,
  }) {
    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOwner ? Icons.note_add : Icons.inbox,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              isOwner ? 'No fight cards yet' : 'No cards shared with you yet',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
            ),
            if (isOwner) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create Fight Card'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.neonCyan,
                  side: const BorderSide(color: AppTheme.neonCyan),
                ),
                onPressed: () => context.push('/fight-card-builder'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.neonCyan,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cards.length,
        itemBuilder: (context, i) => _buildCardTile(cards[i], isOwner: isOwner),
      ),
    );
  }

  Widget _buildCardTile(FightCardTemplate card, {required bool isOwner}) {
    final mainEvent = card.sortedBouts.isNotEmpty
        ? card.sortedBouts.first
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (isOwner) {
            context.push('/fight-card-builder', extra: card.id);
          } else {
            context.push('/fight-card-preview', extra: card);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  const Icon(
                    Icons.sports_mma,
                    color: AppTheme.neonCyan,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.eventName.isEmpty
                          ? 'Untitled Event'
                          : card.eventName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (card.isDraft)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DRAFT',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                      color: AppTheme.cardBackground,
                      onSelected: (v) => _handleMenu(v, card),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'preview',
                          child: Text('Preview'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Meta
              Wrap(
                spacing: 12,
                children: [
                  _meta(Icons.calendar_today, _fmtDate(card.eventDate)),
                  _meta(Icons.location_on, '${card.city}, ${card.country}'),
                  _meta(Icons.sports_mma, '${card.totalBouts} bouts'),
                  _meta(Icons.emoji_events, card.sportType),
                ],
              ),

              if (mainEvent != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFFFD700), width: 3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'MAIN: ',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${mainEvent.redCornerName.isEmpty ? "TBA" : mainEvent.redCornerName} vs ${mainEvent.blueCornerName.isEmpty ? "TBA" : mainEvent.blueCornerName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (!isOwner) ...[
                const SizedBox(height: 8),
                Text(
                  'From: ${card.creatorName}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _handleMenu(String action, FightCardTemplate card) async {
    if (action == 'edit') {
      context.push('/fight-card-builder', extra: card.id);
    } else if (action == 'preview') {
      context.push('/fight-card-preview', extra: card);
    } else if (action == 'delete') {
      final svc = context.read<FightCardTemplateService>();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text(
            'Delete Fight Card?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${card.eventName}"?',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await svc.deleteCard(card.id);
      }
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
