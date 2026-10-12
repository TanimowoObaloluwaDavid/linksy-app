import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/brand.dart';

/// First-run explainer (PRD §8.2).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Insets.gutter,
                  Insets.huge,
                  Insets.gutter,
                  Insets.xl,
                ),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BrandLockup(markSize: 38),
                  ),
                  const SizedBox(height: Insets.giant),
                  Text('Send a file.\nThat’s the whole idea.', style: t.displayLarge),
                  const SizedBox(height: Insets.lg),
                  Text(
                    'No account for the person receiving it. No app to install. '
                    'Just a link or a QR code that opens anywhere.',
                    style: t.body.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: Insets.xxxl),
                  const _Feature(
                    icon: Icons.bolt_rounded,
                    title: 'Built for the handoff',
                    body: 'No sign-up wall on the receiving end. Ever.',
                  ),
                  const _Feature(
                    icon: Icons.lock_outline_rounded,
                    title: 'You hold the keys',
                    body: 'Set an expiry, add a password, revoke access instantly.',
                  ),
                  const _Feature(
                    icon: Icons.qr_code_2_rounded,
                    title: 'Works in person',
                    body: 'Show a code, let them scan it. No typing URLs.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.gutter,
                0,
                Insets.gutter,
                Insets.xxl,
              ),
              child: Column(
                children: [
                  _PrimaryButton(
                    label: 'Create an account',
                    onTap: () => context.push(Routes.signIn),
                  ),
                  const SizedBox(height: Insets.md),
                  TextButton(
                    onPressed: () => context.push(Routes.signIn),
                    child: const Text('I already have one'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(icon, size: 19, color: scheme.primary),
          ),
          const SizedBox(width: Insets.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.subheading),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        child: Text(label, style: t16.copyWith(color: scheme.onPrimary)),
      ),
    );
  }
}

const t16 = TextStyle(
  fontFamily: 'Inter',
  fontSize: 15,
  fontWeight: FontWeight.w600,
);