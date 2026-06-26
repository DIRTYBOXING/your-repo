import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SalesAdminScreen extends StatefulWidget {
  const SalesAdminScreen({super.key});

  @override
  State<SalesAdminScreen> createState() => _SalesAdminScreenState();
}

class _SalesAdminScreenState extends State<SalesAdminScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Map<String, dynamic> _settings = {};
  List<Map<String, dynamic>> _posterTemplates = const [];
  bool _loadingSettings = true;
  bool _loadingTemplates = true;

  // Bulk selection state for offer review tab
  final Set<String> _selectedOfferIds = {};
  bool _bulkProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadTemplateCatalog();
  }

  Future<void> _loadSettings() async {
    final doc = await _db.doc('admin/settings').get();
    if (!mounted) return;

    setState(() {
      _settings = doc.exists ? (doc.data() ?? {}) : {};
      _loadingSettings = false;
    });
  }

  Future<void> _loadTemplateCatalog() async {
    final raw = await rootBundle.loadString(
      'assets/poster_templates/templates.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    if (!mounted) return;

    setState(() {
      _posterTemplates = List<Map<String, dynamic>>.from(
        (decoded['templates'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>(),
      );
      _loadingTemplates = false;
    });
  }

  Future<void> _saveRate(String key, num value) async {
    await _db.doc('admin/settings').set({
      key: value,
      'salesUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _loadSettings();
  }

  Future<void> _reviewOffer({
    required String promotionId,
    required bool approved,
  }) async {
    await _db.collection('promotions').doc(promotionId).set({
      'requiresReview': false,
      'reviewStatus': approved ? 'approved' : 'rejected',
      'active': approved,
      'published': approved,
      'publishedAt': approved ? FieldValue.serverTimestamp() : null,
      'reviewedBy': 'sales_admin_console',
      'reviewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _bulkReviewOffers({required bool approved}) async {
    if (_selectedOfferIds.isEmpty || _bulkProcessing) return;
    setState(() => _bulkProcessing = true);
    try {
      final batch = _db.batch();
      for (final id in _selectedOfferIds) {
        batch.set(_db.collection('promotions').doc(id), {
          'requiresReview': false,
          'reviewStatus': approved ? 'approved' : 'rejected',
          'active': approved,
          'published': approved,
          'publishedAt': approved ? FieldValue.serverTimestamp() : null,
          'reviewedBy': 'sales_admin_console_bulk',
          'reviewedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
      setState(_selectedOfferIds.clear);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${approved ? 'Approved' : 'Rejected'} ${_selectedOfferIds.length} offers',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _bulkProcessing = false);
    }
  }

  Future<void> _reviewTemplate({
    required Map<String, dynamic> template,
    required bool approved,
  }) async {
    await _db
        .collection('creative_templates')
        .doc(template['id'].toString())
        .set({
          ...template,
          'reviewStatus': approved ? 'approved' : 'rejected',
          'requiresReview': false,
          'approved': approved,
          'published': approved,
          'publishedAt': approved ? FieldValue.serverTimestamp() : null,
          'reviewedBy': 'sales_admin_console',
          'reviewedAt': FieldValue.serverTimestamp(),
          'source': 'assets/poster_templates/templates.json',
        }, SetOptions(merge: true));
  }

  Future<void> _promptRateEdit({
    required String rateKey,
    String? tierName,
  }) async {
    final controller = TextEditingController(
      text: _settings[rateKey]?.toString() ?? '',
    );

    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set rate for ${tierName ?? rateKey}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: rateKey,
            hintText: 'Enter numeric rate',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (value == null || value.isEmpty) return;
    final parsed = num.tryParse(value);
    if (parsed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid number format')));
      return;
    }

    await _saveRate(rateKey, parsed);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Updated $rateKey')));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sales Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rates'),
              Tab(text: 'Offer Review'),
              Tab(text: 'Creative Review'),
            ],
          ),
        ),
        body: Semantics(
          label: 'data-test=sales-admin-screen',
          child: TabBarView(
            children: [
              _loadingSettings
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _db
                          .collection('config/contract_tiers/tiers')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data?.docs ?? const [];
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No contract tiers found. Run seed script first.',
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final data = docs[index].data();
                            final tierName =
                                (data['name'] ?? data['id'] ?? 'Tier')
                                    .toString();
                            final rateKey = (data['rate_key'] ?? '').toString();
                            final current = rateKey.isEmpty
                                ? null
                                : _settings[rateKey]?.toString();

                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.white12),
                              ),
                              title: Text(tierName),
                              subtitle: Text(
                                rateKey.isEmpty
                                    ? 'Missing rate_key in tier config'
                                    : 'rate_key: $rateKey\ncurrent: ${current ?? 'not set'}',
                              ),
                              isThreeLine: true,
                              trailing: rateKey.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _promptRateEdit(
                                        rateKey: rateKey,
                                        tierName: tierName,
                                      ),
                                    ),
                            );
                          },
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemCount: docs.length,
                        );
                      },
                    ),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _db
                    .collection('promotions')
                    .where('reviewStatus', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No pending AI offers. Generated offers will appear here.',
                      ),
                    );
                  }

                  final allSelected = _selectedOfferIds.length == docs.length;

                  return Column(
                    children: [
                      // ── Bulk action bar ──────────────────────────────
                      Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              tristate: true,
                              value: _selectedOfferIds.isEmpty
                                  ? false
                                  : allSelected
                                  ? true
                                  : null,
                              onChanged: (_) {
                                setState(() {
                                  if (allSelected) {
                                    _selectedOfferIds.clear();
                                  } else {
                                    _selectedOfferIds
                                      ..clear()
                                      ..addAll(docs.map((d) => d.id));
                                  }
                                });
                              },
                            ),
                            Text(
                              _selectedOfferIds.isEmpty
                                  ? 'Select all'
                                  : '${_selectedOfferIds.length} selected',
                            ),
                            const Spacer(),
                            if (_selectedOfferIds.isNotEmpty) ...[
                              _bulkProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        FilledButton(
                                          onPressed: () =>
                                              _bulkReviewOffers(approved: true),
                                          child: const Text('Approve All'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () => _bulkReviewOffers(
                                            approved: false,
                                          ),
                                          child: const Text('Reject All'),
                                        ),
                                      ],
                                    ),
                            ],
                          ],
                        ),
                      ),
                      // ── Offer list ───────────────────────────────────
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: docs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data();
                            final title =
                                (data['title'] ?? data['uiLabel'] ?? doc.id)
                                    .toString();
                            final priceCents = (data['priceCents'] ?? 0) as num;
                            final aiScore = (data['aiScore'] ?? 0).toString();
                            final predictedConversion =
                                (data['predictedConversion'] ?? 0).toString();
                            final isSelected = _selectedOfferIds.contains(
                              doc.id,
                            );

                            return Semantics(
                              label: 'data-test=offer-review-${doc.id}',
                              child: Card(
                                color: isSelected
                                    ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.3)
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (_) {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedOfferIds.remove(
                                                    doc.id,
                                                  );
                                                } else {
                                                  _selectedOfferIds.add(doc.id);
                                                }
                                              });
                                            },
                                          ),
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Type: ${data['type'] ?? 'unknown'}',
                                            ),
                                            Text(
                                              'Price: \$${(priceCents / 100).toStringAsFixed(2)}',
                                            ),
                                            Text(
                                              'AI score: $aiScore · Predicted conversion: $predictedConversion',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          FilledButton(
                                            onPressed: () => _reviewOffer(
                                              promotionId: doc.id,
                                              approved: true,
                                            ),
                                            child: const Text('Approve'),
                                          ),
                                          const SizedBox(width: 12),
                                          OutlinedButton(
                                            onPressed: () => _reviewOffer(
                                              promotionId: doc.id,
                                              approved: false,
                                            ),
                                            child: const Text('Reject'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              _loadingTemplates
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _posterTemplates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final template = _posterTemplates[index];
                        return Semantics(
                          label: 'data-test=poster-template-${template['id']}',
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template['name']?.toString() ??
                                        template['id'].toString(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    template['description']?.toString() ?? '',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Primary: ${template['primaryHex']} · Secondary: ${template['secondaryHex']}',
                                  ),
                                  Text(
                                    'Layouts: ${(template['responsiveLayouts'] as List<dynamic>? ?? const []).join(', ')}',
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      FilledButton(
                                        onPressed: () => _reviewTemplate(
                                          template: template,
                                          approved: true,
                                        ),
                                        child: const Text('Approve'),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton(
                                        onPressed: () => _reviewTemplate(
                                          template: template,
                                          approved: false,
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
