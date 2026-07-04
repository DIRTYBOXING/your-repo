import 'package:flutter/material.dart';
import '../../../shared/services/predictor_live_inputs_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SHAP EXPLANATION CARD
// Renders the top-K feature contributions from the LightGBM SHAP explainer.
// Bars animate on load and on each predictor recalculation.
// ═══════════════════════════════════════════════════════════════════════════════

class ShapExplanationCard extends StatefulWidget {
  final List<ShapFeature> features;
  final String nameA;
  final String nameB;
  final bool isLoading;

  const ShapExplanationCard({
    super.key,
    required this.features,
    this.nameA = 'Fighter A',
    this.nameB = 'Fighter B',
    this.isLoading = false,
  });

  @override
  State<ShapExplanationCard> createState() => _ShapExplanationCardState();
}

class _ShapExplanationCardState extends State<ShapExplanationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _barCtrl;
  late List<Animation<double>> _barAnims;

  static const _cyan = Color(0xFF00E5FF);
  static const _red = Color(0xFFFF1744);
  static const _purple = Color(0xFF9C6FFF);
  static const _bg = Color(0xFF0A1628);

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _buildBarAnims();
    _barCtrl.forward();
  }

  @override
  void didUpdateWidget(ShapExplanationCard old) {
    super.didUpdateWidget(old);
    if (old.features != widget.features) {
      _buildBarAnims();
      _barCtrl.forward(from: 0);
    }
  }

  void _buildBarAnims() {
    _barAnims = List.generate(
      widget.features.length,
      (i) => Tween<double>(begin: 0, end: widget.features[i].impact).animate(
        CurvedAnimation(
          parent: _barCtrl,
          curve: Interval(
            i * 0.12,
            (i * 0.12 + 0.6).clamp(0, 1),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 16),
          if (widget.isLoading)
            _loadingState()
          else if (widget.features.isEmpty)
            _emptyState()
          else
            _featureList(),
          const SizedBox(height: 12),
          _legend(),
        ],
      ),
    );
  }

  Widget _header() => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _purple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.account_tree_outlined,
          color: _purple,
          size: 18,
        ),
      ),
      const SizedBox(width: 12),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SHAP DECISION TREE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            'What drives the AI\'s prediction',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _purple.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'EXPLAINABLE AI',
          style: TextStyle(
            color: _purple,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );

  Widget _featureList() => AnimatedBuilder(
    animation: _barCtrl,
    builder: (_, __) => Column(
      children: List.generate(widget.features.length, (i) {
        final f = widget.features[i];
        final animValue = i < _barAnims.length ? _barAnims[i].value : f.impact;
        return _featureRow(f, animValue, i);
      }),
    ),
  );

  Widget _featureRow(ShapFeature f, double animatedImpact, int index) {
    final favorA = f.direction == 'favors_a';
    final color = favorA ? _cyan : _red;
    final maxImpact = widget.features.isNotEmpty
        ? widget.features.map((e) => e.impact).reduce((a, b) => a > b ? a : b)
        : 1.0;
    final barFraction = maxImpact > 0
        ? (animatedImpact / maxImpact).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatLabel(f.label.isNotEmpty ? f.label : f.feature),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              // Direction chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  favorA
                      ? '▲ ${widget.nameA.split(' ').last}'
                      : '▲ ${widget.nameB.split(' ').last}',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 38,
                child: Text(
                  '+${(f.impact * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Animated bar
          Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: barFraction,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.5), color],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend() => Row(
    children: [
      _legendDot(_cyan),
      const SizedBox(width: 4),
      const Text(
        'Favors Fighter A',
        style: TextStyle(color: Colors.white38, fontSize: 10),
      ),
      const SizedBox(width: 16),
      _legendDot(_red),
      const SizedBox(width: 4),
      const Text(
        'Favors Fighter B',
        style: TextStyle(color: Colors.white38, fontSize: 10),
      ),
      const Spacer(),
      const Text(
        'Bar = relative impact strength',
        style: TextStyle(color: Colors.white24, fontSize: 9),
      ),
    ],
  );

  Widget _legendDot(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _loadingState() => Column(
    children: List.generate(
      4,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white10,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 50,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _emptyState() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.psychology_outlined, color: Colors.white24, size: 32),
          SizedBox(height: 8),
          Text(
            'Adjust sliders to generate SHAP analysis',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    ),
  );

  String _formatLabel(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
