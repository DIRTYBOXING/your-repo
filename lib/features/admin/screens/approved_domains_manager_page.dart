import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/meta_content_service.dart';

/// Admin-only screen to view and modify the partner amplification domain
/// whitelist at runtime without requiring a code deploy.
///
/// Changes are in-memory for the current session. The list is seeded from
/// [MetaContentService.approvedDomains] which is the single source of truth.
class ApprovedDomainsManagerPage extends StatefulWidget {
  const ApprovedDomainsManagerPage({super.key});

  @override
  State<ApprovedDomainsManagerPage> createState() =>
      _ApprovedDomainsManagerPageState();
}

class _ApprovedDomainsManagerPageState
    extends State<ApprovedDomainsManagerPage> {
  final TextEditingController _addCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  void _addDomain() {
    if (!_formKey.currentState!.validate()) return;

    final raw = _addCtrl.text.trim().toLowerCase();
    // Strip scheme if accidentally pasted
    final host = raw
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/.*$'), '');

    if (host.isEmpty) return;

    setState(() {
      MetaContentService.approvedDomains.add(host);
      // Also add www. variant automatically
      if (!host.startsWith('www.')) {
        MetaContentService.approvedDomains.add('www.$host');
      }
    });

    _addCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$host added to approved domains'),
        backgroundColor: Colors.green[800],
      ),
    );
  }

  void _removeDomain(String domain) {
    setState(() {
      MetaContentService.approvedDomains.remove(domain);
      // Remove www. variant too if it exists
      if (!domain.startsWith('www.')) {
        MetaContentService.approvedDomains.remove('www.$domain');
      } else {
        MetaContentService.approvedDomains.remove(
          domain.replaceFirst('www.', ''),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedDomains = MetaContentService.approvedDomains.toList()..sort();

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('APPROVED DOMAINS'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: AppTheme.neonCyan,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PARTNER AMPLIFICATION WHITELIST',
                  style: TextStyle(
                    color: AppTheme.neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Only posts sourced from these domains will be mirrored as DFC amplification posts. Changes apply immediately to the current session.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Add domain form
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. instagram.com',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: AppTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.neonCyan.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.neonCyan.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.neonCyan,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter a domain';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _addDomain(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addDomain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'ADD',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Domain count badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${sortedDomains.length} APPROVED DOMAINS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Domain list
          Expanded(
            child: sortedDomains.isEmpty
                ? Center(
                    child: Text(
                      'No domains approved.\nAdd one above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sortedDomains.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withValues(alpha: 0.07),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final domain = sortedDomains[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: const Icon(
                          Icons.link,
                          color: AppTheme.neonCyan,
                          size: 18,
                        ),
                        title: Text(
                          domain,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: AppTheme.errorColor.withValues(alpha: 0.8),
                            size: 20,
                          ),
                          onPressed: () => _showRemoveDialog(domain),
                          tooltip: 'Remove domain',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(String domain) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Remove Domain?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "$domain" from the approved list? DFC will no longer amplify posts from this source.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _removeDomain(domain);
            },
            child: const Text('REMOVE', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
