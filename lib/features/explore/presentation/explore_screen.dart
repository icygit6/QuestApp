import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/quest_snack_bar.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../posts/presentation/posts_provider.dart';
import '../../posts/presentation/posts_tab.dart';
import '../../quotes/presentation/quotes_tab.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.explore),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.gold,
          unselectedLabelColor: context.palette.textSecondary,
          indicatorColor: AppColors.gold,
          tabs: const [
            Tab(text: AppStrings.quotes),
            Tab(text: AppStrings.posts),
          ],
        ),
      ),
      floatingActionButton: _activeTab == 1
          ? FloatingActionButton(
              onPressed: _showAddPostSheet,
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.onAccent,
              tooltip: 'New Chronicle',
              child: const Icon(Icons.edit_rounded),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: const [QuotesTab(), PostsTab()],
      ),
    );
  }

  void _showAddPostSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddPostSheet(
        userId: ref.read(authStateProvider).user?.id ?? 1,
      ),
    );
  }
}

class _AddPostSheet extends ConsumerStatefulWidget {
  const _AddPostSheet({required this.userId});

  final int userId;

  @override
  ConsumerState<_AddPostSheet> createState() => _AddPostSheetState();
}

class _AddPostSheetState extends ConsumerState<_AddPostSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                'NEW CHRONICLE',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Give your post a title',
              labelText: 'Title',
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLength: 100,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            decoration: const InputDecoration(
              hintText: 'Share your adventure...',
              labelText: 'Body',
              alignLabelWithHint: true,
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 4,
            maxLength: 500,
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'PUBLISH',
            icon: Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      showQuestSnackBar(
        context,
        message: 'Title and body are required.',
        icon: Icons.warning_amber_rounded,
        color: AppColors.medium,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final error = await ref.read(postsProvider.notifier).create(
        title: title,
        body: body,
        userId: widget.userId,
      );
      if (!mounted) return;
      if (error != null) {
        showQuestSnackBar(
          context,
          message: error,
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
        );
        return;
      }
      Navigator.of(context).pop();
      showQuestSnackBar(
        context,
        message: 'Chronicle published!',
        icon: Icons.check_circle_rounded,
        color: AppColors.easy,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
