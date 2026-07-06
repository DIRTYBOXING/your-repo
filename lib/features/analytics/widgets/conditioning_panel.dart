import 'package:flutter/material.dart';
import '../../../shared/services/predictor_live_inputs_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CONDITIONING PANEL — Live Input Sliders → Predictor Engine
// Sliders drive ConditioningInputs which feed directly into the ML predictor.
// Every slider change debounces 600ms then re-runs the LightGBM model.
// ═══════════════════════════════════════════════════════════════════════════════

class ConditioningPanel extends StatefulWidget {
  final ConditioningInputs inputs;
  final ValueChanged<ConditioningInputs> onChanged;
  final String nameA;
  final String nameB;
  final Color colorA;
  final Color colorB;

  const ConditioningPanel({
    super.key,
    required this.inputs,
    required this.onChanged,
    this.nameA = 'Fighter A',
    this.nameB = 'Fighter B',
    this.colorA = const Color(0xFF00E5FF),
    this.colorB = const Color(0xFFFF1744),
  });

  @override
  State<ConditioningPanel> createState() => _ConditioningPanelState();
}

class _ConditioningPanelState extends State<ConditioningPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandCtrl;
  late ConditioningInputs _local;
  bool _expanded = true;

  static const _bg = Color(0xFF0A1628);

  static const _purple = Color(0xFF9C6FFF);
  static const _gold = Color(0xFFFFD600);

  @override
  void initState() {
    super.initState();
    _local = widget.inputs;
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(ConditioningPanel old) {
    super.didUpdateWidget(old);
    if (old.inputs != widget.inputs) {
      _local = widget.inputs;
    }
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _update(ConditioningInputs updated) {
    setState(() => _local = updated);
    widget.onChanged(updated);
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          SizeTransition(
            sizeFactor: _expandCtrl,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _sectionDivider(
                    'FIGHTER A — ${widget.nameA.toUpperCase()}',
                    widget.colorA,
                  ),
                  const SizedBox(height: 12),
                  _slider(
                    label: 'Camp Length',
                    icon: Icons.calendar_today,
                    value: _local.campWeeksA,
                    min: 1,
                    max: 16,
                    color: widget.colorA,
                    displayFormat: (v) => '${v.round()} wks',
                    onChanged: (v) => _update(_local.copyWith(campWeeksA: v)),
                    tooltip: 'Longer camp = more prepared fighter',
                  ),
                  _slider(
                    label: 'Fatigue Level',
                    icon: Icons.battery_alert,
                    value: _local.fatigueA,
                    min: 0,
                    max: 1,
                    color: _fatigueColor(_local.fatigueA),
                    displayFormat: (v) => '${(v * 100).round()}%',
                    onChanged: (v) => _update(_local.copyWith(fatigueA: v)),
                    tooltip: '0 = fresh · 1 = exhausted',
                  ),
                  _slider(
                    label: 'Weight Cut Severity',
                    icon: Icons.monitor_weight_outlined,
                    value: _local.weightCutA,
                    min: 0,
                    max: 1,
                    color: _weightColor(_local.weightCutA),
                    displayFormat: (v) => '${(v * 100).round()}%',
                    onChanged: (v) => _update(_local.copyWith(weightCutA: v)),
                    tooltip: '0 = easy cut · 1 = extreme cut',
                  ),
                  _toggle(
                    label: 'Short Notice',
                    icon: Icons.warning_amber,
                    value: _local.shortNoticeA,
                    color: _gold,
                    onChanged: (v) => _update(_local.copyWith(shortNoticeA: v)),
                  ),

                  const SizedBox(height: 16),
                  _sectionDivider(
                    'FIGHTER B — ${widget.nameB.toUpperCase()}',
                    widget.colorB,
                  ),
                  const SizedBox(height: 12),
                  _slider(
                    label: 'Camp Length',
                    icon: Icons.calendar_today,
                    value: _local.campWeeksB,
                    min: 1,
                    max: 16,
                    color: widget.colorB,
                    displayFormat: (v) => '${v.round()} wks',
                    onChanged: (v) => _update(_local.copyWith(campWeeksB: v)),
                    tooltip: 'Longer camp = more prepared fighter',
                  ),
                  _slider(
                    label: 'Fatigue Level',
                    icon: Icons.battery_alert,
                    value: _local.fatigueB,
                    min: 0,
                    max: 1,
                    color: _fatigueColor(_local.fatigueB),
                    displayFormat: (v) => '${(v * 100).round()}%',
                    onChanged: (v) => _update(_local.copyWith(fatigueB: v)),
                    tooltip: '0 = fresh · 1 = exhausted',
                  ),
                  _slider(
                    label: 'Weight Cut Severity',
                    icon: Icons.monitor_weight_outlined,
                    value: _local.weightCutB,
                    min: 0,
                    max: 1,
                    color: _weightColor(_local.weightCutB),
                    displayFormat: (v) => '${(v * 100).round()}%',
                    onChanged: (v) => _update(_local.copyWith(weightCutB: v)),
                    tooltip: '0 = easy cut · 1 = extreme cut',
                  ),
                  _toggle(
                    label: 'Short Notice',
                    icon: Icons.warning_amber,
                    value: _local.shortNoticeB,
                    color: _gold,
                    onChanged: (v) => _update(_local.copyWith(shortNoticeB: v)),
                  ),

                  const SizedBox(height: 16),
                  _sectionDivider('FIGHT CONTEXT', _purple),
                  const SizedBox(height: 12),
                  _slider(
                    label: 'Market Odds — ${widget.nameA.split(' ').last}',
                    icon: Icons.trending_up,
                    value: _local.oddsA,
                    min: 0.05,
                    max: 0.95,
                    color: _purple,
                    displayFormat: (v) => '${(v * 100).round()}%',
                    onChanged: (v) => _update(
                      _local.copyWith(
                        oddsA: v,
                        oddsB: (1.0 - v).clamp(0.05, 0.95),
                      ),
                    ),
                    tooltip: 'Market-implied win probability',
                  ),
                  _toggle(
                    label: 'Title Fight (5 rounds)',
                    icon: Icons.emoji_events,
                    value: _local.isTitleFight,
                    color: _gold,
                    onChanged: (v) => _update(
                      _local.copyWith(
                        isTitleFight: v,
                        scheduledRounds: v ? 5 : 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => InkWell(
    onTap: _toggleExpand,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune, color: _purple, size: 18),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONDITIONING INPUTS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Drag sliders → probability updates live',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
          AnimatedRotation(
            turns: _expanded ? 0 : 0.5,
            duration: const Duration(milliseconds: 300),
            child: const Icon(Icons.keyboard_arrow_up, color: Colors.white38),
          ),
        ],
      ),
    ),
  );

  Widget _sectionDivider(String label, Color color) => Row(
    children: [
      Container(
        width: 4,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      const Expanded(child: Divider(color: Colors.white10, indent: 12)),
    ],
  );

  Widget _slider({
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required Color color,
    required String Function(double) displayFormat,
    required ValueChanged<double> onChanged,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  displayFormat(value),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          if (tooltip != null)
            Text(
              tooltip,
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _toggle({
    required String label,
    required IconData icon,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: value ? color : Colors.white24, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: value ? Colors.white : Colors.white38,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Color _fatigueColor(double v) {
    if (v < 0.33) return const Color(0xFF00E676);
    if (v < 0.66) return const Color(0xFFFFD600);
    return const Color(0xFFFF1744);
  }

  Color _weightColor(double v) {
    if (v < 0.25) return const Color(0xFF00E676);
    if (v < 0.6) return const Color(0xFFFFD600);
    return const Color(0xFFFF1744);
  }
}
