import 'package:flutter/material.dart';

/// Design tokens for Linksy.
///
/// ## Colour semantics
///
/// The palette is deliberately *semantic*, not decorative. Two accent hues carry
/// fixed meanings so the interface never has to explain itself:
///
/// * **Violet (`intent`)** — the sender's agency. Primary actions, the brand
///   mark, things the user chose.
/// * **Cyan (`inTransit`)** — data physically moving. Upload progress, scanning,
///   anything live.
///
/// Because violet and cyan each mean one thing, neither is ever used as a
/// generic decorative wash. That is what keeps this palette from collapsing
/// into the usual purple-gradient look.
abstract final class AppColors {
  // ---- Canvas & surfaces (dark, the default theme) ----
  static const canvas = Color(0xFF0B0D12);
  static const surface = Color(0xFF151923);
  static const surfaceRaised = Color(0xFF1C2130);
  static const surfaceHigh = Color(0xFF242A3A);
  static const hairline = Color(0xFF2B3244);
  static const hairlineStrong = Color(0xFF3A4358);

  // ---- Canvas & surfaces (light) ----
  static const canvasLight = Color(0xFFF7F8FB);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceRaisedLight = Color(0xFFF0F2F7);
  static const surfaceHighLight = Color(0xFFE6EAF2);
  static const hairlineLight = Color(0xFFDDE2EC);
  static const hairlineStrongLight = Color(0xFFC3CBD9);

  // ---- Brand: intent (sender agency) ----
  static const violet = Color(0xFF7C5CFC);
  static const violetDeep = Color(0xFF5B44CC);
  static const violetLift = Color(0xFF9B84FF);
  static const violetInk = Color(0xFF2B1F6B); // violet that passes AA on light
  static const violetSoft = Color(0x1A7C5CFC);

  // ---- In transit: data movement ----
  static const cyan = Color(0xFF39D5FF);
  static const cyanDeep = Color(0xFF12A8D6);
  static const cyanSoft = Color(0x1A39D5FF);

  // ---- Text ----
  static const text = Color(0xFFF5F7FB);
  static const textMuted = Color(0xFF969EAE);
  static const textFaint = Color(0xFF636B7C);

  static const textInk = Color(0xFF0E1016); // on light
  static const textMutedInk = Color(0xFF525A6B);
  static const textFaintInk = Color(0xFF7E8798);

  // ---- Semantic ----
  static const success = Color(0xFF35C98A);
  static const successInk = Color(0xFF106B47);
  static const successSoft = Color(0x1A35C98A);

  static const error = Color(0xFFF06464);
  static const errorInk = Color(0xFFA32727);
  static const errorSoft = Color(0x1AF06464);

  static const warning = Color(0xFFF5B544);
  static const warningInk = Color(0xFF8A5A08);
  static const warningSoft = Color(0x1AF5B544);

  static const info = Color(0xFF7AA2F7);
  static const infoSoft = Color(0x1A7AA2F7);
}

/// 4pt spacing scale. Use these instead of raw numbers so rhythm stays even.
abstract final class Insets {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double giant = 48;

  /// Horizontal page gutter.
  static const double gutter = 20;
}

/// Corner radii. Two families only: `r` for controls, `rLg` for containers.
abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
  static const double pill = 999;
}

/// Motion tokens. Durations follow the Material 3 easing/duration scale and
/// springs are used for anything the finger is driving.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration deliberate = Duration(milliseconds: 650);

  /// Emphasized decelerate — the M3 curve for entering elements.
  static const Curve enter = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve exit = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);
}

/// Elevation. Subtle on purpose — depth comes from surface tone and hairlines,
/// not from heavy shadows.
abstract final class Elev {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> low = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> glow = [
    BoxShadow(color: Color(0x407C5CFC), blurRadius: 28, spreadRadius: -4),
  ];
}