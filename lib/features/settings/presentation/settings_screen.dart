import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app.dart';
import '../../../app/preferences.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/ls_button.dart';
import '../../../core/widgets/ls_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../sharing/presentation/share_draft_controller.dart';

/// Profile & settings (PRD §8.13).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final themeMode = ref.watch(themeModeProvider);
    final prefs = ref.watch(notificationPrefsProvider);
    final usage = ref.watch(usageProvider).valueOrNull;

    final prefsController = ref.read(notificationPrefsProvider.notifier);

    return LsScaffold(
      title: 'Settings',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- profile ----
          LsCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.violet, AppColors.cyanDeep],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    user?.initials ?? '?',
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: Insets.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? 'Signed out',
                          style: t.subheading),
                      const SizedBox(height: 1),
                      Text(
                        user?.email ?? '',
                        style: t.caption
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xxl),

          // ---- plan ----
          const LsSectionHeader(label: 'Plan & usage'),
          LsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Free plan', style: t.bodyStrong),
                    const Spacer(),
                    if (usage != null)
                      Text(
                        '${Fmt.bytes(usage.usedBytes)} / ${Fmt.bytes(usage.quotaBytes)}',
                        style: AppType.monoSmall
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
                const SizedBox(height: Insets.md),
                if (usage != null) LsProgressBar(value: usage.fraction),
                const SizedBox(height: Insets.md),
                Text(
                  usage == null
                      ? 'Loading usage…'
                      : '${Fmt.plural(usage.shareLimit - usage.activeShares, 'share')} left · '
                          'up to ${Fmt.bytes(usage.maxFileBytes)} per file',
                  style: t.caption.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: Insets.lg),
                LsButton(
                  label: 'Upgrade to Pro',
                  icon: Icons.workspace_premium_rounded,
                  variant: LsButtonVariant.secondary,
                  expand: true,
                  onPressed: () => _notImplemented(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xxl),

          // ---- appearance ----
          const LsSectionHeader(label: 'Appearance'),
          LsCard(
            padding: const EdgeInsets.all(Insets.md),
            child: LsSegmented<ThemeMode>(
              value: themeMode,
              options: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
              labelBuilder: (m) => switch (m) {
                ThemeMode.system => 'System',
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
              },
              onChanged: (m) => ref.read(themeModeProvider.notifier).set(m),
            ),
          ),
          const SizedBox(height: Insets.xxl),

          // ---- notifications ----
          const LsSectionHeader(label: 'Notifications'),
          LsCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Insets.lg, vertical: Insets.xs),
            child: Column(
              children: [
                _SwitchRow(
                  title: 'Upload finished',
                  value: prefs.uploadComplete,
                  onChanged: (v) => prefsController.toggle('uploadComplete', v),
                ),
                _SwitchRow(
                  title: 'Upload failed',
                  subtitle: 'Only when an upload needs your attention',
                  value: prefs.uploadFailed,
                  onChanged: (v) => prefsController.toggle('uploadFailed', v),
                ),
                _SwitchRow(
                  title: 'Share expiring soon',
                  value: prefs.shareExpiring,
                  onChanged: (v) => prefsController.toggle('shareExpiring', v),
                ),
                _SwitchRow(
                  title: 'Show filenames on lock screen',
                  subtitle: 'Off by default so private names stay private',
                  value: prefs.showSensitivePreviews,
                  onChanged: (v) => prefsController.toggle('previews', v),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xxl),

          // ---- about ----
          const LsSectionHeader(label: 'About'),
          LsCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _LinkRow(
                  icon: Icons.description_outlined,
                  label: 'Privacy policy',
                  onTap: () => _notImplemented(context),
                ),
                const Divider(height: 1, indent: 56),
                _LinkRow(
                  icon: Icons.gavel_rounded,
                  label: 'Terms of service',
                  onTap: () => _notImplemented(context),
                ),
                const Divider(height: 1, indent: 56),
                _LinkRow(
                  icon: Icons.help_outline_rounded,
                  label: 'Support & issue reporting',
                  onTap: () => _notImplemented(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),

          LsButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            variant: LsButtonVariant.secondary,
            expand: true,
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
          const SizedBox(height: Insets.md),
          LsButton(
            label: 'Delete account',
            icon: Icons.delete_outline_rounded,
            variant: LsButtonVariant.danger,
            expand: true,
            onPressed: () => _confirmDelete(context, ref),
          ),

          const SizedBox(height: Insets.xl),
          Center(
            child: Column(
              children: [
                const BrandLockup(markSize: 22),
                const SizedBox(height: Insets.sm),
                Text(
                  'Linksy 1.0.0 · build 1',
                  style: AppType.monoTiny
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _notImplemented(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Not part of this build — see the README.'),
      ));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This removes your profile and revokes every share you own. '
          'Files recipients already downloaded cannot be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(shareActionsProvider).refresh();
      await ref.read(authProvider.notifier).deleteAccount();
    }
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.bodySmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: t.caption.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg, vertical: Insets.lg),
        child: Row(
          children: [
            Icon(icon, size: 19, color: scheme.onSurfaceVariant),
            const SizedBox(width: Insets.lg),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.body)),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}