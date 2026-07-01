import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/router_config.dart' as app_router;
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/brand_video_player.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingFlowScreen extends StatelessWidget {
  const OnboardingFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppTheme.primaryBackground,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _OnboardingHeader(
                    progress: controller.progress,
                    step: controller.currentStep + 1,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppConstants.mediumAnimation,
                      child: _buildStep(controller),
                    ),
                  ),
                  if (controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        controller.errorMessage!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.error),
                      ),
                    ),
                  _OnboardingControls(controller: controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(OnboardingController controller) {
    switch (controller.currentStep) {
      case 0:
        return _VideoIntroStep(controller: controller);
      case 1:
        return _RoleIntentStep(controller: controller);
      case 2:
        return _LoadCalibrationStep(controller: controller);
      case 3:
        return _OpportunitiesStep(controller: controller);
      case 4:
        return _ConsentStep(controller: controller);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _OnboardingHeader extends StatelessWidget {
  final double progress;
  final int step;

  const _OnboardingHeader({required this.progress, required this.step});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mind • Body • Soul',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            Text('Step $step / ${OnboardingController.totalSteps}'),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppTheme.surfaceColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
          ),
        ),
      ],
    );
  }
}

/// Step 0: Video introduction showcasing the platform
class _VideoIntroStep extends StatelessWidget {
  final OnboardingController controller;

  const _VideoIntroStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome to DataFightCentral',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'The promotional engine for events, fights & combat sports',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BrandVideoPlayer(
              videoType: BrandVideoType.promo,
              showControls: true,
              onSkip: controller.nextStep,
              onComplete: controller.nextStep,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap Skip or Continue to begin your journey',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _RoleIntentStep extends StatelessWidget {
  final OnboardingController controller;

