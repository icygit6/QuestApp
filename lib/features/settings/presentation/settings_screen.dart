import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/quest_snack_bar.dart';
import '../../gamification/presentation/gamification_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark theme',
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              activeThumbColor: AppColors.gold,
              onChanged: (value) =>
                  ref.read(settingsProvider.notifier).setDarkMode(value),
            ),
          ),
          _SettingsTile(
            icon: Icons.notifications_active_rounded,
            title: 'Notifications',
            trailing: Switch(
              value: settings.notificationsEnabled,
              activeThumbColor: AppColors.gold,
              onChanged: (value) =>
                  ref.read(settingsProvider.notifier).setNotifications(value),
            ),
          ),
          _SettingsTile(
            icon: Icons.restart_alt_rounded,
            title: 'Reset progress',
            titleColor: AppColors.danger,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _confirmReset(context, ref),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy Policy',
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _showPrivacy(context),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About QuestBoard',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.aboutQuestBoard,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Version 0.1.0',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Reset progress?'),
          content: const Text(
            'XP, streaks, daily history, achievements, and local quest progress will be reset.',
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('RESET EVERYTHING'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      if (context.mounted) {
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          ),
        );
      }
      await ref.read(gamificationProvider.notifier).resetAllProgress();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        context.go('/quests');
        showQuestSnackBar(
          context,
          message: 'Progress reset. New adventure begins!',
          icon: Icons.restart_alt_rounded,
          color: AppColors.gold,
        );
      }
    }
  }

  void _showPrivacy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Privacy Policy'),
          content: const Text(
            'QuestBoard stores your token securely on this device and keeps XP, streak, quest cache, and achievements locally.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: titleColor ?? AppColors.gold),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: titleColor ?? AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}
