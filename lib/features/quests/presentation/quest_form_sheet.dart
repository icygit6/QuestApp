import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/quest_snack_bar.dart';
import '../domain/quest_entity.dart';
import 'custom_quest_provider.dart';

/// Opens the create/edit sheet for a user quest.
///
/// Pass [existing] to edit; omit it to create. Returns once the sheet closes.
Future<void> showQuestFormSheet(
  BuildContext context, {
  required int userId,
  QuestEntity? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _QuestFormSheet(userId: userId, existing: existing),
  );
}

class _QuestFormSheet extends ConsumerStatefulWidget {
  const _QuestFormSheet({required this.userId, this.existing});

  final int userId;
  final QuestEntity? existing;

  @override
  ConsumerState<_QuestFormSheet> createState() => _QuestFormSheetState();
}

class _QuestFormSheetState extends ConsumerState<_QuestFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late QuestDifficulty _difficulty;
  late QuestCategory _category;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _difficulty = existing?.difficulty ?? QuestDifficulty.easy;
    _category = existing?.category ?? QuestCategory.combat;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.gold),
                const SizedBox(width: 8),
                Text(
                  _isEditing ? 'EDIT QUEST' : 'NEW QUEST',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Name your quest',
                labelText: 'Title',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLength: 80,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Describe the challenge (optional)',
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 12),
            Text('Difficulty', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final value in QuestDifficulty.values)
                  ChoiceChip(
                    label: Text('${value.label} · ${value.xpReward} XP'),
                    selected: _difficulty == value,
                    showCheckmark: false,
                    selectedColor: AppColors.gold,
                    backgroundColor: context.palette.surfaceAlt,
                    side: BorderSide(color: context.palette.border),
                    labelStyle: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(
                          color: _difficulty == value
                              ? AppColors.onAccent
                              : context.palette.textSecondary,
                        ),
                    onSelected: (_) => setState(() => _difficulty = value),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Category', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final value in QuestCategory.values)
                  ChoiceChip(
                    label: Text(value.label),
                    selected: _category == value,
                    showCheckmark: false,
                    selectedColor: AppColors.gold,
                    backgroundColor: context.palette.surfaceAlt,
                    side: BorderSide(color: context.palette.border),
                    labelStyle: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(
                          color: _category == value
                              ? AppColors.onAccent
                              : context.palette.textSecondary,
                        ),
                    onSelected: (_) => setState(() => _category = value),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: _isEditing ? 'SAVE CHANGES' : 'CREATE QUEST',
              icon: Icons.check_rounded,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showQuestSnackBar(
        context,
        message: 'A quest needs a title.',
        icon: Icons.warning_amber_rounded,
        color: AppColors.medium,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final notifier = ref.read(customQuestsProvider.notifier);
    final description = _descriptionController.text.trim();
    try {
      if (_isEditing) {
        await notifier.update(
          widget.existing!.copyWith(
            title: title,
            description: description,
            difficulty: _difficulty,
            category: _category,
          ),
        );
      } else {
        await notifier.create(
          title: title,
          description: description,
          difficulty: _difficulty,
          category: _category,
          assignedTo: widget.userId,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showQuestSnackBar(
        context,
        message: _isEditing ? 'Quest updated!' : 'Quest forged!',
        icon: Icons.check_circle_rounded,
        color: AppColors.easy,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
