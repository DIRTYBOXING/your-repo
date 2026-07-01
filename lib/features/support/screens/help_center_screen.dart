import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/support_ticket_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HELP CENTER — Professional Support & Contact Hub
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Facebook-style Help & Support system:
///  - Submit support tickets (Firestore-backed)
///  - View ticket history + admin replies
///  - FAQ quick answers
///  - Contact admin (email, in-app)
///  - Report a problem (streamlined flow)
///  - Platform links (website, socials, legal)
/// ═══════════════════════════════════════════════════════════════════════════

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _service = SupportTicketService();
  final _user = FirebaseAuth.instance.currentUser;
  int _selectedTab = 0; // 0=FAQ, 1=My Tickets, 2=New Ticket, 3=Contact

  void _goBackSafely() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _goBackSafely,
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['FAQ', 'My Tickets', 'New Ticket', 'Contact'];
    final icons = [
      Icons.help_outline,
      Icons.inbox,
      Icons.add_circle_outline,
      Icons.mail_outline,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DesignTokens.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[i],
                      size: 18,
                      color: isActive
                          ? DesignTokens.neonCyan
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tabs[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? DesignTokens.neonCyan
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case 0:
        return _buildFAQ();
      case 1:
        return _buildMyTickets();
      case 2:
        return _buildNewTicket();
      case 3:
        return _buildContact();
      default:
        return _buildFAQ();
    }
  }

  // ── FAQ ──────────────────────────────────────────────────────────────

  Widget _buildFAQ() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _faqCard(
          'How do I change my password?',
          'Go to Settings → Account → Change Password. You can also reset it via email from the login screen.',
          Icons.lock_outline,
        ),
        _faqCard(
          'How do I verify my identity?',
          'Go to Settings → Account → Identity Verification and follow the verification process to get a verified badge.',
          Icons.verified,
        ),
        _faqCard(
          'How does the safety system work?',
          'Our Guardian safety system (Wellness → Cycle & Hormone Hub) includes a hidden silent alert. Long-press the check-in button to send an SOS to your guardian contacts without anyone knowing.',
          Icons.shield,
        ),
        _faqCard(
          'How do I report inappropriate content?',
          'Tap the three-dot menu on any post or profile and select "Report". Our AI moderation system + human review will handle it within 24 hours.',
          Icons.flag_outlined,
        ),
        _faqCard(
          'How do I manage my membership?',
          'Go to Settings → Account → Membership. Choose between Free, Gold, or Diamond tiers for additional features.',
          Icons.workspace_premium,
        ),
        _faqCard(
          'Where is the FightWire news feed?',
          'The FightWire icon is on the bottom navigation bar. It shows real-time fight news, YouTube highlights, and event updates from over 35 global combat sports sources.',
          Icons.newspaper,
        ),
        _faqCard(
          'How do I find local events or gyms?',
          'Use the Discovery screen or the Fight Event & Gym Finder to locate training facilities and upcoming events near you.',
          Icons.location_on,
        ),
        _faqCard(
          'How do I contact an admin?',
          'Use the "Contact" tab above to email admin directly, or submit a support ticket for tracked resolution.',
          Icons.support_agent,
        ),
      ],
    );
  }

  Widget _faqCard(String question, String answer, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
      ),
      child: ExpansionTile(
        collapsedIconColor: Colors.white.withValues(alpha: 0.4),
        iconColor: DesignTokens.neonCyan,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(icon, color: DesignTokens.neonCyan, size: 22),
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── My Tickets ──────────────────────────────────────────────────────

  Widget _buildMyTickets() {
    if (_user == null) {
      return _centeredMessage('Sign in to view your support tickets');
    }

    return StreamBuilder<List<SupportTicket>>(
      stream: _service.myTickets(_user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.neonCyan),
          );
        }

        final tickets = snapshot.data ?? [];
        if (tickets.isEmpty) {
          return _centeredMessage(
            'No support tickets yet.\nSubmit one from the "New Ticket" tab.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, i) => _ticketCard(tickets[i]),
        );
      },
    );
  }

  Widget _ticketCard(SupportTicket ticket) {
    final statusColor = _statusColor(ticket.status);

    return GestureDetector(
      onTap: () => _showTicketDetail(ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.categoryLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                if (ticket.replies.isNotEmpty)
                  Icon(
                    Icons.chat_bubble,
                    size: 14,
                    color: DesignTokens.neonGreen.withValues(alpha: 0.7),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ticket.subject,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(ticket.createdAt),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketDetail(SupportTicket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ticket.subject,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statusBadge(ticket.status),
                      const SizedBox(width: 8),
                      Text(
                        ticket.categoryLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ticket.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (ticket.replies.isNotEmpty) ...[
                    Text(
                      'REPLIES',
                      style: TextStyle(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...ticket.replies.map(_replyCard),
                  ],
                  const SizedBox(height: 16),
                  _buildReplyInput(ticket.id),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _replyCard(TicketReply reply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: reply.isAdmin
            ? DesignTokens.neonGold.withValues(alpha: 0.08)
            : DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: reply.isAdmin
              ? DesignTokens.neonGold.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                reply.isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 14,
                color: reply.isAdmin
                    ? DesignTokens.neonGold
                    : DesignTokens.neonCyan,
              ),
              const SizedBox(width: 6),
              Text(
                reply.isAdmin ? 'Admin' : reply.authorName,
                style: TextStyle(
                  color: reply.isAdmin
                      ? DesignTokens.neonGold
                      : Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(reply.timestamp),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reply.message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  final _replyController = TextEditingController();

  Widget _buildReplyInput(String ticketId) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _replyController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Add a reply...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: DesignTokens.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final msg = _replyController.text.trim();
            if (msg.isEmpty || _user == null) return;
            await _service.addReply(
              ticketId: ticketId,
              authorId: _user.uid,
              authorName: _user.displayName ?? 'Member',
              message: msg,
            );
            _replyController.clear();
            if (mounted) Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.send,
              color: DesignTokens.neonCyan,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ── New Ticket ──────────────────────────────────────────────────────

  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  TicketCategory _selectedCategory = TicketCategory.other;
  TicketPriority _selectedPriority = TicketPriority.normal;
  bool _submitting = false;

  Widget _buildNewTicket() {
    if (_user == null) {
      return _centeredMessage('Sign in to submit a support ticket');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Category
        _fieldLabel('Category'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TicketCategory>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: DesignTokens.bgCard,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: TicketCategory.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(_categoryLabel(c)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Priority
        _fieldLabel('Priority'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TicketPriority>(
              value: _selectedPriority,
              isExpanded: true,
              dropdownColor: DesignTokens.bgCard,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: TicketPriority.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedPriority = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Subject
        _fieldLabel('Subject'),
        const SizedBox(height: 6),
        _inputField(_subjectController, 'Brief summary of your issue'),
        const SizedBox(height: 16),

        // Description
        _fieldLabel('Description'),
        const SizedBox(height: 6),
        _inputField(
          _descriptionController,
          'Describe your issue in detail...',
          maxLines: 6,
        ),
        const SizedBox(height: 24),

        // Submit
        GestureDetector(
          onTap: _submitting ? null : _submitTicket,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonCyan.withValues(alpha: 0.3),
                  DesignTokens.neonMagenta.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Ticket',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitTicket() async {
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    if (subject.isEmpty || description.isEmpty) {
      _showSnackBar('Please fill in subject and description', isError: true);
      return;
    }

    setState(() => _submitting = true);
    final ticketId = await _service.submitTicket(
      userId: _user!.uid,
      userEmail: _user.email ?? '',
      userName: _user.displayName ?? 'Member',
      subject: subject,
      description: description,
      category: _selectedCategory,
      priority: _selectedPriority,
    );
    setState(() => _submitting = false);

    if (ticketId != null) {
      _subjectController.clear();
      _descriptionController.clear();
      _showSnackBar('Ticket submitted! We\'ll get back to you soon.');
      setState(() => _selectedTab = 1); // Switch to My Tickets
    } else {
      _showSnackBar('Failed to submit. Please try again.', isError: true);
    }
  }

  // ── Contact ──────────────────────────────────────────────────────────

  Widget _buildContact() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Admin contact card
        _contactCard(
          icon: Icons.admin_panel_settings,
          title: 'Platform Admin',
          subtitle: 'Direct contact with DFC administration',
          color: DesignTokens.neonGold,
          children: [
            _contactRow(
              Icons.email,
              'Admin Email',
              SupportTicketService.adminEmail,
              () => _launchEmail(SupportTicketService.adminEmail),
            ),
            _contactRow(
              Icons.support_agent,
              'Support Email',
              SupportTicketService.supportEmail,
              () => _launchEmail(SupportTicketService.supportEmail),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Platform links
        _contactCard(
          icon: Icons.public,
          title: 'Platform & Resources',
          subtitle: 'Website, documentation, and community',
          color: DesignTokens.neonCyan,
          children: [
            _contactRow(
              Icons.language,
              'Website',
              SupportTicketService.websiteUrl,
              () => _launchUrl(SupportTicketService.websiteUrl),
            ),
            _contactRow(
              Icons.help,
              'Help Center',
              SupportTicketService.helpUrl,
              () => _launchUrl(SupportTicketService.helpUrl),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Social media channels
        _contactCard(
          icon: Icons.share,
          title: 'Social Media',
          subtitle: 'Follow DFC across all platforms',
          color: DesignTokens.neonMagenta,
          children: [
            _contactRow(
              Icons.camera_alt,
              'Instagram',
              '@datafightcentral',
              () => _launchUrl('https://www.instagram.com/datafightcentral'),
            ),
            _contactRow(
              Icons.music_note,
              'TikTok',
              '@datafightcentral',
              () => _launchUrl('https://www.tiktok.com/@datafightcentral'),
            ),
            _contactRow(
              Icons.play_circle,
              'YouTube',
              'Data Fight Central',
              () => _launchUrl('https://www.youtube.com/@datafightcentral'),
            ),
            _contactRow(
              Icons.alternate_email,
              'X (Twitter)',
              '@datafightcentral',
              () => _launchUrl('https://x.com/datafightcentral'),
            ),
            _contactRow(
              Icons.facebook,
              'Facebook',
              'Data Fight Central',
              () => _launchUrl('https://www.facebook.com/datafightcentral'),
            ),
            _contactRow(
              Icons.group,
              'Discord',
              'DFC Community',
              () => _launchUrl('https://discord.gg/datafightcentral'),
            ),
            _contactRow(
              Icons.tag,
              'Threads',
              '@datafightcentral',
              () => _launchUrl('https://www.threads.net/@datafightcentral'),
            ),
            _contactRow(
              Icons.work,
              'LinkedIn',
              'Data Fight Central',
              () => _launchUrl(
                'https://www.linkedin.com/company/datafightcentral',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Emergency / Safety
        _contactCard(
          icon: Icons.shield,
          title: 'Safety & Emergency',
          subtitle: 'Urgent safety concerns and DV support',
          color: DesignTokens.neonRed,
          children: [
            _contactRow(
              Icons.phone,
              '1800RESPECT (AU)',
              '1800 737 732',
              () => _launchPhone('1800737732'),
            ),
            _contactRow(
              Icons.phone,
              'Lifeline Australia',
              '13 11 14',
              () => _launchPhone('131114'),
            ),
            _contactRow(
              Icons.phone,
              'Need to Talk? (NZ)',
              '1737',
              () => _launchPhone('1737'),
            ),
            _contactRow(
              Icons.phone,
              'Women\'s Refuge (NZ)',
              '0800 733 843',
              () => _launchPhone('0800733843'),
            ),
            _contactRow(
              Icons.phone,
              'Emergency AU',
              '000',
              () => _launchPhone('000'),
            ),
            _contactRow(
              Icons.phone,
              'Emergency NZ',
              '111',
              () => _launchPhone('111'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Quick links
        _contactCard(
          icon: Icons.article,
          title: 'Legal & Policies',
          subtitle: 'Terms, privacy, and community guidelines',
          color: Colors.white.withValues(alpha: 0.5),
          children: [
            _contactRow(
              Icons.description,
              'Terms of Service',
              'datafightcentral.com/terms',
              () => _launchUrl('https://datafightcentral.com/#/terms'),
            ),
            _contactRow(
              Icons.privacy_tip,
              'Privacy Policy',
              'datafightcentral.com/privacy',
              () => _launchUrl('https://datafightcentral.com/#/privacy'),
            ),
            _contactRow(
              Icons.people,
              'Community Guidelines',
              'datafightcentral.com/community',
              () => _launchUrl(
                'https://datafightcentral.com/#/community-guidelines',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
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
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          ...children,
        ],
      ),
    );
  }

  Widget _contactRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.open_in_new,
              size: 14,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _statusBadge(TicketStatus status) {
    final color = _statusColor(status);
    final label = status == TicketStatus.open
        ? 'Open'
        : status == TicketStatus.inProgress
        ? 'In Progress'
        : status == TicketStatus.resolved
        ? 'Resolved'
        : 'Closed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return DesignTokens.neonCyan;
      case TicketStatus.inProgress:
        return DesignTokens.neonAmber;
      case TicketStatus.resolved:
        return DesignTokens.neonGreen;
      case TicketStatus.closed:
        return Colors.white.withValues(alpha: 0.4);
    }
  }

  String _categoryLabel(TicketCategory cat) {
    const labels = {
      TicketCategory.account: 'Account & Login',
      TicketCategory.billing: 'Billing & Subscription',
      TicketCategory.safety: 'Safety & Moderation',
      TicketCategory.bug: 'Bug Report',
      TicketCategory.featureRequest: 'Feature Request',
      TicketCategory.content: 'Content Issue',
      TicketCategory.technical: 'Technical Support',
      TicketCategory.other: 'Other',
    };
    return labels[cat] ?? 'Other';
  }

  Widget _fieldLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: DesignTokens.neonCyan.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: DesignTokens.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DesignTokens.neonCyan),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _centeredMessage(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? DesignTokens.neonRed
            : DesignTokens.neonGreen,
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _replyController.dispose();
    super.dispose();
  }
}
