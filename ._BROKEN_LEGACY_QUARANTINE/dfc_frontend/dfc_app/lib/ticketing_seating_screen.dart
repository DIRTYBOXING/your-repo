import 'package:flutter/material.dart';
import 'dart:math' as math;

class TicketingSeatingScreen extends StatefulWidget {
  const TicketingSeatingScreen({super.key});

  @override
  State<TicketingSeatingScreen> createState() => _TicketingSeatingScreenState();
}

class _TicketingSeatingScreenState extends State<TicketingSeatingScreen> {
  String _selectedSection = 'VIP CAGESIDE';
  int _ticketCount = 2;
  double _pricePerTicket = 1500.00;

  void _selectSection(String name, double price) {
    setState(() {
      _selectedSection = name;
      _pricePerTicket = price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: [
            const SizedBox(height: 32),

            // ─── 1. HEADER ───────────────────────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'TICKETING & SEATING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    'DFC 2',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'MELBOURNE ARENA • SAT, OCT 14 • 7:00 PM',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),

            // ─── 2. ARENA MAP (STYLISED) ─────────────────────────────────────
            _buildSectionHeader(
              Icons.map,
              'INTERACTIVE ARENA MAP',
              Colors.cyanAccent,
            ),
            _DfcCard(
              height: 300,
              glow: true,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Bowl (Upper)
                  _buildRingSection(300, 200, Colors.white10),
                  // Inner Bowl (Lower)
                  _buildRingSection(
                    200,
                    120,
                    Colors.blueAccent.withValues(alpha: 0.2),
                  ),
                  // VIP Cageside
                  _buildRingSection(
                    120,
                    70,
                    Colors.amberAccent.withValues(alpha: 0.3),
                  ),

                  // The Octagon
                  Transform.rotate(
                    angle: math.pi / 8,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.redAccent, width: 2),
                        shape: BoxShape.rectangle,
                      ),
                    ),
                  ),
                  const Text(
                    'CAGE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),

                  // Indicators for the Map
                  Positioned(
                    top: 10,
                    child: _buildMapLabel('UPPER BOWL', Colors.white54),
                  ),
                  Positioned(
                    top: 50,
                    child: _buildMapLabel('LOWER BOWL', Colors.cyanAccent),
                  ),
                  Positioned(
                    bottom: 70,
                    child: _buildMapLabel('VIP CAGESIDE', Colors.amberAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── 3. SEATING ZONES & TICKETS ──────────────────────────────────
            _buildSectionHeader(
              Icons.event_seat,
              'AVAILABLE SECTIONS',
              Colors.purpleAccent,
            ),
            Column(
              children: [
                _buildTicketOption(
                  name: 'VIP CAGESIDE',
                  desc: 'Rows A-C • Exclusive Lounge Access',
                  price: 1500.00,
                  availability: 'Low',
                  color: Colors.amberAccent,
                ),
                const SizedBox(height: 12),
                _buildTicketOption(
                  name: 'LOWER BOWL - SEC 104',
                  desc: 'Premium Elevated View • Rows D-K',
                  price: 350.00,
                  availability: 'Medium',
                  color: Colors.cyanAccent,
                ),
                const SizedBox(height: 12),
                _buildTicketOption(
                  name: 'UPPER BOWL - SEC 208',
                  desc: 'Standard Seating • Rows L-Z',
                  price: 85.00,
                  availability: 'High',
                  color: Colors.white54,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ─── 4. CHECKOUT SUMMARY ─────────────────────────────────────────
            _DfcCard(
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedSection,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '\$${_pricePerTicket.toStringAsFixed(2)} ea',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(color: Colors.white10),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'QUANTITY',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Row(
                        children: [
                          _buildQuantityButton(Icons.remove, () {
                            if (_ticketCount > 1) {
                              setState(() => _ticketCount--);
                            }
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              '$_ticketCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildQuantityButton(Icons.add, () {
                            if (_ticketCount < 8) {
                              setState(() => _ticketCount++);
                            }
                          }),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: Text(
                        'CHECKOUT: \$${(_pricePerTicket * _ticketCount).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingSection(double outerSize, double innerSize, Color color) {
    return Container(
      width: outerSize,
      height: outerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: (outerSize - innerSize) / 2),
      ),
    );
  }

  Widget _buildMapLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTicketOption({
    required String name,
    required String desc,
    required double price,
    required String availability,
    required Color color,
  }) {
    final isSelected = _selectedSection == name;

    return GestureDetector(
      onTap: () => _selectSection(name, price),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFF0A0E17),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$availability Avail',
                  style: TextStyle(
                    color: availability == 'Low'
                        ? Colors.redAccent
                        : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _DfcCard extends StatelessWidget {
  final double height;
  final bool glow;
  final Widget child;

  const _DfcCard({
    required this.height,
    this.glow = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
