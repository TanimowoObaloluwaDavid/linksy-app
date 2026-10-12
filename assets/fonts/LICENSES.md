Third-party assets bundled with Linksy
======================================

Fonts
-----

All three families are licensed under the SIL Open Font License 1.1, which
permits bundling and redistribution in an application, including commercial
use. No separate attribution is required in the UI, but the licences are
reproduced below for completeness.

1. Space Grotesk
   Copyright (c) 2020 Florian Karsten
   SIL Open Font License 1.1
   https://github.com/floriankarsten/space-grotesk

2. Inter
   Copyright (c) 2016 The Inter Project Authors
   SIL Open Font License 1.1
   https://github.com/rsms/inter

3. JetBrains Mono
   Copyright (c) 2020 The JetBrains Mono Project Authors
   SIL Open Font License 1.1
   https://github.com/JetBrains/JetBrainsMono

  Files used (subset — only the weights the design system consumes):
    SpaceGrotesk-Medium.ttf    (500)
    SpaceGrotesk-SemiBold.ttf  (600)
    SpaceGrotesk-Bold.ttf      (700)
    Inter-Regular.ttf          (400)
    Inter-Medium.ttf           (500)
    Inter-SemiBold.ttf         (600)
    Inter-Bold.ttf             (700)
    JetBrainsMono-Regular.ttf  (400)
    JetBrainsMono-Medium.ttf   (500)
    JetBrainsMono-Bold.ttf     (700)

  Italic and unused weights were deliberately not bundled to keep the app
  binary small.

Icons
-----

Material Symbols / Material Icons, provided by the Flutter SDK under the
Apache License 2.0. These are used for functional interface affordances only;
the Linksy brand mark and the transfer rail are drawn with `CustomPainter` in
`lib/core/widgets/brand.dart` and `lib/core/painters/transfer_rail.dart`.

Third-party packages
--------------------

Declared in `pubspec.yaml`. Each retains its own licence; run `flutter pub deps`
to list them. Notable ones:

  flutter, flutter_riverpod, go_router, equatable, shared_preferences,
  file_picker, qr_flutter, mobile_scanner, share_plus, url_launcher,
  flutter_animate

No artwork, photography or stock imagery is bundled. Every graphic in the app
is drawn in code or set in type.