  const _RoleIntentStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    final activeRole = controller.activeRole;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.roleStepTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            controller.roleStepSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Column(
            children: controller.roleOptions
                .map(
                  (role) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RoleChoiceCard(
                      role: role,
                      selected: activeRole == role,
                      onTap: () => controller.selectRole(role),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          Text(
            'Why are you here?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: controller.adaptiveIntentOptions
                .map(
                  (intent) => FilterChip(
                    label: Text(intent),
                    selected: controller.selectedIntents.contains(intent),
                    onSelected: (_) => controller.toggleIntent(intent),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LoadCalibrationStep extends StatelessWidget {
  final OnboardingController controller;

  const _LoadCalibrationStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.loadStepTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'DFC will use this to shape recommendations, pacing, and the kind of support surfaces you see first.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          _LoadSlider(
            label: 'Mind',
            value: controller.mindLoad,
            accent: AppTheme.neonPurple,
            onChanged: controller.updateMindLoad,
          ),
          _LoadSlider(
            label: 'Body',
            value: controller.bodyLoad,
            accent: AppTheme.neonGreen,
            onChanged: controller.updateBodyLoad,
          ),
          _LoadSlider(
            label: 'Soul',
            value: controller.soulLoad,
            accent: AppTheme.neonOrange,
            onChanged: controller.updateSoulLoad,
          ),
          const SizedBox(height: 24),
          Text(
            'What keeps you reset?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: controller.adaptivePracticeOptions
                .map(
                  (practice) => FilterChip(
                    label: Text(practice),
                    selected: controller.preferredPractices.contains(practice),
                    onSelected: (_) => controller.togglePractice(practice),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LoadSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color accent;
  final ValueChanged<double> onChanged;

  const _LoadSlider({
    required this.label,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: accent),
            ),
            const Spacer(),
            Text(value.toStringAsFixed(1)),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          max: 10,
          activeColor: accent,
          inactiveColor: accent.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}

class _OpportunitiesStep extends StatelessWidget {
  final OnboardingController controller;

  const _OpportunitiesStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.opportunityStepTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Pick the outcomes that matter most now. This helps DFC rank intros, tools, and opportunities around your lane.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: controller.adaptiveOpportunityOptions
                .map(
                  (option) => FilterChip(
                    label: Text(option),
                    selected: controller.opportunityInterests.contains(option),
                    onSelected: (_) => controller.toggleOpportunity(option),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'What story should we spotlight?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 4,
            onChanged: controller.updateStoryIntro,
            decoration: InputDecoration(
              hintText:
                  '${controller.storyPromptHint} We will thread it into your DFC journey.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentStep extends StatelessWidget {
  final OnboardingController controller;

  const _ConsentStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    final role =
        controller.selectedRole ?? controller.authService.userModel?.role;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final pass before we generate your Journey glyph.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            title: 'Identity & Intent',
            content: [
              'Role: ${role?.displayName ?? 'Not set'}',
              'Intents: ${controller.selectedIntents.join(', ')}',
            ],
          ),
          _SummaryCard(
            title: 'Offsets & Rituals',
            content: [
              'Mind/Body/Soul: ${controller.mindLoad.toStringAsFixed(0)} / ${controller.bodyLoad.toStringAsFixed(0)} / ${controller.soulLoad.toStringAsFixed(0)}',
              'Practices: ${controller.preferredPractices.join(', ')}',
            ],
          ),
          _SummaryCard(
            title: 'Opportunities',
            content: [
              controller.opportunityInterests.isEmpty
                  ? 'We will recommend based on your intents.'
                  : controller.opportunityInterests.join(', '),
              if (controller.storyIntro.isNotEmpty)
                'Story: ${controller.storyIntro}',
            ],
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: controller.termsAccepted,
            onChanged: (value) => controller.setTermsAccepted(value ?? false),
            title: const Text('I agree to the Terms & Privacy commitments.'),
          ),
          CheckboxListTile(
            value: controller.updatesOptIn,
            onChanged: (value) => controller.setUpdatesOptIn(value ?? true),
            title: const Text('Send me curated rituals and partner invites.'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<String> content;

  const _SummaryCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardBackground,
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...content
              .where((line) => line.isNotEmpty)
              .map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (role) {
      case UserRole.fighter:
        return Icons.sports_mma_rounded;
      case UserRole.promoter:
        return Icons.campaign_rounded;
      case UserRole.gym:
        return Icons.fitness_center_rounded;
      case UserRole.fan:
        return Icons.visibility_rounded;
      case UserRole.coach:
        return Icons.record_voice_over_rounded;
      case UserRole.sponsor:
        return Icons.handshake_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }

  Color get _accent => AppTheme.getRoleColor(role.name);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.mediumAnimation,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? _accent.withValues(alpha: 0.12)
              : AppTheme.cardBackground,
          border: Border.all(
            color: selected ? _accent : AppTheme.surfaceColor,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_icon, color: _accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? _accent : AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingControls extends StatelessWidget {
  final OnboardingController controller;

  const _OnboardingControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (controller.currentStep > 0)
          OutlinedButton(
            onPressed: controller.isSaving ? null : controller.previousStep,
            child: const Text('Back'),
          )
        else
          const SizedBox(width: 96),
        const Spacer(),
        ElevatedButton(
          onPressed: controller.canContinue && !controller.isSaving
              ? () async {
                  if (controller.isLastStep) {
                    final success = await controller.completeOnboarding();
                    if (context.mounted) {
                      if (success) {
                        context.go(app_router.RouterConfig.homePath);
                      } else {
                        // Show prominent error so user knows what happened
                        final errorMsg =
                            controller.errorMessage ??
                            'Something went wrong. Tap again or skip below.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMsg),
                            backgroundColor: Colors.red.shade800,
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'SKIP TO HOME',
                              textColor: Colors.white,
                              onPressed: () {
                                if (context.mounted) {
                                  context.go(app_router.RouterConfig.homePath);
                                }
                              },
                            ),
                          ),
                        );
                      }
                    }
                  } else {
                    controller.nextStep();
                  }
                }
              : null,
          style: controller.isSaving
              ? ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.3),
                )
              : null,
          child: controller.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  controller.isLastStep
                      ? 'Generate Journey Glyph \u2728'
                      : 'Continue',
                ),
        ),
      ],
    );
  }
}
