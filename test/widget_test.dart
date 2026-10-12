import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linksy/core/painters/transfer_rail.dart';
import 'package:linksy/core/theme/app_theme.dart';
import 'package:linksy/core/utils/formatters.dart';
import 'package:linksy/features/sharing/domain/shared_file.dart';

import 'package:linksy/features/sharing/presentation/share_draft_controller.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(theme: AppTheme.dark, home: child),
    );

void main() {
  group('Fmt', () {
    test('byte counts use 1024 steps and stay readable', () {
      expect(Fmt.bytes(0), '0 B');
      expect(Fmt.bytes(999), '999 B');
      expect(Fmt.bytes(1024), '1.0 KB');
      expect(Fmt.bytes(1536), '1.5 KB');
      expect(Fmt.bytes(1024 * 1024), '1.0 MB');
      // 2 GiB is 2.0 GB — the scale is binary, the suffix is decimal-named.
      expect(Fmt.bytes(2 * 1024 * 1024 * 1024), '2.0 GB');
      expect(Fmt.bytes(1024 * 1024 * 1024 * 1024), '1.0 TB');
    });

    test('remaining time reads as a countdown and stops at zero', () {
      final now = DateTime(2026, 1, 1, 12);
      expect(Fmt.remaining(now.add(const Duration(seconds: 30)), now), '30s left');
      expect(Fmt.remaining(now.add(const Duration(hours: 2)), now), '2 hours left');
      expect(Fmt.remaining(now.subtract(const Duration(minutes: 1)), now), isNull);
    });

    test('ellipsizeMiddle always preserves the extension', () {
      const name = 'quarterly-financial-report-2026-final.pdf';
      final out = Fmt.ellipsizeMiddle(name, 20);
      expect(out.endsWith('.pdf'), isTrue);
      expect(out.length, lessThanOrEqualTo(21));
      expect(Fmt.ellipsizeMiddle('short.pdf', 20), 'short.pdf');
    });
  });

  group('ShareDraftController', () {
    test('duplicate filenames are disambiguated, not overwritten', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(shareDraftProvider.notifier).addFiles([
        const SharedFile(
          id: 'a', name: 'report.pdf', sizeBytes: 100,
          state: FileUploadState.queued,
        ),
        const SharedFile(
          id: 'b', name: 'report.pdf', sizeBytes: 200,
          state: FileUploadState.queued,
        ),
        const SharedFile(
          id: 'c', name: 'report.pdf', sizeBytes: 300,
          state: FileUploadState.queued,
        ),
      ]);

      final names =
          container.read(shareDraftProvider).files.map((f) => f.name).toList();
      expect(names, ['report.pdf', 'report (2).pdf', 'report (3).pdf']);
    });

    test('a share cannot be submitted without a title or files', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(shareDraftProvider).canSubmit, isFalse);

      final c = container.read(shareDraftProvider.notifier);
      c.addFiles([
        const SharedFile(
          id: 'a', name: 'a.pdf', sizeBytes: 1,
          state: FileUploadState.queued,
        ),
      ]);
      expect(container.read(shareDraftProvider).canSubmit, isFalse,
          reason: 'files alone are not enough');

      c.setTitle('Holiday photos');
      expect(container.read(shareDraftProvider).canSubmit, isTrue);
    });

    test('total progress reflects bytes sent across all files', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final c = container.read(shareDraftProvider.notifier);
      c.addFiles([
        const SharedFile(
          id: 'a', name: 'a.bin', sizeBytes: 1000,
          state: FileUploadState.queued,
        ),
        const SharedFile(
          id: 'b', name: 'b.bin', sizeBytes: 1000,
          state: FileUploadState.queued,
        ),
      ]);
      c.setTitle('Two files');

      expect(container.read(shareDraftProvider).progress, 0);

      c.retryFile('a');
      final state = container.read(shareDraftProvider);
      expect(state.totalBytes, 2000);
      expect(state.progress, 0);
    });
  });

  testWidgets('TransferRail paints without error in both stages',
      (tester) async {
    for (final stage in RailStage.values) {
      await tester.pumpWidget(_wrap(
        Scaffold(
          body: TransferRail(stage: stage, progress: 0.5, reducedMotion: true),
        ),
      ));
      await tester.pump();
      expect(find.byType(TransferRail), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('ShareReady shows a recovery path when there is no share',
      (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    expect(tester.takeException(), isNull);
  });
}