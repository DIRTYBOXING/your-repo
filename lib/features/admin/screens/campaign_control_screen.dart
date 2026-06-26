import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/admin_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ❤️ CAMPAIGN CONTROL SCREEN — Manage community campaigns
/// ═══════════════════════════════════════════════════════════════════════════
class CampaignControlScreen extends StatefulWidget {
  final String adminId;

  const CampaignControlScreen({super.key, required this.adminId});

  @override
  State<CampaignControlScreen> createState() => _CampaignControlScreenState();
}

class _CampaignControlScreenState extends State<CampaignControlScreen> {
  final _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text(
          'Campaign Control',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.neonGreen),
            onPressed: _showCreateCampaignDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<CampaignSummary>>(
        stream: _adminService.streamCampaigns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.neonGreen),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final campaigns = snapshot.data ?? [];

          if (campaigns.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign, size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No campaigns yet',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create a campaign',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: campaigns.length,
            itemBuilder: (context, index) =>
                _buildCampaignCard(campaigns[index]),
          );
        },
      ),
    );
  }

  Widget _buildCampaignCard(CampaignSummary campaign) {
    Color typeColor;
    String emoji;

    switch (campaign.type.toLowerCase()) {
      case 'pink_shield':
        typeColor = Colors.pinkAccent;
        emoji = '❤️';
        break;
      case 'gold_coin':
        typeColor = Colors.amber;
        emoji = '🥇';
        break;
      case 'nightchill':
        typeColor = Colors.cyan;
        emoji = '☕';
        break;
      default:
        typeColor = AppTheme.accentPurple;
        emoji = '🌟';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      campaign.type.toUpperCase(),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(campaign.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Goal',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${campaign.goalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Raised',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${campaign.raisedAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${campaign.progressPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppTheme.neonGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: campaign.progressPercent / 100,
              backgroundColor: AppTheme.cardDark,
              valueColor: AlwaysStoppedAnimation(typeColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleFeature(campaign),
                  icon: const Icon(Icons.star, size: 18),
                  label: const Text('Feature'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.2),
                    foregroundColor: AppTheme.neonGreen,
                    side: const BorderSide(color: AppTheme.neonGreen),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentTeal.withValues(alpha: 0.2),
                    foregroundColor: AppTheme.accentTeal,
                    side: const BorderSide(color: AppTheme.accentTeal),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'paused':
        color = Colors.orange;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      default:
        color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _toggleFeature(CampaignSummary campaign) async {
    try {
      await _adminService.featureCampaign(campaign.id, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${campaign.name} featured in feed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _showCreateCampaignDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final goalController = TextEditingController();
    String selectedType = 'pink_shield';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Create Campaign',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Campaign Name',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: AppTheme.textPrimary),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: goalController,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Goal Amount (\$)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                dropdownColor: AppTheme.cardDark,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Campaign Type',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'pink_shield',
                    child: Text('❤️ Pink Shield'),
                  ),
                  DropdownMenuItem(
                    value: 'gold_coin',
                    child: Text('🥇 Gold Coin Drive'),
                  ),
                  DropdownMenuItem(
                    value: 'nightchill',
                    child: Text('☕ NightChill'),
                  ),
                  DropdownMenuItem(
                    value: 'community',
                    child: Text('🌟 Community'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) selectedType = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _adminService.createCampaign(
                  name: nameController.text,
                  description: descController.text,
                  type: selectedType,
                  goalAmount: double.parse(goalController.text),
                  adminId: widget.adminId,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Campaign created')));
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Create', style: TextStyle(color: AppTheme.neonGreen)),
          ),
        ],
      ),
    );
  }
}
