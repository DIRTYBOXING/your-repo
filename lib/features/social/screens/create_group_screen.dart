import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/group_service.dart';
import '../../../shared/models/community/group_model.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  GroupPrivacy _privacy = GroupPrivacy.public;
  String _category = 'general';
  bool _isSubmitting = false;

  static const _categories = <String, IconData>{
    'general': Icons.groups,
    'gym': Icons.fitness_center,
    'team': Icons.people,
    'fan_club': Icons.star,
    'promotion': Icons.campaign,
  };

  static const _privacyInfo = <GroupPrivacy, Map<String, dynamic>>{
    GroupPrivacy.public: {
      'icon': Icons.public,
      'label': 'Public',
      'hint': 'Anyone can find and join',
    },
    GroupPrivacy.private: {
      'icon': Icons.lock_outline,
      'label': 'Private',
      'hint': 'Visible but must request to join',
    },
    GroupPrivacy.secret: {
      'icon': Icons.visibility_off,
      'label': 'Secret',
      'hint': 'Invite-only, hidden from search',
    },
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty && !_isSubmitting;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final auth = context.read<AuthService>();
    final groupService = context.read<GroupService>();
    final userId =
        auth.currentUser?.uid ??
        (auth.isDemoUser ? AuthService.demoUserId : null);

    if (userId == null) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to create a group'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await groupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        privacy: _privacy,
        creatorId: userId,
        category: _category,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Group',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedOpacity(
              opacity: _canSubmit ? 1.0 : 0.35,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: _canSubmit ? _submit : null,
                style: TextButton.styleFrom(
                  backgroundColor: _canSubmit
                      ? DesignTokens.neonCyan
                      : Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Create',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Group Name ──────────────────
              _sectionLabel('GROUP NAME'),
              const SizedBox(height: DesignTokens.spacingS),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                maxLength: 60,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'e.g. East Side Boxing Crew',
                  counterStyle: TextStyle(color: DesignTokens.textMuted),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter a group name'
                    : null,
              ),
              const SizedBox(height: DesignTokens.spacingXL),

              // ── Description ─────────────────
              _sectionLabel('DESCRIPTION'),
              const SizedBox(height: DesignTokens.spacingS),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'What is this group about?',
                  counterStyle: TextStyle(color: DesignTokens.textMuted),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXL),

              // ── Category ────────────────────
              _sectionLabel('CATEGORY'),
              const SizedBox(height: DesignTokens.spacingS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.entries.map((e) {
                  final selected = _category == e.key;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          e.value,
                          size: 16,
                          color: selected
                              ? Colors.black
                              : DesignTokens.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(_categoryLabel(e.key)),
                      ],
                    ),
                    selected: selected,
                    selectedColor: DesignTokens.neonCyan,
                    backgroundColor: DesignTokens.bgCard,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.black
                          : DesignTokens.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                      side: BorderSide(
                        color: selected
                            ? DesignTokens.neonCyan
                            : DesignTokens.neonCyan.withValues(alpha: 0.15),
                      ),
                    ),
                    onSelected: (_) => setState(() => _category = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: DesignTokens.spacingXXL),

              // ── Privacy ─────────────────────
              _sectionLabel('PRIVACY'),
              const SizedBox(height: DesignTokens.spacingS),
              ...GroupPrivacy.values.map(_privacyTile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: DesignTokens.neonCyan,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );

  Widget _privacyTile(GroupPrivacy p) {
    final info = _privacyInfo[p]!;
    final selected = _privacy == p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        onTap: () => setState(() => _privacy = p),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? DesignTokens.neonCyan.withValues(alpha: 0.08)
                : DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(
              color: selected
                  ? DesignTokens.neonCyan
                  : DesignTokens.neonCyan.withValues(alpha: 0.12),
              width: selected ? 1.5 : 0.6,
            ),
          ),
          child: Row(
            children: [
              Icon(
                info['icon'] as IconData,
                color: selected
                    ? DesignTokens.neonCyan
                    : DesignTokens.textMuted,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info['label'] as String,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : DesignTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info['hint'] as String,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: DesignTokens.neonCyan,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String key) {
    switch (key) {
      case 'gym':
        return 'Gym';
      case 'team':
        return 'Team';
      case 'fan_club':
        return 'Fan Club';
      case 'promotion':
        return 'Promotion';
      default:
        return 'General';
    }
  }
}
