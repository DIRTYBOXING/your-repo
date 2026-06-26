import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC INVOICE GENERATION SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Generates invoices for all DFC financial transactions:
///   • PPV purchases — buyer receipt + promoter settlement statement
///   • Subscription billing — monthly/annual invoice
///   • Marketplace orders — buyer receipt + seller remittance
///   • Ticket purchases — buyer receipt with event details
///   • Creator payouts — settlement statement with tax withholding
///
/// Invoice Format:
///   Stored as structured Firestore documents. Can be rendered to HTML/PDF
///   via Cloud Functions when download is requested.
///
/// Firestore Collections:
///   invoices/{invoiceId}                — Invoice records
///   invoice_templates/{templateType}    — Template configuration
///
/// Numbering: DFC-{YYYY}-{SEQ:7} (e.g., DFC-2026-0001234)
///
/// ═══════════════════════════════════════════════════════════════════════════
class InvoiceGenerationService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isGenerating = false;
  String? _error;

  bool get isGenerating => _isGenerating;
  String? get error => _error;

  // ── Tax Rates by Region ──
  static const Map<String, TaxConfig> taxRates = {
    'AU': TaxConfig(name: 'GST', rate: 0.10, id: 'ABN'),
    'NZ': TaxConfig(name: 'GST', rate: 0.15, id: 'NZBN'),
    'GB': TaxConfig(name: 'VAT', rate: 0.20, id: 'VAT'),
    'DE': TaxConfig(name: 'MwSt', rate: 0.19, id: 'USt-IdNr'),
    'FR': TaxConfig(name: 'TVA', rate: 0.20, id: 'TVA'),
    'IE': TaxConfig(name: 'VAT', rate: 0.23, id: 'VAT'),
    'NL': TaxConfig(name: 'BTW', rate: 0.21, id: 'BTW'),
    'BE': TaxConfig(name: 'BTW', rate: 0.21, id: 'BTW'),
    'SG': TaxConfig(name: 'GST', rate: 0.09, id: 'UEN'),
    'JP': TaxConfig(name: 'CT', rate: 0.10, id: 'TIN'),
    'TH': TaxConfig(name: 'VAT', rate: 0.07, id: 'TIN'),
    'CA': TaxConfig(name: 'GST', rate: 0.05, id: 'BN'),
    'IN': TaxConfig(name: 'GST', rate: 0.18, id: 'GSTIN'),
    'ZA': TaxConfig(name: 'VAT', rate: 0.15, id: 'VAT'),
    'BR': TaxConfig(name: 'ICMS', rate: 0.17, id: 'CNPJ'),
    'MX': TaxConfig(name: 'IVA', rate: 0.16, id: 'RFC'),
    'PH': TaxConfig(name: 'VAT', rate: 0.12, id: 'TIN'),
    'NG': TaxConfig(name: 'VAT', rate: 0.075, id: 'TIN'),
  };

  // DFC Platform Info for Invoices
  static const Map<String, String> dfcBusinessInfo = {
    'name': 'DataFightCentral Pty Ltd',
    'abn': '00 000 000 000', // Replace with actual ABN
    'address': 'Melbourne, Victoria, Australia',
    'email': 'billing@datafightcentral.com',
    'website': 'https://datafightcentral.com',
  };

  // ═══════════════════════════════════════════════════════════════════════
  // INVOICE GENERATION
  // ═══════════════════════════════════════════════════════════════════════

  /// Generate invoice for a PPV purchase
  Future<Invoice?> generatePPVInvoice({
    required String userId,
    required String transactionId,
    required String eventName,
    required double amount,
    required String currency,
    required String buyerCountry,
    String? promoterName,
  }) async {
    return _generateInvoice(
      type: InvoiceType.ppvPurchase,
      userId: userId,
      transactionId: transactionId,
      description: 'PPV Access: $eventName',
      lineItems: [
        InvoiceLineItem(
          description: 'Pay-Per-View Event: $eventName',
          quantity: 1,
          unitPrice: amount,
          currency: currency,
        ),
      ],
      buyerCountry: buyerCountry,
      metadata: {'eventName': eventName, 'promoterName': promoterName ?? ''},
    );
  }

  /// Generate invoice for a subscription billing cycle
  Future<Invoice?> generateSubscriptionInvoice({
    required String userId,
    required String planName,
    required double amount,
    required String currency,
    required String buyerCountry,
    required String billingPeriod,
  }) async {
    return _generateInvoice(
      type: InvoiceType.subscription,
      userId: userId,
      transactionId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      description: 'DFC $planName Subscription',
      lineItems: [
        InvoiceLineItem(
          description: '$planName Plan — $billingPeriod',
          quantity: 1,
          unitPrice: amount,
          currency: currency,
        ),
      ],
      buyerCountry: buyerCountry,
    );
  }

  /// Generate invoice for a marketplace purchase
  Future<Invoice?> generateMarketplaceInvoice({
    required String userId,
    required String transactionId,
    required List<InvoiceLineItem> items,
    required String currency,
    required String buyerCountry,
    String? sellerName,
  }) async {
    return _generateInvoice(
      type: InvoiceType.marketplace,
      userId: userId,
      transactionId: transactionId,
      description: 'DFC Marketplace Order',
      lineItems: items,
      buyerCountry: buyerCountry,
      metadata: {'sellerName': sellerName ?? ''},
    );
  }

  /// Generate invoice for a ticket purchase
  Future<Invoice?> generateTicketInvoice({
    required String userId,
    required String transactionId,
    required String eventName,
    required String ticketType,
    required int quantity,
    required double unitPrice,
    required String currency,
    required String buyerCountry,
  }) async {
    return _generateInvoice(
      type: InvoiceType.ticket,
      userId: userId,
      transactionId: transactionId,
      description: 'Event Ticket: $eventName',
      lineItems: [
        InvoiceLineItem(
          description: '$eventName — $ticketType',
          quantity: quantity,
          unitPrice: unitPrice,
          currency: currency,
        ),
      ],
      buyerCountry: buyerCountry,
    );
  }

  /// Generate a payout settlement statement for a creator
  Future<Invoice?> generatePayoutStatement({
    required String creatorId,
    required String payoutId,
    required double grossEarnings,
    required double platformFee,
    required double taxWithholding,
    required double netPayout,
    required String currency,
    required String creatorCountry,
    required String periodFrom,
    required String periodTo,
  }) async {
    return _generateInvoice(
      type: InvoiceType.payoutStatement,
      userId: creatorId,
      transactionId: payoutId,
      description: 'Payout Statement: $periodFrom to $periodTo',
      lineItems: [
        InvoiceLineItem(
          description: 'Gross Earnings',
          quantity: 1,
          unitPrice: grossEarnings,
          currency: currency,
        ),
        InvoiceLineItem(
          description: 'Platform Fee',
          quantity: 1,
          unitPrice: -platformFee,
          currency: currency,
        ),
        if (taxWithholding > 0)
          InvoiceLineItem(
            description: 'Tax Withholding',
            quantity: 1,
            unitPrice: -taxWithholding,
            currency: currency,
          ),
      ],
      buyerCountry: creatorCountry,
      metadata: {
        'periodFrom': periodFrom,
        'periodTo': periodTo,
        'netPayout': netPayout,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INVOICE RETRIEVAL
  // ═══════════════════════════════════════════════════════════════════════

  /// Get all invoices for a user
  Future<List<Invoice>> getUserInvoices(String userId, {int limit = 50}) async {
    try {
      final snap = await _firestore
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map(Invoice.fromFirestore).toList();
    } catch (e) {
      debugPrint('getUserInvoices error: $e');
      return [];
    }
  }

  /// Get a single invoice by ID
  Future<Invoice?> getInvoice(String invoiceId) async {
    try {
      final doc = await _firestore.collection('invoices').doc(invoiceId).get();
      if (!doc.exists) return null;
      return Invoice.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INTERNAL
  // ═══════════════════════════════════════════════════════════════════════

  Future<Invoice?> _generateInvoice({
    required InvoiceType type,
    required String userId,
    required String transactionId,
    required String description,
    required List<InvoiceLineItem> lineItems,
    required String buyerCountry,
    Map<String, dynamic>? metadata,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      // Calculate totals
      double subtotal = 0;
      for (final item in lineItems) {
        subtotal += item.unitPrice * item.quantity;
      }

      // Calculate tax
      final tax = taxRates[buyerCountry.toUpperCase()];
      final taxAmount = (tax != null && subtotal > 0)
          ? subtotal * tax.rate
          : 0.0;
      final total = subtotal + taxAmount;

      // Generate invoice number
      final invoiceNumber = await _nextInvoiceNumber();

      final ref = _firestore.collection('invoices').doc();
      final now = DateTime.now();

      final invoice = Invoice(
        invoiceId: ref.id,
        invoiceNumber: invoiceNumber,
        type: type,
        userId: userId,
        transactionId: transactionId,
        description: description,
        lineItems: lineItems,
        subtotal: subtotal,
        taxName: tax?.name,
        taxRate: tax?.rate ?? 0,
        taxAmount: taxAmount,
        total: total,
        currency: lineItems.isNotEmpty ? lineItems.first.currency : 'AUD',
        buyerCountry: buyerCountry,
        status: InvoiceStatus.issued,
        createdAt: now,
        metadata: metadata,
      );

      await ref.set({
        'invoiceId': ref.id,
        'invoiceNumber': invoiceNumber,
        'type': type.name,
        'userId': userId,
        'transactionId': transactionId,
        'description': description,
        'lineItems': lineItems
            .map(
              (i) => {
                'description': i.description,
                'quantity': i.quantity,
                'unitPrice': i.unitPrice,
                'currency': i.currency,
              },
            )
            .toList(),
        'subtotal': subtotal,
        'taxName': tax?.name,
        'taxRate': tax?.rate ?? 0,
        'taxAmount': taxAmount,
        'total': total,
        'currency': lineItems.isNotEmpty ? lineItems.first.currency : 'AUD',
        'buyerCountry': buyerCountry,
        'status': 'issued',
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': metadata,
      });

      return invoice;
    } catch (e) {
      _error = 'Invoice generation failed: $e';
      debugPrint('InvoiceGenerationService._generateInvoice error: $e');
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<String> _nextInvoiceNumber() async {
    try {
      final year = DateTime.now().year;
      final counterRef = _firestore
          .collection('counters')
          .doc('invoices_$year');

      final result = await _firestore.runTransaction((txn) async {
        final snap = await txn.get(counterRef);
        final current = snap.exists ? (snap.data()?['seq'] as int? ?? 0) : 0;
        final next = current + 1;
        txn.set(counterRef, {'seq': next});
        return next;
      });

      return 'DFC-$year-${result.toString().padLeft(7, '0')}';
    } catch (e) {
      // Fallback: timestamp-based
      return 'DFC-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum InvoiceType {
  ppvPurchase,
  subscription,
  marketplace,
  ticket,
  donation,
  payoutStatement,
}

enum InvoiceStatus { draft, issued, paid, voided, refunded }

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class TaxConfig {
  final String name;
  final double rate;
  final String id;

  const TaxConfig({required this.name, required this.rate, required this.id});
}

class InvoiceLineItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final String currency;

  const InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.currency = 'AUD',
  });

  double get lineTotal => unitPrice * quantity;
}

class Invoice {
  final String invoiceId;
  final String invoiceNumber;
  final InvoiceType type;
  final String userId;
  final String transactionId;
  final String description;
  final List<InvoiceLineItem> lineItems;
  final double subtotal;
  final String? taxName;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String currency;
  final String buyerCountry;
  final InvoiceStatus status;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const Invoice({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.type,
    required this.userId,
    required this.transactionId,
    required this.description,
    required this.lineItems,
    required this.subtotal,
    this.taxName,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.currency,
    required this.buyerCountry,
    required this.status,
    required this.createdAt,
    this.metadata,
  });

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final items = (data['lineItems'] as List? ?? [])
        .map(
          (i) => InvoiceLineItem(
            description: i['description'] as String? ?? '',
            quantity: i['quantity'] as int? ?? 1,
            unitPrice: (i['unitPrice'] as num?)?.toDouble() ?? 0,
            currency: i['currency'] as String? ?? 'AUD',
          ),
        )
        .toList();

    return Invoice(
      invoiceId: doc.id,
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      type: InvoiceType.values.firstWhere(
        (t) => t.name == (data['type'] as String? ?? ''),
        orElse: () => InvoiceType.ppvPurchase,
      ),
      userId: data['userId'] as String? ?? '',
      transactionId: data['transactionId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      lineItems: items,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      taxName: data['taxName'] as String?,
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0,
      taxAmount: (data['taxAmount'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'AUD',
      buyerCountry: data['buyerCountry'] as String? ?? '',
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? ''),
        orElse: () => InvoiceStatus.issued,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }
}
