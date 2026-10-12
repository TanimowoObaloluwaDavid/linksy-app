import 'package:flutter/material.dart';

/// Convenience accessors over [TextTheme].
///
/// Material's scale is organised by role and cannot express the two distinctions
/// this product actually cares about: *machine value* vs *prose*, and *display*
/// vs *heading*. These aliases keep call sites reading like design intent
/// instead of leaking M3 slot names into every screen.
extension LsTextTheme on TextTheme {
  /// Prose running at body size.
  TextStyle get body => bodyMedium!;

  /// Body copy that is a label or a row title — still prose, but emphasised.
  TextStyle get bodyStrong => titleMedium!;

  /// Small explanatory text under a control or beside a value.
  TextStyle get caption => bodySmall!;

  /// Section or card heading.
  TextStyle get heading => headlineMedium!;

  /// Title inside a card or list row.
  TextStyle get subheading => titleLarge!;

  /// A literal machine value: a filename, size, slug or URL.
  TextStyle get monoValue => AppType.monoValue;

  TextStyle get monoSmall => AppType.monoSmall;

  TextStyle get monoTiny => AppType.monoTiny;
}

/// Linksy type scale.
///
/// Three families, each with a job:
/// * **Space Grotesk** — display and headings. Technical, slightly angular,
///   confident. Used sparingly at large sizes where it reads as brand.
/// * **Inter** — all UI and body copy. High x-height, excellent at small sizes.
/// * **JetBrains Mono** — filenames, byte counts, share IDs, checksums, URLs.
///   These are literal machine values, so they get a literal machine face.
abstract final class AppType {
  static const display = 'SpaceGrotesk';
  static const sans = 'Inter';
  static const mono = 'JetBrainsMono';

  // ---- Display (Space Grotesk) ----
  static const hero = TextStyle(
    fontFamily: display,
    fontSize: 40,
    height: 1.04,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
  );

  static const title = TextStyle(
    fontFamily: display,
    fontSize: 28,
    height: 1.12,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
  );

  static const heading = TextStyle(
    fontFamily: display,
    fontSize: 21,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );

  static const subheading = TextStyle(
    fontFamily: display,
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  // ---- Body (Inter) ----
  static const body = TextStyle(
    fontFamily: sans,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const bodyStrong = TextStyle(
    fontFamily: sans,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );

  static const bodySmall = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const caption = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  /// All-caps micro label used for section eyebrows and status chips.
  static const overline = TextStyle(
    fontFamily: sans,
    fontSize: 10.5,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
  );

  // ---- Technical (JetBrains Mono) ----
  /// A real filename, byte count, share slug or URL.
  static const monoValue = TextStyle(
    fontFamily: mono,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static const monoSmall = TextStyle(
    fontFamily: mono,
    fontSize: 11.5,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const monoTiny = TextStyle(
    fontFamily: mono,
    fontSize: 10,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );

  static const monoLarge = TextStyle(
    fontFamily: mono,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
  );
}