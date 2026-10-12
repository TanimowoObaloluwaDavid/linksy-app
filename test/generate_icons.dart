// Generates the real app icon for every platform from the painted BrandMark.
//
//     flutter test test/generate_icons.dart --update-goldens
//
// Why a generator instead of a hand-made PNG set: the mark is a `CustomPainter`,
// not an asset, so the only way to keep the launcher icon identical to the
// in-app mark is to render the painter at each size the platform requires.
//
// Overwrites (in place) files that Flutter's template ships as default logos:
//   android/app/src/main/res/mipmap-*/ic_launcher.png
//   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png
//   web/favicon.png, web/icons/Icon-*.png
//
// Maskable variants render the mark at ~60% on a full-bleed plate, because
// those platforms may crop up to 20% from every edge.
//
// Capturing goes through `matchesGoldenFile` with `--update-goldens` rather than
// `RenderRepaintBoundary.toImage()`, which stalls in the headless rasteriser.
// Golden paths are relative to this file, hence the leading `../`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linksy/core/theme/tokens.dart';
import 'package:linksy/core/widgets/brand.dart';

/// Paints the plate + mark without depending on a Theme, so the icon is stable
/// regardless of the test's light/dark mode.
Widget _plate(double px, {required bool maskable}) {
  if (!maskable) return BrandMark(size: px, fullBleed: true);
  return Container(
    width: px,
    height: px,
    color: AppColors.violetDeep,
    alignment: Alignment.center,
    child: Padding(
      padding: EdgeInsets.all(px * 0.16),
      child: BrandMark(size: px * 0.68, fullBleed: true),
    ),
  );
}

Future<void> _write(
  WidgetTester tester,
  int px,
  String path, {
  required bool maskable,
}) async {
  tester.view.physicalSize = Size(px.toDouble(), px.toDouble());
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: SizedBox.square(
          dimension: px.toDouble(),
          child: _plate(px.toDouble(), maskable: maskable),
        ),
      ),
    ),
  );
  await tester.pump();

  await expectLater(
    find.byKey(key),
    matchesGoldenFile('../$path'),
  );
}

void main() {
  // Android launcher icons. The template ships no adaptive-icon XML, so
  // ic_launcher.png is the entire icon and must be full-bleed.
  const android = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  // iOS AppIcon set — filenames and pixel sizes are fixed by the template.
  const ios = {
    'Icon-App-20x20@1x': 20,
    'Icon-App-20x20@2x': 40,
    'Icon-App-20x20@3x': 60,
    'Icon-App-29x29@1x': 29,
    'Icon-App-29x29@2x': 58,
    'Icon-App-29x29@3x': 87,
    'Icon-App-40x40@1x': 40,
    'Icon-App-40x40@2x': 80,
    'Icon-App-40x40@3x': 120,
    'Icon-App-60x60@2x': 120,
    'Icon-App-60x60@3x': 180,
    'Icon-App-76x76@1x': 76,
    'Icon-App-76x76@2x': 152,
    'Icon-App-83.5x83.5@2x': 167,
    'Icon-App-1024x1024@1x': 1024,
  };

  const web = {
    'web/favicon.png': 48,
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
  };

  testWidgets('android launcher icons', (t) async {
    for (final e in android.entries) {
      await _write(t, e.value,
          'android/app/src/main/res/${e.key}/ic_launcher.png',
          maskable: false);
    }
  });

  testWidgets('ios app icon set', (t) async {
    for (final e in ios.entries) {
      await _write(
        t,
        e.value,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/${e.key}.png',
        maskable: false,
      );
    }
  });

  testWidgets('web icons', (t) async {
    for (final e in web.entries) {
      await _write(t, e.value, e.key, maskable: e.key.contains('maskable'));
    }
  });

  testWidgets('app icon preview sheet', (t) async {
    const sizes = [160.0, 96.0, 64.0, 48.0, 32.0];
    t.view.physicalSize = const Size(760, 220);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final key = GlobalKey();
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: AppColors.canvas,
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (final s in sizes)
                  BrandMark(size: s, fullBleed: true),
              ],
            ),
          ),
        ),
      ),
    );
    await t.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('../screenshots/00-app-icon.png'),
    );
  });
}