import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/account.dart';
import '../../state/services.dart';
import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../widgets/tally.dart';

/// Email and password: sign in to an existing account or create one, with a
/// password reset. Pops with the [SignInOutcome] on success.
class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _create = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: TallyBody(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TallyTopBar(title: _create ? 'New account' : 'Sign in'),
          Expanded(
            child: AutofillGroup(
              child: ListView(padding: const EdgeInsets.fromLTRB(tallyMargin, 20, tallyMargin, 24), children: [
                TallySegmented<bool>(
                  options: const [(false, 'Sign in'), (true, 'Create account')],
                  value: _create,
                  onChanged: (v) => setState(() {
                    _create = v;
                    _error = null;
                    _info = null;
                  }),
                  expand: true,
                ),
                const SizedBox(height: 24),
                _field(p, 'Email', _email,
                    keyboard: TextInputType.emailAddress,
                    autofill: const [AutofillHints.email],
                    action: TextInputAction.next),
                const SizedBox(height: 14),
                _field(p, 'Password', _password,
                    obscure: _hidePassword,
                    autofill: [_create ? AutofillHints.newPassword : AutofillHints.password],
                    action: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    suffix: IconButton(
                      tooltip: _hidePassword ? 'Show password' : 'Hide password',
                      icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: p.ink2),
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    )),
                if (_create) ...[
                  const SizedBox(height: 8),
                  Text('At least 6 characters.', style: TallyType.label(p.ink2)),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: TallyType.prose(p.error, size: 15)),
                ],
                if (_info != null) ...[
                  const SizedBox(height: 14),
                  Text(_info!, style: TallyType.prose(p.ink, size: 15)),
                ],
                if (!_create)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      button: true,
                      label: 'Forgot password?',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _busy ? null : _reset,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text('Forgot password?', style: TallyType.body(p.ink2).copyWith(fontSize: 15)),
                        ),
                      ),
                    ),
                  ),
                if (_create) ...[
                  const SizedBox(height: 16),
                  Text('Your progress on this device moves into the new account.', style: TallyType.prose(p.ink2, size: 14)),
                ],
              ]),
            ),
          ),
          PrimarySlab(
            label: _busy ? 'One moment…' : (_create ? 'Create account' : 'Sign in'),
            onPressed: _busy ? null : _submit,
            height: 78,
          ),
        ]),
      ),
    );
  }

  Widget _field(
    GridwellPalette p,
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
    bool obscure = false,
    List<String>? autofill,
    TextInputAction? action,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: !obscure,
        autofillHints: autofill,
        textInputAction: action,
        onSubmitted: onSubmitted,
        style: TallyType.body(p.ink).copyWith(fontSize: 17),
        cursorColor: p.accent,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelStyle: TallyType.label(p.accent),
          suffixIcon: suffix,
        ),
      );

  bool _validate() {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      setState(() => _error = 'Please enter your email address.');
      return false;
    }
    if (_password.text.length < 6) {
      setState(() => _error =
          _create ? 'Please choose a password of at least 6 characters.' : 'Please enter your password.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _info = null;
    });
    if (!_validate()) return;
    setState(() => _busy = true);
    try {
      final actions = ref.read(accountActionsProvider);
      final outcome = _create
          ? await actions.createEmailAccount(_email.text, _password.text)
          : await actions.signInWithEmail(_email.text, _password.text);
      if (mounted) context.pop(outcome);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e, st) {
      ref.read(crashReporterProvider).recordError(e, st, reason: 'email sign-in');
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your email above, then tap "Forgot password?" again.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountActionsProvider).sendPasswordReset(email);
      if (mounted) setState(() => _info = 'If an account uses $email, a reset link is on its way.');
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
