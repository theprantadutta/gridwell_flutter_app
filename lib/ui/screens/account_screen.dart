import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/account.dart';
import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';

/// Settings > Account, and where the "keep your progress" offer leads.
/// Guests choose Google or email; signed-in players see who they are and can
/// sign out. Playing without an account is always fine.
// TODO(mac): add "Continue with Apple" on iOS (docs/MAC_CHECKLIST.md).
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final account = ref.watch(accountProvider).value ?? Account.guest;

    return Scaffold(
      body: FolioBody(
        child: Stack(children: [
          Column(children: [
            const FolioHeader(leading: 'Back', center: 'Account'),
            Expanded(
              child: FolioCenteredPage(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: account.isGuest ? _guest(context, p) : _signedIn(context, p, account),
                ),
              ),
            ),
          ]),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: p.surface.withValues(alpha: 0.6),
                child: Center(child: CircularProgressIndicator(color: p.textPrimary, strokeWidth: 2)),
              ),
            ),
        ]),
      ),
    );
  }

  List<Widget> _guest(BuildContext context, GridwellPalette p) => [
        Text('YOUR PROGRESS', style: FolioType.kicker(p)),
        const SizedBox(height: 8),
        Text('Keep your book safe', style: FolioType.display(p)),
        const SizedBox(height: 14),
        Text(
          'Sign in to keep your solved plates and best times if you change or lose your phone, '
          'and to pick up where you left off on another device.',
          style: FolioType.body(p, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          'You can keep playing without an account. Nothing changes, and you can sign in later in Settings.',
          style: FolioType.bodyMuted(p, size: 16),
        ),
        const SizedBox(height: 28),
        InkButton(label: 'Continue with Google', onPressed: _busy ? null : _google, height: 60),
        const SizedBox(height: 12),
        OutlineButtonFolio(label: 'Continue with email', onPressed: _busy ? null : _email),
        const SizedBox(height: 8),
        Center(child: TextAction(label: 'Not now', onPressed: _notNow)),
        const SizedBox(height: 16),
        const Hairline(),
        const SizedBox(height: 14),
        Wrap(children: [
          Text('By signing in you agree to the ', style: FolioType.bodyMuted(p, size: 14)),
          _link(p, 'Terms of Use', '/legal/terms'),
          Text(' and the ', style: FolioType.bodyMuted(p, size: 14)),
          _link(p, 'Privacy Policy', '/legal/privacy'),
          Text('.', style: FolioType.bodyMuted(p, size: 14)),
        ]),
      ];

  List<Widget> _signedIn(BuildContext context, GridwellPalette p, Account account) {
    final via = switch (account.kind) {
      AccountKind.google => 'Google',
      AccountKind.apple => 'Apple',
      _ => 'email',
    };
    return [
      Text('SIGNED IN WITH ${via.toUpperCase()}', style: FolioType.kicker(p)),
      const SizedBox(height: 8),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(account.email ?? 'Your account', maxLines: 1, style: FolioType.plateTitle(p, size: 30)),
      ),
      const SizedBox(height: 14),
      Text(
        'Your solved plates and best times are saved to your account. '
        'Sign in on another device to carry on there.',
        style: FolioType.body(p, size: 18),
      ),
      if (account.kind == AccountKind.email && !account.emailVerified) ...[
        const SizedBox(height: 10),
        Text('We sent you an email to confirm your address.', style: FolioType.bodyMuted(p, size: 15)),
      ],
      const SizedBox(height: 28),
      OutlineButtonFolio(label: 'Sign out', onPressed: _busy ? null : _signOut),
      const SizedBox(height: 10),
      Text(
        'Your progress stays on this device after you sign out.',
        style: FolioType.bodyMuted(p, size: 15),
      ),
    ];
  }

  Widget _link(GridwellPalette p, String label, String route) => GestureDetector(
        onTap: () => context.push(route),
        child: Text(label,
            style: FolioType.bodyMuted(p, size: 14).copyWith(
              color: p.textPrimary,
              decoration: TextDecoration.underline,
            )),
      );

  void _notNow() {
    ref.read(accountOfferProvider.notifier).done();
    context.pop();
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      final outcome = await ref.read(accountActionsProvider).signInWithGoogle();
      if (!mounted || outcome == SignInOutcome.cancelled) return;
      _signedInMessage(outcome);
    } on AuthFailure catch (e) {
      _show(e.message);
    } catch (e) {
      _show('Google sign-in did not work. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _email() async {
    final outcome = await context.push<SignInOutcome>('/account/email');
    if (outcome != null && mounted) _signedInMessage(outcome);
  }

  void _signedInMessage(SignInOutcome outcome) {
    _show(outcome == SignInOutcome.switched
        ? 'Signed in. Your account and this device now share the same progress.'
        : 'Signed in. Your progress is saved to your account.');
  }

  Future<void> _signOut() async {
    final p = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text('Sign out?', style: FolioType.plateTitle(p, size: 26)),
        content: Text(
          'Your progress stays on this device and in your account. Sign in again any time.',
          style: FolioType.body(p),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: FolioType.body(p))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign out', style: FolioType.body(p).copyWith(color: p.accent)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(accountActionsProvider).signOut();
      _show('Signed out.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
