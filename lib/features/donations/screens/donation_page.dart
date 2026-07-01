import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/stripe_config.dart';
import '../../../shared/services/paypal_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  String _selectedCause = 'Buy a Coffee, Not a Coffin';
  final _causes = [
    'Buy a Coffee, Not a Coffin',
    'Protect Children',
    'End Domestic Violence',
    'Fight Poverty',
    'Support Education',
    'Mental Health & Suicide Prevention',
    'Help Survivors',
  ];
  final _controller = TextEditingController();
  bool _recurring = false;

  bool get _isCoffeeProgram => _selectedCause == 'Buy a Coffee, Not a Coffin';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Donate to End Pain',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Buy a Coffee, Not a Coffin Banner ──
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/logos/buy_a_coffee_not_a_coffin.png',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.brown.withAlpha(80),
                      Colors.green.withAlpha(50),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'BUY A COFFEE,\nNOT A COFFIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.brown.withAlpha(60),
                  Colors.green.withAlpha(30),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withAlpha(40)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUY A COFFEE, NOT A COFFIN',
                  style: TextStyle(
                    color: Colors.brown,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Every donation can become a real coffee for someone hurting. '
                  'Your support brings hope, not just help. When you donate, a QR '
                  'code for a 24hr coffee is sent to someone in need \u2014 powered '
                  'by DFC, supporting Nitechill and real people.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Inspirational Banner ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.withAlpha(40), Colors.green.withAlpha(30)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withAlpha(40)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STOP THE PAIN. BUILD HOPE.',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your donation helps prevent family destruction, violence, '
                  'poverty, and suffering. Every dollar brings hope, education, '
                  'and safety to those who need it most.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Cause Selection ──
          const Text(
            'Choose a Cause',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _causes
                .map(
                  (c) => ChoiceChip(
                    label: Text(
                      c,
                      style: TextStyle(
                        color: _selectedCause == c
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    selected: _selectedCause == c,
                    selectedColor: c == 'Buy a Coffee, Not a Coffin'
                        ? Colors.brown.withAlpha(100)
                        : Colors.green.withAlpha(80),
                    backgroundColor: Colors.white12,
                    onSelected: (_) => setState(() => _selectedCause = c),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),

          // ── How it works: Direct to Org vs Coffee Program ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isCoffeeProgram
                ? _buildCoffeeProgramInfo()
                : _buildDirectOrgInfo(),
          ),

          const SizedBox(height: 24),

          // ── Donation Amount ──
          const Text(
            'Donation Amount',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter amount (e.g. 20)',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _recurring,
                onChanged: (v) => setState(() => _recurring = v ?? false),
                activeColor: Colors.green,
              ),
              const Text(
                'Make this a monthly donation',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Bank Transfer Card (Coffee Program only) ──
          if (_isCoffeeProgram) ...[
            _buildBankTransferCard(),
            const SizedBox(height: 20),
          ],

          // ── Donate Button ──
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCoffeeProgram ? Colors.brown : Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (_isCoffeeProgram) {
                _showCoffeeThankYou();
              } else {
                _showOrgDonationInfo();
              }
            },
            child: Text(
              _isCoffeeProgram
                  ? 'Donate via Bank Transfer'
                  : 'Donate Directly to Organisation',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Stripe Card Payment Button ──
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF635BFF), // Stripe purple
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.credit_card, color: Colors.white),
            label: const Text(
              'Pay with Card via Stripe',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              final amount =
                  int.tryParse(
                    _controller.text.replaceAll(RegExp(r'[^0-9]'), ''),
                  ) ??
                  10;
              final link = DfcStripeLinks.donationLink(amount);
              final messenger = ScaffoldMessenger.of(context);
              final opened = await DfcStripeLinks.openPaymentLink(link);
              if (!opened && mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Could not open Stripe checkout.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),

          // ── PayPal Donation Button ──
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0070BA),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
            label: const Text(
              'Donate with PayPal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              final amount =
                  int.tryParse(
                    _controller.text.replaceAll(RegExp(r'[^0-9]'), ''),
                  ) ??
                  10;
              final userId =
                  FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
              final paypal = PayPalService();
              final messenger = ScaffoldMessenger.of(context);
              final orderId = await paypal.createOrder(
                userId: userId,
                amountCents: amount * 100,
                currency: 'AUD',
                productType: 'donation',
                productName: _selectedCause,
              );
              if (orderId == null && mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      paypal.error ?? 'Could not open PayPal checkout.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 30),

          // ── Impact Stats ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withAlpha(30)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Impact',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '\u2022 1,200+ families supported',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  '\u2022 800+ children protected',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  '\u2022 2,000+ people educated',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  '\u2022 1,500+ survivors given hope',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Support DFC Footer ──
          const SupportDfcFooter(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Coffee Program info panel
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCoffeeProgramInfo() {
    return Container(
      key: const ValueKey('coffee'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.brown.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.withAlpha(60)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW IT WORKS',
            style: TextStyle(
              color: Colors.brown,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'The "Buy a Coffee, Not a Coffin" program is run directly by DFC. '
            'Your donation is used to purchase real coffees (QR vouchers) for '
            'people doing it tough. We are partnering with cafes and fast food '
            'chains for real-world redemption.\n\n'
            'Donations for this program go to the DFC account below.',
            style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Direct-to-organisation info panel
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDirectOrgInfo() {
    return Container(
      key: const ValueKey('org'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DIRECT TO ORGANISATION',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Donations for "$_selectedCause" go directly to the partner '
            'organisation. No double-handling, no extra paperwork \u2014 100% '
            'of your donation reaches the cause.',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.verified, color: Colors.green, size: 16),
              SizedBox(width: 6),
              Text(
                'Verified partner organisations',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bank Transfer card (Coffee Program)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBankTransferCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.withAlpha(40), const Color(0xFF0A0E1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.brown.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance, color: Colors.brown, size: 20),
              SizedBox(width: 8),
              Text(
                'BANK TRANSFER',
                style: TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _bankRow('Account Name', 'DFC Pty Ltd'),
          _bankRow('BSB', '032-586'),
          _bankRow('Account', '596038'),
          _bankRow('Bank', 'Westpac'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white38, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use your name or "DFC Coffee" as the payment reference. '
                    'Business account (Pty Ltd) coming soon.',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(
                  const ClipboardData(
                    text:
                        'BSB: 032-586\nAccount: 596038\nName: DFC Pty Ltd\nBank: Westpac',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bank details copied!'),
                    backgroundColor: Colors.brown,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 14, color: Colors.brown),
              label: const Text(
                'Copy Details',
                style: TextStyle(color: Colors.brown, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Thank-you dialog for Coffee Program
  // ─────────────────────────────────────────────────────────────────────────
  void _showCoffeeThankYou() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('Thank You!', style: TextStyle(color: Colors.brown)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You just helped bring someone hurting a coffee.\n\n'
              'Transfer the amount to:\n'
              'BSB: 032-586  |  Acc: 596038\n'
              'Name: DFC Pty Ltd (Westpac)\n'
              'Ref: DFC Coffee',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.qr_code, color: Colors.white54, size: 60),
                  SizedBox(height: 6),
                  Text(
                    '24hr Coffee QR — partnering with cafes now',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'A QR code for a free coffee will be sent to someone in need. '
              'We are partnering with cafes and fast food chains for '
              'real-world redemption.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Info dialog for direct-to-organisation donations
  // ─────────────────────────────────────────────────────────────────────────
  void _showOrgDonationInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text(
          'Direct to Organisation',
          style: TextStyle(color: Colors.green),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your donation to "$_selectedCause" will be directed straight '
              'to the partner organisation. No double-handling, no middleman.'
              '\n\nYour donation will go directly to the partner organisation. '
              'Use the Stripe or PayPal buttons above for instant processing, '
              "or transfer via bank details below.",
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text(
                  '100% goes to the cause',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUPPORT DFC FOOTER — Reusable "Support Us" widget with bank details
// ═══════════════════════════════════════════════════════════════════════════════
class SupportDfcFooter extends StatelessWidget {
  const SupportDfcFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.withAlpha(20), Colors.green.withAlpha(15)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        children: [
          const Text(
            'SUPPORT DATA FIGHT CENTRAL',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Help us keep the platform free and support fighters, families, '
            'and communities worldwide.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 10, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _footerDetail('BSB', '032-586'),
              const SizedBox(width: 20),
              _footerDetail('ACC', '596038'),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'DFC Pty Ltd \u2022 Westpac',
            style: TextStyle(color: Colors.white30, fontSize: 10),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ref: "DFC Support"',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _footerDetail(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white30, fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
