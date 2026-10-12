// Renders every screen to a PNG under `screenshots/`.
//
// This is a verification harness, not a golden test: it exists so the UI can be
// eyeballed without a device. Run it with:
//
//     flutter test test/screenshot_harness.dart
//
// Images land in `screenshots/`. They are not asserted against, because
// platform font rasterisation differs between machines and a golden
// comparison would fail spuriously.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linksy/app/preferences.dart';
import 'package:linksy/core/theme/app_theme.dart';
import 'package:linksy/features/auth/domain/app_user.dart';
import 'package:linksy/features/auth/presentation/auth_controller.dart';
import 'package:linksy/features/home/presentation/home_screen.dart';
import 'package:linksy/features/home/presentation/sign_in_screen.dart';
import 'package:linksy/features/home/presentation/welcome_screen.dart';
import 'package:linksy/features/receiving/presentation/receive_screen.dart';
import 'package:linksy/features/settings/presentation/settings_screen.dart';
import 'package:linksy/features/sharing/data/in_memory_share_repository.dart';
import 'package:linksy/features/sharing/domain/share.dart';
import 'package:linksy/features/sharing/domain/shared_file.dart';
import 'package:linksy/features/sharing/presentation/my_shares_screen.dart';
import 'package:linksy/features/sharing/presentation/pick_files_screen.dart';
import 'package:linksy/features/sharing/presentation/share_draft_controller.dart';
import 'package:linksy/features/sharing/presentation/share_ready_screen.dart';
import 'package:linksy/features/sharing/presentation/upload_screen.dart';
import 'package:linksy/features/transfers/presentation/transfers_screen.dart';
import 'package:linksy/features/vault/presentation/vault_screen.dart';

const _dir = 'screenshots';
final _key = GlobalKey();

/// Signed-in session so screens that sit behind the auth guard render.
/// `overrideWith` requires the concrete notifier type, so this extends the
/// real controller rather than replacing it.
class _SignedInAuth extends AuthController {
  @override
  AuthState build() => AuthState(
        status: AuthStatus.signedIn,
        user: AppUser(
          id: 'u1',
          displayName: 'Amaka Obi',
          email: 'amaka@example.com',
          createdAt: DateTime(2026, 1, 4),
        ),
      );
}

/// Pins the share draft to a known state so a screen renders mid-workflow
/// instead of empty.
class _FixedDraft extends ShareDraftController {
  _FixedDraft(this._state);
  final ShareDraftState _state;
  @override
  ShareDraftState build() => _state;
}

InMemoryShareRepository _seeded() {
  final repo = InMemoryShareRepository();
  final now = DateTime.now();

  repo.seed(Share(
    id: 's1', slug: 'kx7m2qpd91vn',
    title: 'Brand guidelines — final',
    status: ShareStatus.active,
    createdAt: now.subtract(const Duration(hours: 3)),
    expiresAt: now.add(const Duration(days: 6)),
    fileCount: 4, totalBytes: 18_400_000, downloadCount: 12,
  ));
  repo.seed(Share(
    id: 's2', slug: 'rt3wz8hn02bf',
    title: 'quarterly-financial-report-2026.pdf',
    status: ShareStatus.active,
    createdAt: now.subtract(const Duration(days: 2)),
    expiresAt: now.add(const Duration(hours: 9)),
    fileCount: 1, totalBytes: 2_650_000, downloadCount: 3,
  ));
  repo.seed(Share(
    id: 's3', slug: 'aa91kcm44xdq',
    title: 'Wedding photos',
    status: ShareStatus.expired,
    createdAt: now.subtract(const Duration(days: 40)),
    expiresAt: now.subtract(const Duration(days: 33)),
    fileCount: 86, totalBytes: 942_000_000, downloadCount: 41,
  ));
  return repo;
}

Future<void> _snap(WidgetTester tester, String name) async {
  // `matchesGoldenFile` is the supported capture path in `flutter test` —
  // `RenderRepaintBoundary.toImage()` stalls in the headless rasteriser.
  // Run with `--update-goldens` to (re)write the PNGs.
  await expectLater(
    find.byKey(_key),
    matchesGoldenFile('../screenshots/$name.png'),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  ThemeMode mode = ThemeMode.dark,
  String name = '',
  ShareDraftState? draft,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(430 * 3, 932 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_SignedInAuth.new),
        themeModeProvider.overrideWith(() => _FixedTheme(mode)),
        if (draft != null)
          shareDraftProvider.overrideWith(() => _FixedDraft(draft)),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: RepaintBoundary(
          key: _key,
          child: Scaffold(body: screen),
        ),
      ),
    ),
  );

  // No pumpAndSettle: the transfer rail, skeletons and QR reveal all animate
  // indefinitely, so it would never settle. Pump a fixed number of frames.
  for (var i = 0; i < 14; i++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
  await _snap(tester, name);
}

class _FixedTheme extends ThemeController {
  _FixedTheme(this.mode);
  final ThemeMode mode;
  @override
  ThemeMode build() => mode;
}

