import 'package:flutter/material.dart';
import 'api_service.dart';
import 'contract_controller.dart';
import 'contract_repository.dart';
import 'contract_state.dart';

class ContractNegotiationScreen extends StatefulWidget {
  const ContractNegotiationScreen({super.key});

  @override
  State<ContractNegotiationScreen> createState() =>
      _ContractNegotiationScreenState();
}

class _ContractNegotiationScreenState extends State<ContractNegotiationScreen> {
  late final ContractController _controller;
  final _fighterCtrl = TextEditingController();
  final _baseCtrl = TextEditingController();
  final _bonusCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ContractController(
      repo: ContractRepository(api: ApiService()),
    )..loadNegotiations();
  }

  @override
  void dispose() {
    _fighterCtrl.dispose();
    _baseCtrl.dispose();
    _bonusCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;
            if (state is ContractInitial || state is ContractLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.amberAccent),
              );
            }
            if (state is ContractError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }
            if (state is ContractLoaded) {
              return _buildContent(state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(ContractLoaded state) {
    final totalFmt = '\$${(state.budget.total / 1000000).toStringAsFixed(1)}M';
    final commFmt = '\$${(state.budget.committed / 1000).toStringAsFixed(0)}K';
    final remFmt = '\$${(state.budget.remaining / 1000).toStringAsFixed(0)}K';

    return RefreshIndicator(
      onRefresh: _controller.loadNegotiations,
      color: Colors.amberAccent,
      backgroundColor: const Color(0xFF0A0E17),
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
                  'CONTRACTS & NEGOTIATIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amberAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'MATCHMAKER',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ─── 2. ROSTER CAP & PAYROLL ─────────────────────────────────────
          _buildSectionHeader(
            Icons.account_balance_wallet,
            'PAYROLL & CAP STATUS',
            Colors.greenAccent,
          ),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'EVENT BUDGET',
                  totalFmt,
                  'DFC 2',
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'COMMITTED',
                  commFmt,
                  '${state.contracts.where((c) => c.status == 'SIGNED').length} Signed',
                  Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'REMAINING',
                  remFmt,
                  'Available',
                  Colors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── 3. ACTIVE NEGOTIATIONS ──────────────────────────────────────
          _buildSectionHeader(
            Icons.handshake,
            'ACTIVE NEGOTIATIONS',
            Colors.blueAccent,
          ),
          _DfcCard(
            height: 220,
            glow: true,
            child: Column(
              children: [
                ...state.contracts.map(
                  (contract) => Column(
                    children: [
                      _buildNegotiationRow(
                        fighter: contract.fighterName,
                        offer: contract.offer,
                        status: contract.status,
                        statusColor: Color(contract.statusColorHex),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: Colors.white10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 4. DRAFT NEW CONTRACT ───────────────────────────────────────
          _buildSectionHeader(
            Icons.draw,
            'DRAFT NEW CONTRACT',
            Colors.purpleAccent,
          ),
          _DfcCard(
            height: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECT ATHLETE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fighterCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Search Roster...',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const Icon(Icons.search, color: Colors.white54, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BASE PURSE',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInputField('\$', _baseCtrl),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WIN BONUS',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInputField('\$', _bonusCtrl),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (_fighterCtrl.text.isNotEmpty) {
                        _controller.sendOffer(
                          _fighterCtrl.text,
                          double.tryParse(_baseCtrl.text) ?? 0,
                          double.tryParse(_bonusCtrl.text) ?? 0,
                        );
                        _fighterCtrl.clear();
                        _baseCtrl.clear();
                        _bonusCtrl.clear();
                      }
                    },
                    child: const Text(
                      'GENERATE PDF & SEND TO MANAGER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
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

  Widget _buildMetricCard(
    String label,
    String value,
    String subValue,
    Color color,
  ) {
    return _DfcCard(
      height: 110,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationRow({
    required String fighter,
    required String offer,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fighter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              offer,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: TextInputType.number,
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        ),
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
                  color: Colors.blueAccent.withValues(alpha: 0.05),
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
