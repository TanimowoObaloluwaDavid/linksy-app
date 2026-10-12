<div align="center">

<img src="web/icons/Icon-192.png" width="88" alt="Linksy icon" />

# Linksy

**Send a file. Get a link.**

Select files, create a secure share, and let another person open it through a
link or QR code — without installing anything or making an account.

[![CI](https://github.com/TanimowoObaloluwaDavid/linksy-app/actions/workflows/ci.yml/badge.svg)](https://github.com/TanimowoObaloluwaDavid/linksy-app/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.6-02569A?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.4-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-1F6FEB.svg)](LICENSE)

</div>

---

## The idea

Most file-sharing apps make the *recipient* do the work: install something,
create an account, learn where the file went. Linksy inverts that. The person
sending picks files and gets a link; the person receiving opens it in a browser
that already exists.

Everything else in the product follows from that one decision — including the
honest limitation, which is stated in the UI rather than buried: revoking a link
stops *future* downloads, but cannot erase a copy someone already saved.

<p align="center">
  <img src="screenshots/03-home.png" width="190" alt="Home screen" />
  <img src="screenshots/04-pick-files.png" width="190" alt="Select files" />
  <img src="screenshots/05-upload.png" width="190" alt="Upload progress" />
  <img src="screenshots/06-share-ready.png" width="190" alt="Share ready with QR code" />
</p>
<p align="center"><sub><b>Home</b> · <b>Select</b> · <b>Upload</b> · <b>Share ready</b></sub></p>

---

## Status

This is a **Phase 1–2 foundation**. The interface is complete and real; the
backend is not. Read this table before assuming anything works end to end.

| | Area | State |
|:--|:--|:--|
| ✅ | Design system, theming, typography | Real — light and dark, no hardcoded colours |
| ✅ | Navigation graph, routing, auth guards | Real — `go_router` with deep links |
| ✅ | All 13 screens in PRD §8 | Real — including empty, loading, error and closed states |
| ✅ | Upload state machine | Real — progress, cancel, per-file retry, resume |
| ✅ | QR generation | Real — genuinely scannable output |
| ✅ | QR scanning | Real — with manual-link fallback when the camera is blocked |
| ⚠️ | Persistence (shares, auth, files) | **Stubbed** — in-memory repositories |
| ❌ | Firebase Auth / Firestore / Storage | Not wired — no project configured |
| ❌ | Subscriptions & payments | Not implemented — UI only |
| ❌ | Nearby device-to-device transfer | Out of MVP scope (see PRD §11) |

### The stub boundary

This is the part that matters for anyone extending the code. Repositories are
declared as interfaces in the domain layer:

```dart
abstract interface class ShareRepository { … }   // lib/features/sharing/domain/share_repository.dart
abstract interface class AuthRepository   { … }   // lib/features/auth/presentation/auth_controller.dart
```

The only implementations are `InMemoryShareRepository` and `LocalAuthRepository`,
both labelled `DEVELOPMENT STUB`. No widget or notifier imports a data source
directly, so going live is:

1. Write `HttpShareRepository implements ShareRepository`.
2. Write `FirebaseAuthRepository implements AuthRepository`.
3. Change two `Provider` definitions.

**Nothing in `presentation/` moves.** That is the whole point of the boundary.

One thing the stub must never become: the authority on whether a share is valid.
`finalize()` already refuses to publish unless every file reached `ready` — but in
production that check belongs in Cloud Functions, not on the client.

---

## Quick start

```sh
git clone https://github.com/TanimowoObaloluwaDavid/linksy-app.git
cd linksy-app
flutter pub get
flutter run
```

Requires **Flutter 3.41.6** / **Dart 3.11.4**. No backend, API keys or `.env` file
is needed to run it.

<details>
<summary>Platform setup before QR scanning will work</summary>

`mobile_scanner` needs camera permission. Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Linksy uses the camera to scan share QR codes.</string>
```

And to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

The scanner degrades gracefully without them — the manual-link field is always
present, per PRD §8.8.

</details>

### Verification

```sh
flutter analyze                                             # 0 issues
flutter test                                                # 8 unit + widget
flutter test test/screenshot_harness.dart --update-goldens  # 13 screens
flutter test test/generate_icons.dart --update-goldens      # 25 icons
```

| Check | Result |
|:--|:--|
| `flutter analyze` | **No issues found** |
| Unit & widget tests | **8/8** |
| Screen render | **13/13** |
| Icon generation | **4/4** |
| `flutter build web --release` | **passing** |

---

## Design system

The full system lives in `lib/core/theme/` and `lib/core/widgets/`.

### Colour is semantic, not decorative

| Colour | Means | Used for |
|:--|:--|:--|
| Violet `#7C5CFC` | the sender's **intent** | primary actions, the mark, user choices |
| Cyan `#39D5FF` | data **in transit** | live progress, scanning, anything moving |
| Green `#35C98A` | **complete** | verified, ready, live |
| Amber `#F5B544` | **attention** | warnings, interrupted transfers |
| Red `#F06464` | **error** | failed, expired, revoked |

Each hue means exactly one thing, so neither accent is ever used as a decorative
wash. That is specifically what keeps a violet-on-near-black palette — the most
templated combination in dark apps — from collapsing into the usual
purple-gradient look.

Light theme is **authored, not inverted.** Dark surfaces get their own tuned
tones; flipping light values produces crushed greys and dead borders.

<p align="center">
  <img src="screenshots/12-home-light.png" width="190" alt="Home in light theme" />
  <img src="screenshots/13-shares-light.png" width="190" alt="My Shares in light theme" />
  <img src="screenshots/11-receive.png" width="190" alt="Recipient share page" />
</p>
<p align="center"><sub><b>Home</b> and <b>My Shares</b> in light theme · <b>Recipient page</b>, which needs no account</sub></p>

### Typography

| Family | Job |
|:--|:--|
| **Space Grotesk** | display and headings — technical, angular, brand |
| **Inter** | all UI and body copy |
| **JetBrains Mono** | filenames, byte counts, share slugs, URLs, checksums |

The mono face is not decoration. A filename, a file size and a share slug are
literal machine values, so they get a literal machine face — which also makes
columns of metadata align in a way a proportional face cannot.

All three are bundled as OFL 1.1 TTFs, so the app renders identically offline.
Licences in [`assets/fonts/LICENSES.md`](assets/fonts/LICENSES.md).

### The signature element: `TransferRail`

`lib/core/painters/transfer_rail.dart`

A transfer is data physically moving between two devices, so the app shows that
movement as a literal rail — nodes for *select → upload → link → done*, a filled
track for what finished, and a travelling cyan packet for what is happening now.
It is the product's state machine drawn, not decoration laid over it, and it is
the one thing that makes the app recognisable.

It respects reduced-motion: the packet stops travelling and holds position.

### The hero moment

`ShareReadyScreen` reveals the QR code behind a sweeping mask. Getting that code
onto the other person's phone is the reason the user came, so it gets the
strongest moment in the app. The code renders pure-black-on-white so it scans
under any camera, in any lighting.

### Accessibility

- **State is never colour alone** — every status badge carries an icon *and* a
  word; file-type chips carry a monogram (`IMG`, `PDF`, `XLS`).
- 52px minimum touch target, above the 48dp floor.
- Text scaling honoured 0.9×–1.4×; the clamp stops fixed-height controls clipping.
- Every icon-only button carries a tooltip and a semantic label.
- Long filenames ellipsize **in the middle**, because the extension carries the
  file's identity and shouldn't be the part that gets cut.

---

## Architecture

Feature-first, three layers per feature:

```
lib/
  app/            router, theme wiring, preferences
  core/
    painters/     transfer_rail.dart
    theme/        tokens, typography, light + dark themes
    utils/        formatters, file-kind visual language
    widgets/      buttons, cards, badges, states, brand mark
  features/
    auth/         domain  presentation/
    home/         presentation/
    sharing/      domain  data/  presentation/
    transfers/    domain  presentation/
    vault/        presentation/
    qr/           presentation/
    receiving/    presentation/
    settings/     presentation/
  main.dart
```

**Rules the codebase holds to:**

- Widgets render and dispatch. They do not call HTTP, storage or policy.
- Notifiers own state transitions. They do not build HTTP clients.
- Repositories orchestrate. They do not touch `BuildContext`.
- Domain is **pure Dart** — no Flutter imports. Enforced, not aspirational:
  `FileUploadState` carries a `label` but no `IconData`, and the icon mapping
  lives in `core/widgets/status_badge.dart` as an extension.
- Dependencies are injected through providers, never constructed inline.

### Decisions worth explaining

**Why hand-written models instead of `freezed`?** The PRD says freezed "if
adopted", so this was a deliberate call. `build_runner` adds a build step and a
class of version-mismatch failures for no runtime gain; zero generated files means
a clean checkout compiles immediately; and the domain is small and explicit
(`Share`, `SharedFile`, `Transfer`, `VaultItem`, `AccessPolicy`, `Expiry`,
`AppUser`). Swapping later is mechanical and touches only the domain layer.

**Why Riverpod 2.6.1 and not 3.x?** 3.x is the current recommendation but needs a
newer SDK than this project's pinned toolchain resolves. The API used here
(`NotifierProvider`, `Notifier`, `ref.watch`) is forward-compatible, so upgrading
is a version bump plus regenerating notifier signatures — no screen changes.

**Why is the upload state not auto-disposed?** PRD §6.5 requires an upload to
keep running coherently when the user navigates away, so that state must outlive
the screen that started it. It surfaces on the Home dashboard while running.

**`LsScaffold` owns one scrolling contract.** Screens pass a plain widget; the
scaffold supplies the scroll view and pins `bottomBar` below it. Passing a
`ListView` into it will throw during layout. *(This bit the project once — the
screenshot harness caught it.)*

**Typography accessors.** `TextTheme` exposes role slots (`headlineMedium`,
`titleLarge`, …) that can't distinguish *machine value* from *prose*. An extension
in `app_typography.dart` adds `t.heading`, `t.subheading`, `t.bodyStrong`,
`t.caption`, `t.monoValue` and friends, so call sites read like design intent
instead of leaking M3 slot names into every screen.

---

## Screenshots

Thirteen screens at 430×932, produced by `test/screenshot_harness.dart`.

| | | |
|:--|:--|:--|
| <img src="screenshots/01-welcome.png" alt="Welcome"> | <img src="screenshots/02-signin.png" alt="Sign in"> | <img src="screenshots/07-my-shares.png" alt="My Shares"> |
| Welcome | Sign in | My Shares |
| <img src="screenshots/08-transfers.png" alt="Transfers"> | <img src="screenshots/09-vault.png" alt="Vault"> | <img src="screenshots/10-settings.png" alt="Settings"> |
| Transfers | Vault | Settings |

<details>
<summary>Why the harness is more than a screenshot tool</summary>

It loads the real bundled typefaces and MaterialIcons before rendering. Without
that, `flutter test` draws every glyph as an Ahem box — uniform width, far wider
than real text — which makes the images useless *and* reports false `RenderFlex`
overflows.

It earned its keep on the first run by surfacing a sign-in row overflowing by
61px on a 430pt-wide screen. That was a genuine responsive bug, and it is fixed.

Capture goes through `matchesGoldenFile` with `--update-goldens` rather than
`RenderRepaintBoundary.toImage()`, which stalls in the headless rasteriser.

These are **captures, not golden assertions** — font rasterisation differs per
machine, so a byte comparison would fail spuriously. Visual regressions are caught
by eye and by CI layout errors, not by pixel diffing.

</details>

---

## App icon

<img src="screenshots/00-app-icon.png" width="620" alt="Icon at five sizes" />

Two interlocking arcs — the two parties — with a cyan packet travelling between
them.

`test/generate_icons.dart` renders the **same `CustomPainter` the app bar uses**
into all 5 Android mipmaps, all 15 iOS AppIcon sizes and the 5 web icons, so the
launcher icon and the in-app mark cannot drift apart. Maskable variants render
the mark at ~60% on a full-bleed plate, because those platforms crop up to 20%
from every edge.

---

## Known gaps

Deliberate, and listed rather than implied away:

- **No backend.** Everything persists in memory; a restart loses shares.
- **Payments and plans** are UI only — "Upgrade to Pro" shows a notice.
- **Privacy policy and terms** screens are stubs. Required for launch, not written.
- **Nearby transfer** (PRD §11 phases 2–3) is not implemented. The PRD is right
  that Flutter cannot provide it cross-platform; no amount of UI changes that.
- **No golden image diffing.** CI catches layout errors, not visual drift.
- **Camera permissions** are not committed — configure them alongside the real
  Firebase project (see Quick start).

---

## Licence

MIT — see [LICENSE](LICENSE). Bundled fonts are OFL 1.1; see
[`assets/fonts/LICENSES.md`](assets/fonts/LICENSES.md).

Built from the Linksy PRD (v1.0).