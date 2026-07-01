import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../shared/models/image_rights_model.dart';
import '../../../shared/services/image_rights_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ADMIN IMAGE APPROVAL SCREEN
///
/// The command center for image rights management. Admins can:
/// - Review pending uploads with full attestation details
/// - Approve / reject images with reason tracking
/// - Monitor takedown requests and resolve disputes
/// - View audit trails and pipeline statistics
/// ═══════════════════════════════════════════════════════════════════════════
class ImageApprovalScreen extends StatefulWidget {
  const ImageApprovalScreen({super.key});

  @override
  State<ImageApprovalScreen> createState() => _ImageApprovalScreenState();
}

class _ImageApprovalScreenState extends State<ImageApprovalScreen>
    with SingleTickerProviderStateMixin {
  final _service = ImageRightsService();
  late TabController _tabController;

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
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: DesignTokens.neonGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: DesignTokens.neonGold.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: DesignTokens.neonGold,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IMAGE RIGHTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Admin Approval Dashboard',
                  style: TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonCyan,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: DesignTokens.textMuted,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(text: 'PENDING', icon: Icon(Icons.hourglass_top, size: 18)),
            Tab(text: 'TAKEDOWNS', icon: Icon(Icons.gavel, size: 18)),
            Tab(text: 'STATS', icon: Icon(Icons.analytics, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingReviewTab(service: _service),
          _TakedownTab(service: _service),
          _StatsTab(service: _service),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 1: PENDING REVIEW
// ═══════════════════════════════════════════════════════════════════════════

class _PendingReviewTab extends StatelessWidget {
  final ImageRightsService service;
  const _PendingReviewTab({required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ImageRightsModel>>(
      stream: service.streamPendingImages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.neonCyan),
          );
        }

        final images = snapshot.data ?? [];

        if (images.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: DesignTokens.neonGreen.withValues(alpha: 0.5),
                  size: 56,
                ),
                const SizedBox(height: 16),
                const Text(
                  'ALL CLEAR',
                  style: TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No images pending review',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          itemCount: images.length,
          itemBuilder: (context, index) =>
              _PendingImageCard(image: images[index], service: service),
        );
      },
    );
  }
}

class _PendingImageCard extends StatefulWidget {
  final ImageRightsModel image;
  final ImageRightsService service;

  const _PendingImageCard({required this.image, required this.service});

  @override
  State<_PendingImageCard> createState() => _PendingImageCardState();
}

class _PendingImageCardState extends State<_PendingImageCard> {
  bool _expanded = false;
  bool _processing = false;

