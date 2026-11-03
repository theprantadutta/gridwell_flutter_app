import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/account.dart';
import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';

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
      body: FolioBody(
        child: Column(children: [
          FolioHeader(leading: 'Account', center: _create ? 'New account' : 'Sign in'),
          Expanded(
            child: AutofillGroup(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(folioMargin, 24, folioMargin, 32),
                children: [
                  Segmented<bool>(
                    options: const [(false, 'Sign in', null), (true, 'Create account', null)],
                    value: _create,
                    onChanged: (v) => setState(() {
                      _create = v;
                      _error = null;
                      _info = null;
                    }),
                    height: 52,
                    expand: true,
                  ),
                  const SizedBox(height: 24),
                  _field(p, 'Email', _email,
                      keyboard: TextInputType.emailAddress,
                      autofill: const [AutofillHints.email],
                      action: TextInputAction.next),
                  const SizedBox(height: 16),
                  _field(p, 'Password', _password,
                      obscure: _hidePassword,
                      autofill: [_create ? AutofillHints.newPassword : AutofillHints.password],
                      action: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        tooltip: _hidePassword ? 'Show password' : 'Hide password',
                        icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: p.textMuted),
                        onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      )),
                  if (_create) ...[
                    const SizedBox(height: 6),
                    Text('At least 6 characters.', style: FolioType.bodyMuted(p, size: 14)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: FolioType.body(p, size: 16).copyWith(color: p.accent)),
                  ],
                  if (_info != null) ...[
                    const SizedBox(height: 14),
                    Text(_info!, style: FolioType.body(p, size: 16)),
                  ],
                  const SizedBox(height: 24),
                  InkButton(
                    label: _busy ? 'One moment…' : (_create ? 'Create account' : 'Sign in'),
                    onPressed: _busy ? null : _submit,
                    height: 60,
                  ),
                  if (!_create)
                    Center(child: TextAction(label: 'Forgot password?', onPressed: _busy ? null : _reset)),
                  if (_create) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Your progress on this device moves into the new account.',
                      style: FolioType.bodyMuted(p, size: 15),
                    ),
                  ],
                ],
              ),
            ),
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
  }) {
    OutlineInputBorder border(Color c) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: c, width: 1.2));
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: !obscure,
      autofillHints: autofill,
      textInputAction: action,
      onSubmitted: onSubmitted,
      style: FolioType.body(p, size: 18),
      cursorColor: p.textPrimary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: FolioType.bodyMuted(p, size: 16),
        floatingLabelStyle: FolioType.body(p, size: 16),
        suffixIcon: suffix,
        enabledBorder: border(p.ruleStrong),
        focusedBorder: border(p.textPrimary),
      ),
    );
  }

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
    } catch (_) {
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