/// Loads the real bundled typefaces into the test environment.
///
/// Without this, `flutter test` renders every glyph as an Ahem box — same width
/// for every character. That both makes screenshots useless and triggers false
/// RenderFlex overflows, because boxed text is far wider than real text.
///
/// [FontLoader] registers one file per family, so weight variants collapse to a
/// single weight. Metrics and glyph shapes are correct, which is what these
/// screenshots exist to check.
Future<void> loadAppFonts() async {
  Future<void> load(String family, String path) async {
    final loader = FontLoader(family)
      ..addFont(rootBundle.load(path));
    await loader.load();
  }

  await load('SpaceGrotesk', 'assets/fonts/SpaceGrotesk-Bold.ttf');
  await load('Inter', 'assets/fonts/Inter-Regular.ttf');
  await load('JetBrainsMono', 'assets/fonts/JetBrainsMono-Regular.ttf');

  // MaterialIcons ships with the SDK rather than the project, so it has to be
  // read off disk. Skipped silently if the SDK is somewhere unexpected.
  final root = Platform.environment['FLUTTER_ROOT'] ??
      'C:${Platform.pathSeparator}flutter';
  final iconFont = File(
    '$root${Platform.pathSeparator}bin${Platform.pathSeparator}cache'
    '${Platform.pathSeparator}artifacts${Platform.pathSeparator}material_fonts'
    '${Platform.pathSeparator}MaterialIcons-Regular.otf',
  );
  if (iconFont.existsSync()) {
    final bytes = await iconFont.readAsBytes();
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(bytes))))
        .load();
  }
}

void main() {
  setUpAll(() async {
    Directory(_dir).createSync(recursive: true);
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  final repo = _seeded();
  final repoOverride = <Override>[shareRepositoryProvider.overrideWithValue(repo)];

  testWidgets('01 welcome', (t) => _pump(t, const WelcomeScreen(), name: '01-welcome'));

  testWidgets('02 sign in', (t) => _pump(t, const SignInScreen(), name: '02-signin'));

  testWidgets('03 home', (t) => _pump(t, const HomeScreen(), name: '03-home', overrides: repoOverride));

  testWidgets('04 pick files', (t) => _pump(
        t,
        const PickFilesScreen(),
        name: '04-pick-files',
        overrides: repoOverride,
        draft: const ShareDraftState(
          title: 'Launch assets',
          files: [
            SharedFile(id: '1', name: 'brand-guidelines-final.pdf', sizeBytes: 8400000, mime: 'application/pdf', state: FileUploadState.queued),
            SharedFile(id: '2', name: 'hero-shot-01.jpg', sizeBytes: 4200000, mime: 'image/jpeg', state: FileUploadState.queued),
            SharedFile(id: '3', name: 'launch-cut.mp4', sizeBytes: 5800000, mime: 'video/mp4', state: FileUploadState.queued),
            SharedFile(id: '4', name: 'invoice-march.pdf', sizeBytes: 260000, mime: 'application/pdf', state: FileUploadState.queued),
          ],
        ),
      ));

  testWidgets('05 upload', (t) => _pump(
        t,
        const UploadScreen(),
        name: '05-upload',
        overrides: repoOverride,
        draft: const ShareDraftState(
          title: 'Launch assets',
          phase: UploadPhase.uploading,
          files: [
            SharedFile(id: '1', name: 'brand-guidelines-final.pdf', sizeBytes: 8400000, state: FileUploadState.ready, bytesSent: 8400000),
            SharedFile(id: '2', name: 'hero-shot-01.jpg', sizeBytes: 4200000, state: FileUploadState.uploading, bytesSent: 2900000),
            SharedFile(id: '3', name: 'launch-cut.mp4', sizeBytes: 5800000, state: FileUploadState.queued),
          ],
        ),
      ));

  testWidgets('06 share ready', (t) => _pump(
        t,
        const ShareReadyScreen(),
        name: '06-share-ready',
        overrides: repoOverride,
        draft: ShareDraftState(
          title: 'Brand guidelines',
          phase: UploadPhase.done,
          files: const [
            SharedFile(id: '1', name: 'brand-guidelines-final.pdf', sizeBytes: 8400000, state: FileUploadState.ready, bytesSent: 8400000),
          ],
          share: Share(
            id: 's1', slug: 'kx7m2qpd91vn',
            title: 'Brand guidelines',
            status: ShareStatus.active,
            createdAt: DateTime(2026, 10, 12, 9, 14),
            expiresAt: DateTime(2026, 10, 19, 9, 14),
            fileCount: 1, totalBytes: 8400000, downloadCount: 0,
          ),
        ),
      ));

  testWidgets('07 my shares', (t) =>
      _pump(t, const MySharesScreen(), name: '07-my-shares', overrides: repoOverride));

  testWidgets('08 transfers', (t) =>
      _pump(t, const TransfersScreen(), name: '08-transfers', overrides: repoOverride));

  testWidgets('09 vault', (t) => _pump(t, const VaultScreen(), name: '09-vault'));

  testWidgets('10 settings', (t) =>
      _pump(t, const SettingsScreen(), name: '10-settings'));

  testWidgets('11 receive page', (t) =>
      _pump(t, const ReceiveScreen(slug: 'kx7m2qpd91vn'), name: '11-receive', overrides: repoOverride));

  testWidgets('12 home light', (t) =>
      _pump(t, const HomeScreen(), name: '12-home-light', mode: ThemeMode.light, overrides: repoOverride));

  testWidgets('13 home light shares', (t) =>
      _pump(t, const MySharesScreen(), name: '13-shares-light', mode: ThemeMode.light, overrides: repoOverride));
}