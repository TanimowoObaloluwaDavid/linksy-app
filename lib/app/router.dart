import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/sign_in_screen.dart';
import '../features/home/presentation/splash_screen.dart';
import '../features/home/presentation/welcome_screen.dart';
import '../features/qr/presentation/qr_scanner_screen.dart';
import '../features/receiving/presentation/receive_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/sharing/presentation/configure_share_screen.dart';
import '../features/sharing/presentation/my_shares_screen.dart';
import '../features/sharing/presentation/pick_files_screen.dart';
import '../features/sharing/presentation/share_ready_screen.dart';
import '../features/sharing/presentation/upload_screen.dart';
import '../features/transfers/presentation/transfers_screen.dart';
import '../features/vault/presentation/vault_screen.dart';

abstract final class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const signIn = '/signin';

  static const home = '/home';
  static const transfers = '/transfers';
  static const shares = '/shares';
  static const vault = '/vault';

  static const pick = '/send/pick';
  static const configure = '/send/configure';
  static const upload = '/send/upload';
  static const ready = '/send/ready';

  static const scan = '/scan';
  static const settings = '/settings';

  static String receive(String slug) => '/receive/$slug';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeKey = GlobalKey<NavigatorState>(debugLabel: 'tab:home');
final _transfersKey = GlobalKey<NavigatorState>(debugLabel: 'tab:transfers');
final _sharesKey = GlobalKey<NavigatorState>(debugLabel: 'tab:shares');
final _vaultKey = GlobalKey<NavigatorState>(debugLabel: 'tab:vault');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,

    // Re-evaluate redirects whenever the session changes, so an expiring
    // session bounces the user out of protected routes automatically.
    refreshListenable: _AuthRefresh(ref),

    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final at = state.matchedLocation;

      // Hold on the splash while a stored session is being restored, otherwise
      // a signed-in user sees the welcome screen flash on every cold start.
      if (auth.status == AuthStatus.loading) {
        return at == Routes.splash ? null : Routes.splash;
      }

      const publicRoutes = {Routes.welcome, Routes.signIn, Routes.splash};
      final signedIn = auth.isSignedIn;

      // A share page is reachable without an account (PRD §6.6) — the whole
      // point is that the recipient never has to register.
      final isReceive = at.startsWith('/receive/');

      if (!signedIn) {
        if (publicRoutes.contains(at) || isReceive) return null;
        return Routes.welcome;
      }
      if (at == Routes.welcome || at == Routes.signIn || at == Routes.splash) {
        return Routes.home;
      }
      return null;
    },

    routes: [
      GoRoute(
        path: Routes.splash,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.welcome,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.signIn,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SignInScreen(),
      ),

      // ------------------------------------------------ four-tab workspace
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => WorkspaceShell(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeKey,
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, __) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'send',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const PickFilesScreen(),
                    routes: [
                      GoRoute(
                        path: 'configure',
                        parentNavigatorKey: _rootKey,
                        builder: (_, __) => const ConfigureShareScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _transfersKey,
            routes: [
              GoRoute(
                path: Routes.transfers,
                builder: (_, __) => const TransfersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _sharesKey,
            routes: [
              GoRoute(
                path: Routes.shares,
                builder: (_, __) => const MySharesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _vaultKey,
            routes: [
              GoRoute(
                path: Routes.vault,
                builder: (_, __) => const VaultScreen(),
              ),
            ],
          ),
        ],
      ),

      // ------------------------------------------------ full-screen flows
      GoRoute(
        path: Routes.upload,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const UploadScreen(),
      ),
      GoRoute(
        path: Routes.ready,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ShareReadyScreen(),
      ),
      GoRoute(
        path: Routes.scan,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const QrScannerScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/receive/:slug',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ReceiveScreen(slug: state.pathParameters['slug']!),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

/// Bridges Riverpod auth changes into go_router's `refreshListenable`.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    _sub = ref.listen<AuthState>(
      authProvider,
      (previous, next) => notifyListeners(),
      fireImmediately: false,
    );
  }

  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

/// Bottom-tab shell for the four primary destinations (PRD §7).
class WorkspaceShell extends StatelessWidget {
  const WorkspaceShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (icon: Icons.add_circle_outline_rounded, active: Icons.add_circle_rounded, label: 'Send'),
    (icon: Icons.swap_vert_rounded, active: Icons.swap_vert_rounded, label: 'Transfers'),
    (icon: Icons.link_rounded, active: Icons.link_rounded, label: 'My Shares'),
    (icon: Icons.bookmark_border_rounded, active: Icons.bookmark_rounded, label: 'Vault'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _TabButton(
                      tab: _tabs[i],
                      selected: shell.currentIndex == i,
                      // Tapping the active tab returns it to its root — the
                      // standard mobile convention.
                      onTap: () => shell.goBranch(
                        i,
                        initialLocation: i == shell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, IconData active, String label}) tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.06 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Icon(selected ? tab.active : tab.icon, size: 23, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                height: 1.1,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}