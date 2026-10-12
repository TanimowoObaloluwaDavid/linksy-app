import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/ls_button.dart';
import '../../auth/presentation/auth_controller.dart';

/// Sign in / register (PRD §6.1).
///
/// One screen with a mode toggle rather than two routes: the fields overlap
/// almost entirely, and a single surface means a returning user never has to
/// hunt for the right one.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _register = true;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final c = ref.read(authProvider.notifier);
      if (_register) {
        await c.register(_email.text, _password.text, _name.text);
      } else {
        await c.signIn(_email.text, _password.text);
      }
      // On success the router's redirect takes over; nothing to navigate here.
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Insets.gutter,
              0,
              Insets.gutter,
              Insets.xxxl,
            ),
            children: [
              const BrandLockup(markSize: 32),
              const SizedBox(height: Insets.xxxl),
              Text(_register ? 'Create your account' : 'Welcome back',
                  style: t.headlineLarge),
              const SizedBox(height: Insets.sm),
              Text(
                _register
                    ? 'You only need this to manage your own shares. '
                        'Anyone you send a link to never needs an account.'
                    : 'Sign in to manage your shares and reach your vault.',
                style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: Insets.xxxl),

              if (_register) ...[
                _Field(
                  controller: _name,
                  label: 'Display name',
                  hint: 'How your name appears on a share',
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'A display name is required'
                      : null,
                ),
                const SizedBox(height: Insets.lg),
              ],

              _Field(
                controller: _email,
                label: 'Email',
                hint: 'you@example.com',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return 'Email is required';
                  if (!s.contains('@') || !s.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Insets.lg),

              _Field(
                controller: _password,
                label: 'Password',
                hint: _register ? 'At least 8 characters' : '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 19,
                    color: scheme.onSurfaceVariant,
                  ),
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) {
                  final s = v ?? '';
                  if (s.isEmpty) return 'Password is required';
                  if (_register && s.length < 8) {
                    return 'Use at least 8 characters';
                  }
                  return null;
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: Insets.lg),
                _ErrorBanner(message: _error!),
              ],

              const SizedBox(height: Insets.xxl),
              LsButton(
                label: _register ? 'Create account' : 'Sign in',
                onPressed: _submit,
                busy: _busy,
                expand: true,
              ),
              const SizedBox(height: Insets.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _register ? 'Already have an account?' : 'New to Linksy?',
                      textAlign: TextAlign.end,
                      style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _register = !_register;
                      _error = null;
                    }),
                    child: Text(_register ? 'Sign in' : 'Create one'),
                  ),
                ],
              ),

              // PRD §6.1 — the receiving side never needs an account, so say so
              // explicitly rather than leaving it as a discovery.
              const SizedBox(height: Insets.lg),
              Container(
                padding: const EdgeInsets.all(Insets.lg),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: Insets.md),
                    Expanded(
                      child: Text(
                        'Opening someone else’s link? You don’t need an account — '
                        'that screen works in any browser.',
                        style: t.caption.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      autocorrect: false,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 19),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        suffixIcon: suffix,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.45,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}