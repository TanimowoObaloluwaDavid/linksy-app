import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/brand.dart';

/// Held while the stored session is restored (PRD §8.1).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandMark(size: 76),
            const SizedBox(height: Insets.xxl),
            Text('Linksy', style: AppType.title.copyWith(color: scheme.onSurface)),
            const SizedBox(height: Insets.xs),
            Text(
              'Sharing, without the friction.',
              style: AppType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Insets.xxxl),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}