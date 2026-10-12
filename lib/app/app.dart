import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/tokens.dart';
import 'preferences.dart';
import 'router.dart';

class LinksyApp extends ConsumerWidget {
  const LinksyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    return MaterialApp.router(
      title: 'Linksy',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,

      // Text scaling is honoured up to a point. Beyond ~1.4 the fixed-height
      // rails and segmented controls start to clip, so the ceiling keeps the
      // layout intact while still supporting a meaningful range.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final clamped = mq.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.35,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: clamped),
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Page shell used by every screen so gutters, safe areas and back behaviour
/// behave identically everywhere.
class LsScaffold extends StatelessWidget {
  const LsScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.bottomBar,
    this.floating,
    this.showBack = true,
    this.padded = true,
    this.background,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottomBar;
  final Widget? floating;
  final bool showBack;
  /// Whether the body receives the standard horizontal page gutter.
  final bool padded;
  final Color? background;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasBar = title != null || actions != null || showBack;

    final content = Column(
      children: [
        Expanded(
          // `body` is a plain widget, not a scroll view. Wrapping it here keeps
          // one scrolling contract for every screen. (Wrapping it in a
          // `SliverToBoxAdapter` inside a `CustomScrollView` instead gives the
          // child an unbounded height and throws during layout.)
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: Insets.sm),
            child: padded
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Insets.gutter),
                    child: body,
                  )
                : body,
          ),
        ),
        if (bottomBar != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.gutter,
                Insets.md,
                Insets.gutter,
                Insets.md,
              ),
              child: bottomBar,
            ),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: background ?? scheme.surface,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: hasBar
          ? AppBar(
              title: title == null ? null : Text(title!),
              automaticallyImplyLeading: false,
              leading: showBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      tooltip: 'Back',
                    )
                  : null,
              actions: actions,
            )
          : null,
      body: content,
      floatingActionButton: floating,
    );
  }
}