  Future<void> _approve() async {
    setState(() => _processing = true);
    try {
      await widget.service.approveImage(widget.image.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image approved'),
            backgroundColor: Color(0xFF00FF88),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DesignTokens.neonRed,
          ),
        );
      }
    }
    if (mounted) setState(() => _processing = false);
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _RejectDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _processing = true);
    try {
      await widget.service.rejectImage(widget.image.id, reason.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image rejected'),
            backgroundColor: DesignTokens.neonAmber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DesignTokens.neonRed,
          ),
        );
      }
    }
    if (mounted) setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.image;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: Container(
        decoration: GlassDecoration.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Thumbnail + basic info ──
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSmall,
                        ),
                        border: Border.all(color: DesignTokens.borderSubtle),
                        image:
                            (img.thumbnailUrl != null &&
                                img.thumbnailUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: ImageAssets.resolveImage(
                                  img.thumbnailUrl!,
                                ),
                                fit: BoxFit.cover,
                                onError: (_, _) {},
                              )
                            : null,
                        color: DesignTokens.bgCard,
                      ),
                      child:
                          (img.thumbnailUrl == null ||
                              img.thumbnailUrl!.isEmpty)
                          ? const Icon(
                              Icons.image,
                              color: DesignTokens.textMuted,
                              size: 28,
                            )
                          : null,
                    ),
                    const SizedBox(width: DesignTokens.spacingM),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            img.ownerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            img.ownerEmail,
                            style: const TextStyle(
                              color: DesignTokens.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _chip(
                                img.ownerType.name.toUpperCase(),
                                AppTheme.neonMagenta,
                              ),
                              const SizedBox(width: 6),
                              _chip(
                                img.licenseType.name.toUpperCase(),
                                AppTheme.neonCyan,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Arrow
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: DesignTokens.textMuted,
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded details ──
            if (_expanded) ...[
              const Divider(color: DesignTokens.borderSubtle, height: 1),
              Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(
                      'Attestation',
                      img.attestationSigned ? 'SIGNED' : 'MISSING',
                      color: img.attestationSigned
                          ? DesignTokens.neonGreen
                          : DesignTokens.neonRed,
                    ),
                    _detailRow(
                      'Uploaded',
                      img.createdAt.toString().split('.').first,
                    ),
                    if (img.sourceEventId != null)
                      _detailRow('Event', img.sourceEventId!),
                    if (img.licenseNotes != null &&
                        img.licenseNotes!.isNotEmpty)
                      _detailRow('License Notes', img.licenseNotes!),
                    _detailRow(
                      'Scopes',
                      img.allowedScopes
                          .map((s) => s.name.toUpperCase())
                          .join(', '),
                    ),
                    if (img.tags.isNotEmpty)
                      _detailRow('Tags', img.tags.join(', ')),
                    const SizedBox(height: DesignTokens.spacingM),

                    // Full image preview
                    if (img.url.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSmall,
                        ),
                        child: ImageAssets.isLocalAsset(img.url)
                            ? Image.asset(
                                img.url,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  height: 200,
                                  color: DesignTokens.bgCard,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: DesignTokens.textMuted,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              )
                            : DfcNetworkImage(
                                url: img.url,
                                height: 200,
                                width: double.infinity,
                              ),
                      ),
                  ],
                ),
              ),
            ],

            // ── Action bar ──
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingS,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.bgSecondary.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(DesignTokens.radiusMedium),
                  bottomRight: Radius.circular(DesignTokens.radiusMedium),
                ),
              ),
              child: _processing
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Reject
                        TextButton.icon(
                          onPressed: _reject,
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: DesignTokens.neonRed,
                          ),
                          label: const Text(
                            'REJECT',
                            style: TextStyle(
                              color: DesignTokens.neonRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Approve
                        ElevatedButton.icon(
                          onPressed: _approve,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text(
                            'APPROVE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.neonGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusSmall,
                              ),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? DesignTokens.textSecondary,
                fontSize: 12,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reject Reason Dialog ──────────────────────────────────────────────────

class _RejectDialog extends StatefulWidget {
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignTokens.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        side: const BorderSide(color: DesignTokens.borderSubtle),
      ),
      title: const Row(
        children: [
          Icon(Icons.block, color: DesignTokens.neonRed, size: 22),
          SizedBox(width: 10),
          Text(
            'REJECT IMAGE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Provide a reason for rejection. This will be visible to the uploader.',
            style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. Image contains watermark, low resolution...',
              hintStyle: const TextStyle(
                color: DesignTokens.textDisabled,
                fontSize: 12,
              ),
              filled: true,
              fillColor: DesignTokens.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                borderSide: const BorderSide(color: DesignTokens.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                borderSide: const BorderSide(color: DesignTokens.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                borderSide: BorderSide(
                  color: DesignTokens.neonRed.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: DesignTokens.textMuted,
              letterSpacing: 1,
              fontSize: 12,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.neonRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            elevation: 0,
          ),
          child: const Text(
            'REJECT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 2: TAKEDOWNS
// ═══════════════════════════════════════════════════════════════════════════

class _TakedownTab extends StatelessWidget {
  final ImageRightsService service;
  const _TakedownTab({required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ImageTakedownModel>>(
      stream: service.streamTakedowns(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.neonCyan),
          );
        }

        final takedowns = snapshot.data ?? [];

        if (takedowns.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: DesignTokens.neonGreen.withValues(alpha: 0.5),
                  size: 56,
                ),
                const SizedBox(height: 16),
                const Text(
                  'NO ACTIVE TAKEDOWNS',
                  style: TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'All clear — no DMCA or takedown requests',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          itemCount: takedowns.length,
          itemBuilder: (context, index) =>
              _TakedownCard(takedown: takedowns[index], service: service),
        );
      },
    );
  }
}

class _TakedownCard extends StatefulWidget {
  final ImageTakedownModel takedown;
  final ImageRightsService service;
  const _TakedownCard({required this.takedown, required this.service});

  @override
  State<_TakedownCard> createState() => _TakedownCardState();
}

class _TakedownCardState extends State<_TakedownCard> {
  bool _processing = false;

  Color _statusColor(TakedownStatus status) {
    switch (status) {
      case TakedownStatus.received:
        return DesignTokens.neonAmber;
      case TakedownStatus.investigating:
        return AppTheme.neonCyan;
      case TakedownStatus.upheld:
        return DesignTokens.neonRed;
      case TakedownStatus.dismissed:
        return DesignTokens.neonGreen;
      case TakedownStatus.restored:
        return AppTheme.neonPurple;
    }
  }

  Future<void> _resolve(bool upheld) async {
    setState(() => _processing = true);
    try {
      await widget.service.resolveTakedown(
        takedownId: widget.takedown.id,
        upheld: upheld,
        resolution: upheld
            ? 'Takedown upheld by admin'
            : 'Takedown dismissed by admin',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              upheld
                  ? 'Takedown upheld — image removed'
                  : 'Takedown dismissed — image restored',
            ),
            backgroundColor: upheld
                ? DesignTokens.neonRed
                : DesignTokens.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DesignTokens.neonRed,
          ),
        );
      }
    }
    if (mounted) setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    final td = widget.takedown;
    final statusColor = _statusColor(td.status);
    final isPending =
        td.status == TakedownStatus.received ||
        td.status == TakedownStatus.investigating;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.gavel, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TAKEDOWN #${td.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    td.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingM),

            // Details
            _tdRow('Reporter', td.complainantName),
            _tdRow('Email', td.complainantEmail),
            _tdRow('Reason', td.reason),
            _tdRow('Filed', td.receivedAt.toString().split('.').first),
            if (td.resolvedAt != null)
              _tdRow('Resolved', td.resolvedAt!.toString().split('.').first),

            // Actions
            if (isPending && !_processing) ...[
              const SizedBox(height: DesignTokens.spacingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _resolve(false),
                    child: const Text(
                      'DISMISS',
                      style: TextStyle(
                        color: DesignTokens.neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _resolve(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.neonRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSmall,
                        ),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'UPHOLD & REMOVE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_processing)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tdRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: DesignTokens.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 3: STATS
// ═══════════════════════════════════════════════════════════════════════════

class _StatsTab extends StatefulWidget {
  final ImageRightsService service;
  const _StatsTab({required this.service});

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  Map<String, int>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await widget.service.getImageStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.neonCyan),
      );
    }

    if (_stats == null) {
      return const Center(
        child: Text(
          'Failed to load stats',
          style: TextStyle(color: DesignTokens.textMuted),
        ),
      );
    }

    final tiles = [
      _StatTile(
        'PENDING',
        _stats!['pending'] ?? 0,
        DesignTokens.neonAmber,
        Icons.hourglass_top,
      ),
      _StatTile(
        'APPROVED',
        _stats!['approved'] ?? 0,
        DesignTokens.neonGreen,
        Icons.check_circle,
      ),
      _StatTile(
        'REJECTED',
        _stats!['rejected'] ?? 0,
        DesignTokens.neonRed,
        Icons.cancel,
      ),
      _StatTile(
        'REVOKED',
        _stats!['revoked'] ?? 0,
        AppTheme.neonPurple,
        Icons.remove_circle,
      ),
      _StatTile(
        'EXPIRED',
        _stats!['expired'] ?? 0,
        DesignTokens.textMuted,
        Icons.timer_off,
      ),
      _StatTile(
        'TAKEN DOWN',
        _stats!['takenDown'] ?? 0,
        DesignTokens.neonRed,
        Icons.gavel,
      ),
      _StatTile(
        'TOTAL',
        _stats!['total'] ?? 0,
        AppTheme.neonCyan,
        Icons.photo_library,
      ),
    ];

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppTheme.neonCyan,
      backgroundColor: DesignTokens.bgSecondary,
      child: ListView(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            decoration: GlassDecoration.card(accent: DesignTokens.neonGold),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: DesignTokens.neonGold,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PIPELINE OVERVIEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      '${_stats!['total'] ?? 0} total images in system',
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: DesignTokens.spacingM,
            crossAxisSpacing: DesignTokens.spacingM,
            childAspectRatio: 1.6,
            children: tiles.map(_buildStatTile).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(_StatTile tile) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: tile.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: tile.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(tile.icon, color: tile.color, size: 22),
          const Spacer(),
          Text(
            tile.count.toString(),
            style: TextStyle(
              color: tile.color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            tile.label,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _StatTile(this.label, this.count, this.color, this.icon);
}
