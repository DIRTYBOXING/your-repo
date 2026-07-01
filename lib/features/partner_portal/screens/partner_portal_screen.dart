import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/mock_partner_portal_service.dart';
import '../models/partner_portal_models.dart';

class PartnerPortalScreen extends StatefulWidget {
  const PartnerPortalScreen({super.key});

  @override
  State<PartnerPortalScreen> createState() => _PartnerPortalScreenState();
}

class _PartnerPortalScreenState extends State<PartnerPortalScreen> {
  final MockPartnerPortalService _service = const MockPartnerPortalService();
  String _pipelineFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final programs = _service.programs;
    final metrics = _service.metrics;
    final stageOptions = <String>{
      'All',
      ..._service.pipeline.map((lead) => lead.stage),
    }.toList();
    final pipeline = _service.pipeline
        .where(
          (lead) => _pipelineFilter == 'All' || lead.stage == _pipelineFilter,
        )
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Partner Portal'),
        backgroundColor: AppTheme.primaryBackground,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email partners@datafightcentral.com to submit a new brief'),
                ),
              );
            },
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppTheme.neonCyan,
            ),
            label: const Text(
              'New Brief',
              style: TextStyle(color: AppTheme.neonCyan),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(),
            const SizedBox(height: 24),
            _buildMetricsGrid(metrics),
            const SizedBox(height: 32),
            _SectionHeader(
              title: 'Active programs',
              actionLabel: 'See pipeline',
              onAction: () {},
            ),
            const SizedBox(height: 12),
            for (final program in programs) ...[
              _ProgramCard(program: program),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 32),
            _SectionHeader(
              title: 'Talent pipeline',
              actionLabel: 'Export',
              onAction: () {},
            ),
            const SizedBox(height: 16),
            _buildPipelineFilters(stageOptions),
            const SizedBox(height: 12),
            if (pipeline.isEmpty)
              const _EmptyState(message: 'No leads in this stage yet.')
            else
              ...pipeline.map(
                (lead) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TalentLeadCard(lead: lead),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B3A), Color(0xFF192228)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonMagenta.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Brand partner console',
            style: TextStyle(
              color: AppTheme.neonMagenta,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track briefs, surface ready-to-sign talent, and push approvals without touching email threads.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(List<PartnerMetric> metrics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: metrics.map((metric) => _MetricCard(metric: metric)).toList(),
    );
  }

  Widget _buildPipelineFilters(List<String> stageOptions) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stageOptions
            .map(
              (stage) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(stage),
                  selected: _pipelineFilter == stage,
                  onSelected: (_) => setState(() => _pipelineFilter = stage),
                  selectedColor: AppTheme.neonCyan,
                  labelStyle: TextStyle(
                    color: _pipelineFilter == stage
                        ? Colors.black
                        : AppTheme.textPrimary,
                  ),
                  backgroundColor: AppTheme.cardBackground,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final PartnerMetric metric;

  @override
  Widget build(BuildContext context) {
    final Color accent = metric.isPositive
        ? AppTheme.neonGreen
        : AppTheme.errorColor;
    final String deltaPrefix = metric.delta > 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(metric.label, style: const TextStyle(color: AppTheme.textMuted)),
          Text(
            metric.value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          Text(
            '$deltaPrefix${metric.delta.toStringAsFixed(1)} vs last sprint',
            style: TextStyle(color: accent, fontSize: 12),
          ),
          Text(
            metric.caption,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program});

  final PartnerProgram program;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.cases_outlined,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.briefTitle,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      program.brandName,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  program.status,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            program.objective,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: program.deliverables
                .map(
                  (deliverable) => Chip(
                    label: Text(deliverable),
                    backgroundColor: AppTheme.surfaceColor,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 16,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                program.budget,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              const Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                program.timeline,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TalentLeadCard extends StatelessWidget {
  const _TalentLeadCard({required this.lead});

  final TalentLead lead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.neonMagenta.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.neonMagenta,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      lead.discipline,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                lead.signal,
                style: const TextStyle(
                  color: AppTheme.neonGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                lead.region,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lead.stage,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lead.notes
                .map(
                  (note) => Chip(
                    label: Text(note),
                    backgroundColor: AppTheme.surfaceColor,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: const TextStyle(color: AppTheme.neonCyan),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.dynamic_feed_outlined,
            size: 36,
            color: AppTheme.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
