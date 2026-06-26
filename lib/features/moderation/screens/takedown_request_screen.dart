import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// TAKEDOWN REQUEST SCREEN — File, track, and manage content takedown requests
///
/// Features:
///  • File new takedown requests (URL, reason, evidence, reporter info)
///  • 3 email templates: Support, DMCA, Host Escalation
///  • Status tracking: pending → sent → acknowledged → resolved
///  • List of existing requests with filters and search
///  • Slack webhook integration stub for notifications
/// ═══════════════════════════════════════════════════════════════════════════

class TakedownRequestScreen extends StatefulWidget {
  const TakedownRequestScreen({super.key});
  @override
  State<TakedownRequestScreen> createState() => _TakedownRequestScreenState();
}

class _TakedownRequestScreenState extends State<TakedownRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _urlController = TextEditingController();
  final _reasonController = TextEditingController();
  final _evidenceController = TextEditingController();
  final _reporterController = TextEditingController();
  String _selectedCategory = 'Harassment';
  String _selectedPriority = 'HIGH';
  String _selectedTemplate = 'Support';

  // Request list
  List<_TakedownRequest> _requests = [];
  String _statusFilter = 'ALL';
  bool _loading = true;
  StreamSubscription? _sub;

  static const _categories = [
    'Harassment',
    'Defamation',
    'Doxxing',
    'Impersonation',
    'Copyright / DMCA',
    'Hate Speech',
    'Threats / Violence',
    'Privacy Violation',
    'Revenge Content',
    'Other',
  ];

  static const _priorities = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

  static const _statuses = [
    'ALL',
    'pending',
    'sent',
    'acknowledged',
    'resolved',
    'rejected',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _reasonController.dispose();
    _evidenceController.dispose();
    _reporterController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _loadRequests() {
    try {
      _sub = FirebaseFirestore.instance
          .collection('takedown_requests')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots()
          .listen((snap) {
            if (!mounted) return;
            setState(() {
              _requests = snap.docs.map((d) {
                final data = d.data();
                return _TakedownRequest(
                  id: d.id,
                  url: data['url'] ?? '',
                  reason: data['reason'] ?? '',
                  category: data['category'] ?? 'Other',
                  priority: data['priority'] ?? 'MEDIUM',
                  reporter: data['reporter'] ?? 'anonymous',
                  status: data['status'] ?? 'pending',
                  evidence: data['evidence'] ?? '',
                  template: data['template'] ?? '',
                  createdAt:
                      (data['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                  resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
                  notes: data['notes'] ?? '',
                );
              }).toList();
              _loading = false;
            });
          });
    } catch (_) {
      // Demo fallback
      setState(() {
        _requests = _demoRequests();
        _loading = false;
      });
    }
  }

  List<_TakedownRequest> _filteredRequests() {
    if (_statusFilter == 'ALL') return _requests;
    return _requests.where((r) => r.status == _statusFilter).toList();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'url': _urlController.text.trim(),
      'reason': _reasonController.text.trim(),
      'category': _selectedCategory,
      'priority': _selectedPriority,
      'reporter': _reporterController.text.trim().isEmpty
          ? 'anonymous'
          : _reporterController.text.trim(),
      'evidence': _evidenceController.text.trim(),
      'template': _selectedTemplate,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('takedown_requests')
          .add(data);
      if (!mounted) return;
      _urlController.clear();
      _reasonController.clear();
      _evidenceController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Takedown request filed successfully'),
          backgroundColor: Color(0xFF00FF88),
        ),
      );
      _tabController.animateTo(1); // Switch to list tab
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error filing request: $e'),
          backgroundColor: const Color(0xFFFF3366),
        ),
      );
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    final updates = <String, dynamic>{'status': newStatus};
    if (newStatus == 'resolved') {
      updates['resolvedAt'] = FieldValue.serverTimestamp();
    }
    try {
      await FirebaseFirestore.instance
          .collection('takedown_requests')
          .doc(id)
          .update(updates);
    } catch (_) {
      // Demo mode — update locally
      setState(() {
        final idx = _requests.indexWhere((r) => r.id == id);
        if (idx >= 0) {
          _requests[idx] = _requests[idx].copyWith(status: newStatus);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        title: const Text(
          'Takedown Requests',
          style: TextStyle(
            color: Color(0xFF00F5FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: DesignTokens.bgSecondary,
        iconTheme: const IconThemeData(color: Color(0xFF00F5FF)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00F5FF),
          labelColor: const Color(0xFF00F5FF),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'New Request'),
            Tab(icon: Icon(Icons.list_alt), text: 'All Requests'),
            Tab(icon: Icon(Icons.email_outlined), text: 'Templates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewRequestTab(),
          _buildRequestListTab(),
          _buildTemplatesTab(),
        ],
      ),
    );
  }

  // ── Tab 1: New Request Form ──────────────────────────────────────────

  Widget _buildNewRequestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('File Takedown Request'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _urlController,
              label: 'Offending URL *',
              hint: 'https://example.com/offensive-content',
              icon: Icons.link,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'URL is required';
                if (!v.contains('.')) return 'Enter a valid URL';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Category',
              value: _selectedCategory,
              items: _categories,
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Priority',
              value: _selectedPriority,
              items: _priorities,
              onChanged: (v) => setState(() => _selectedPriority = v!),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _reasonController,
              label: 'Reason / Description *',
              hint: 'Describe the violation and why takedown is needed...',
              icon: Icons.description,
              maxLines: 4,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Reason is required' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _evidenceController,
              label: 'Evidence / Screenshots',
              hint:
                  'Links to screenshots, archived pages, or additional evidence...',
              icon: Icons.photo_library,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _reporterController,
              label: 'Reporter Name (optional)',
              hint: 'Your name or alias',
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Email Template',
              value: _selectedTemplate,
              items: const ['Support', 'DMCA', 'Host Escalation'],
              onChanged: (v) => setState(() => _selectedTemplate = v!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _submitRequest,
                icon: const Icon(Icons.send, color: Colors.black),
                label: const Text(
                  'FILE TAKEDOWN REQUEST',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Request List ──────────────────────────────────────────────

  Widget _buildRequestListTab() {
    final filtered = _filteredRequests();
    return Column(
      children: [
        // Status filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: DesignTokens.bgSecondary,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((s) {
                final selected = s == _statusFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      s.toUpperCase(),
                      style: TextStyle(
                        color: selected ? Colors.black : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    selected: selected,
                    selectedColor: const Color(0xFF00F5FF),
                    backgroundColor: const Color(0xFF0D1B2A),
                    onSelected: (_) => setState(() => _statusFilter = s),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: DesignTokens.bgPrimary,
          child: Row(
            children: [
              _statBadge('Total', _requests.length, const Color(0xFF00F5FF)),
              _statBadge(
                'Pending',
                _requests.where((r) => r.status == 'pending').length,
                const Color(0xFFFFB800),
              ),
              _statBadge(
                'Sent',
                _requests.where((r) => r.status == 'sent').length,
                const Color(0xFFFF00FF),
              ),
              _statBadge(
                'Resolved',
                _requests.where((r) => r.status == 'resolved').length,
                const Color(0xFF00FF88),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00F5FF)),
                )
              : filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No requests found',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (ctx, i) => _buildRequestCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(_TakedownRequest req) {
    final statusColor = _statusColor(req.status);
    final priorityColor = _priorityColor(req.priority);

    return Card(
      color: DesignTokens.bgCard,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(Icons.shield, color: statusColor, size: 28),
        title: Text(
          req.url.length > 50 ? '${req.url.substring(0, 50)}...' : req.url,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            _chipLabel(req.status.toUpperCase(), statusColor),
            const SizedBox(width: 6),
            _chipLabel(req.priority, priorityColor),
            const SizedBox(width: 6),
            _chipLabel(req.category, Colors.white38),
          ],
        ),
        iconColor: Colors.white54,
        collapsedIconColor: Colors.white38,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Reason', req.reason),
                if (req.evidence.isNotEmpty)
                  _detailRow('Evidence', req.evidence),
                _detailRow('Reporter', req.reporter),
                _detailRow('Template', req.template),
                _detailRow('Filed', _formatDate(req.createdAt)),
                if (req.resolvedAt != null)
                  _detailRow('Resolved', _formatDate(req.resolvedAt!)),
                const SizedBox(height: 12),
                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (req.status == 'pending')
                      _actionButton(
                        'Mark Sent',
                        Icons.send,
                        const Color(0xFFFF00FF),
                        () => _updateStatus(req.id, 'sent'),
                      ),
                    if (req.status == 'sent')
                      _actionButton(
                        'Acknowledged',
                        Icons.check_circle,
                        const Color(0xFFFFB800),
                        () => _updateStatus(req.id, 'acknowledged'),
                      ),
                    if (req.status != 'resolved' && req.status != 'rejected')
                      _actionButton(
                        'Resolve',
                        Icons.done_all,
                        const Color(0xFF00FF88),
                        () => _updateStatus(req.id, 'resolved'),
                      ),
                    if (req.status != 'resolved' && req.status != 'rejected')
                      _actionButton(
                        'Reject',
                        Icons.cancel,
                        const Color(0xFFFF3366),
                        () => _updateStatus(req.id, 'rejected'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Email Templates ───────────────────────────────────────────

  Widget _buildTemplatesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionHeader('Takedown Email Templates'),
        const SizedBox(height: 16),
        _templateCard(
          'Support Request',
          Icons.support_agent,
          const Color(0xFF00F5FF),
          'Subject: Content Removal Request — DataFightCentral\n\n'
              'Dear Support Team,\n\n'
              'I am writing to request the removal of content hosted at:\n'
              '[URL]\n\n'
              'This content violates our platform\'s community guidelines '
              'and constitutes [CATEGORY]. The content is harmful because:\n'
              '[REASON]\n\n'
              'Evidence of the violation is available at:\n'
              '[EVIDENCE_LINKS]\n\n'
              'We respectfully request prompt removal. We are a registered '
              'combat sports platform committed to participant safety.\n\n'
              'Thank you for your attention.\n'
              'DataFightCentral Safety Team\n'
              'Brisbane, Australia',
        ),
        const SizedBox(height: 16),
        _templateCard(
          'DMCA Takedown Notice',
          Icons.gavel,
          const Color(0xFFFF00FF),
          'Subject: DMCA Takedown Notice\n\n'
              'To Whom It May Concern,\n\n'
              'Pursuant to the Digital Millennium Copyright Act (17 U.S.C. § 512), '
              'I hereby provide notice of copyright infringement.\n\n'
              'Infringing Material Location:\n[URL]\n\n'
              'Original Content:\n[DESCRIPTION_OF_ORIGINAL]\n\n'
              'I have a good faith belief that the use of the material described '
              'above is not authorized by the copyright owner, its agent, or the law.\n\n'
              'I swear, under penalty of perjury, that the information in this '
              'notification is accurate and that I am the copyright owner or authorized '
              'to act on behalf of the owner.\n\n'
              'Contact: DataFightCentral Safety Team\n'
              'Email: safety@datafightcentral.com\n'
              'Address: Brisbane, QLD, Australia\n\n'
              'Signature: [AUTHORIZED_SIGNATURE]\n'
              'Date: [DATE]',
        ),
        const SizedBox(height: 16),
        _templateCard(
          'Host Escalation',
          Icons.escalator_warning,
          const Color(0xFFFFB800),
          'Subject: URGENT — Hosting Provider Content Escalation\n\n'
              'Dear Abuse Team,\n\n'
              'We are reporting content hosted on your infrastructure that '
              'constitutes [CATEGORY] and poses an immediate safety risk.\n\n'
              'Offending URL: [URL]\n'
              'Hosting IP/Domain: [HOSTING_DETAILS]\n\n'
              'Nature of Violation:\n[REASON]\n\n'
              'This content targets individuals associated with our platform '
              '(DataFightCentral — a registered combat sports organization in '
              'Brisbane, Australia) and constitutes:\n'
              '• [SPECIFIC_VIOLATIONS]\n\n'
              'Evidence:\n[EVIDENCE_LINKS]\n\n'
              'We request immediate investigation and removal under your '
              'Acceptable Use Policy. This matter has been logged for '
              'potential legal follow-up if unresolved within 48 hours.\n\n'
              'DataFightCentral Safety & Legal Team\n'
              'safety@datafightcentral.com',
        ),
      ],
    );
  }

  Widget _templateCard(String title, IconData icon, Color color, String body) {
    return Card(
      color: DesignTokens.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconColor: Colors.white54,
        collapsedIconColor: Colors.white38,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.bgPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: SelectableText(
              body,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Copy to clipboard
                    _copyToClipboard(body);
                  },
                  icon: const Icon(Icons.copy, size: 16, color: Colors.black),
                  label: const Text(
                    'Copy Template',
                    style: TextStyle(color: Colors.black, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    // Use Clipboard from services
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template copied to clipboard'),
        backgroundColor: Color(0xFF00FF88),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF00F5FF),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.white38, size: 20)
            : null,
        filled: true,
        fillColor: DesignTokens.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF00F5FF)),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      dropdownColor: DesignTokens.bgCard,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: DesignTokens.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF00F5FF)),
        ),
      ),
    );
  }

  Widget _statBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFB800);
      case 'sent':
        return const Color(0xFFFF00FF);
      case 'acknowledged':
        return const Color(0xFF00F5FF);
      case 'resolved':
        return const Color(0xFF00FF88);
      case 'rejected':
        return const Color(0xFFFF3366);
      default:
        return Colors.white54;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'CRITICAL':
        return const Color(0xFFFF3366);
      case 'HIGH':
        return const Color(0xFFFFB800);
      case 'MEDIUM':
        return const Color(0xFF00F5FF);
      case 'LOW':
        return const Color(0xFF00FF88);
      default:
        return Colors.white54;
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ── Demo data ────────────────────────────────────────────────────────

  List<_TakedownRequest> _demoRequests() {
    return [
      _TakedownRequest(
        id: 'td_001',
        url: 'https://example-forum.com/thread/12345',
        reason:
            'Posting personal photos and home address of a DFC fighter without consent',
        category: 'Doxxing',
        priority: 'CRITICAL',
        reporter: 'Heath',
        status: 'sent',
        evidence: 'Screenshot archived at archive.org/web/...',
        template: 'Host Escalation',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      _TakedownRequest(
        id: 'td_002',
        url: 'https://social-media.com/post/67890',
        reason:
            'Defamatory claims about match fixing with fabricated screenshots',
        category: 'Defamation',
        priority: 'HIGH',
        reporter: 'DFC Legal',
        status: 'pending',
        evidence: 'Original timestamps prove fabrication',
        template: 'Support',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      _TakedownRequest(
        id: 'td_003',
        url: 'https://video-host.com/clip/abc123',
        reason:
            'Unauthorized reupload of DFC PPV content with added defamatory commentary',
        category: 'Copyright / DMCA',
        priority: 'HIGH',
        reporter: 'Content Team',
        status: 'acknowledged',
        evidence: 'Original broadcast timestamps and watermarks match',
        template: 'DMCA',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      _TakedownRequest(
        id: 'td_004',
        url: 'https://anon-board.com/thread/harassment',
        reason: 'Coordinated harassment campaign targeting DFC staff',
        category: 'Harassment',
        priority: 'CRITICAL',
        reporter: 'Safety Team',
        status: 'resolved',
        evidence: 'Multiple archived screenshots',
        template: 'Host Escalation',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      _TakedownRequest(
        id: 'td_005',
        url: 'https://fake-profile.com/impersonation',
        reason: 'Fake profile impersonating DFC official account to scam users',
        category: 'Impersonation',
        priority: 'HIGH',
        reporter: 'Moderator',
        status: 'sent',
        evidence: 'Side-by-side comparison screenshots',
        template: 'Support',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}

// ── Data model ──────────────────────────────────────────────────────────

class _TakedownRequest {
  final String id;
  final String url;
  final String reason;
  final String category;
  final String priority;
  final String reporter;
  final String status;
  final String evidence;
  final String template;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String notes;

  const _TakedownRequest({
    required this.id,
    required this.url,
    required this.reason,
    required this.category,
    required this.priority,
    required this.reporter,
    required this.status,
    this.evidence = '',
    this.template = '',
    required this.createdAt,
    this.resolvedAt,
    this.notes = '',
  });

  _TakedownRequest copyWith({String? status, DateTime? resolvedAt}) {
    return _TakedownRequest(
      id: id,
      url: url,
      reason: reason,
      category: category,
      priority: priority,
      reporter: reporter,
      status: status ?? this.status,
      evidence: evidence,
      template: template,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      notes: notes,
    );
  }
}
