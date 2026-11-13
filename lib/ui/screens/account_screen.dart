import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/account.dart';
import '../../state/services.dart';
import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../widgets/tally.dart';
import 'settings_screen.dart' show TallyDialogText, showTallyDialog;

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
      body: TallyBody(
        bottom: false,
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const TallyTopBar(title: 'Account'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                children: [
                  for (final w in account.isGuest ? _guest(context, p) : _signedIn(context, p, account))
                    w is _EdgeToEdge ? w.child : Padding(padding: const EdgeInsets.symmetric(horizontal: tallyMargin), child: w),
                ],
              ),
            ),
            if (account.isGuest)
              PrimarySlab(
                label: 'Continue with Google',
                sublabel: 'One tap, nothing to remember',
                onPressed: _busy ? null : _google,
                height: 78,
              )
            else
              ColoredBox(
                color: p.sunk,
                child: Padding(
                  padding: const EdgeInsets.only(top: tallyDivider),
                  child: SizedBox(
                    height: 64 + MediaQuery.paddingOf(context).bottom,
                    child: SlabButton(label: 'Sign out', onPressed: _busy ? null : _signOut, textColor: p.error),
                  ),
                ),
              ),
          ]),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: p.bg.withValues(alpha: 0.6),
                child: Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2.5)),
              ),
            ),
        ]),
      ),
    );
  }

  List<Widget> _guest(BuildContext context, GridwellPalette p) => [
        Overline('Your progress', color: p.accent),
        const SizedBox(height: 12),
        Text('Keep your puzzles safe.', style: TallyType.titleL(p.ink)),
        const SizedBox(height: 16),
        Text(
          'Sign in to keep your solved puzzles and best times if you change or lose your phone, '
          'and to pick up where you left off on another device.',
          style: TallyType.prose(p.ink2, size: 16).copyWith(height: 1.5),
        ),
        const SizedBox(height: 10),
        Text(
          'You can keep playing without an account. Nothing changes, and you can sign in later in Settings.',
          style: TallyType.prose(p.ink3, size: 14),
        ),
        const SizedBox(height: 28),
        _EdgeToEdge(ColoredBox(
          color: p.sunk,
          child: Column(children: [
            SettingsRow.link(label: 'Continue with email', onTap: _busy ? () {} : _email),
            const SizedBox(height: tallyDivider),
            SettingsRow.link(label: 'Not now', onTap: _notNow),
          ]),
        )),
        const SizedBox(height: 22),
        Wrap(children: [
          Text('By signing in you agree to the ', style: TallyType.label(p.ink2)),
          _link(p, 'Terms of Use', '/legal/terms'),
          Text(' and the ', style: TallyType.label(p.ink2)),
          _link(p, 'Privacy Policy', '/legal/privacy'),
          Text('.', style: TallyType.label(p.ink2)),
        ]),
      ];

  List<Widget> _signedIn(BuildContext context, GridwellPalette p, Account account) {
    final via = switch (account.kind) {
      AccountKind.google => 'Google',
      AccountKind.apple => 'Apple',
      _ => 'email',
    };
    return [
      Overline('Signed in with $via', color: p.accent),
      const SizedBox(height: 12),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(account.email ?? 'Your account', maxLines: 1, style: TallyType.titleM(p.ink)),
      ),
      const SizedBox(height: 16),
      Text(
        'Your solved puzzles and best times are saved to your account. '
        'Sign in on another device to carry on there.',
        style: TallyType.prose(p.ink2, size: 16).copyWith(height: 1.5),
      ),
      if (account.kind == AccountKind.email && !account.emailVerified) ...[
        const SizedBox(height: 10),
        Text('We sent you an email to confirm your address.', style: TallyType.prose(p.ink3, size: 14)),
      ],
      const SizedBox(height: 14),
      Text('Your progress stays on this device after you sign out.', style: TallyType.prose(p.ink3, size: 14)),
    ];
  }

  Widget _link(GridwellPalette p, String label, String route) => GestureDetector(
        onTap: () => context.push(route),
        child: Text(label, style: TallyType.label(p.ink).copyWith(decoration: TextDecoration.underline)),
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
    } catch (e, st) {
      // Not a known auth failure: worth a look.
      ref.read(crashReporterProvider).recordError(e, st, reason: 'google sign-in');
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
    final ok = await showTallyDialog<bool>(
      context: context,
      title: 'Sign out?',
      body: const TallyDialogText('Your progress stays on this device and in your account. Sign in again any time.'),
      cancel: 'Cancel',
      confirm: 'Sign out',
      destructive: true,
      onConfirm: () => true,
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
    tallyToast(context, message);
  }
}

/// Marks a child of the account page that runs edge to edge, unpadded.
class _EdgeToEdge extends StatelessWidget {
  const _EdgeToEdge(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
