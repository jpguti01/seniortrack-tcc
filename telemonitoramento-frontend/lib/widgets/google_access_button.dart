import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_button_web_stub.dart'
    if (dart.library.html) 'google_button_web.dart';

class GoogleAccessButton extends StatefulWidget {
  const GoogleAccessButton(
      {super.key,
      required this.onToken,
      required this.onError,
      required this.enabled});
  final Future<void> Function(String) onToken;
  final void Function(String) onError;
  final bool enabled;
  static const clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  @override
  State<GoogleAccessButton> createState() => _GoogleAccessButtonState();
}

class _GoogleAccessButtonState extends State<GoogleAccessButton> {
  late final GoogleSignIn _google;
  StreamSubscription<GoogleSignInAccount?>? _subscription;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _google = GoogleSignIn(
        scopes: const ['email'],
        clientId: kIsWeb ? GoogleAccessButton.clientId : null,
        serverClientId: kIsWeb ? null : GoogleAccessButton.clientId);
    if (kIsWeb) {
      _subscription = _google.onCurrentUserChanged.listen((account) {
        if (account != null) _receive(account);
      },
          onError: (_) => widget
              .onError('Não foi possível acessar o Google. Tente novamente.'));
      _google.isSignedIn().catchError((_) => false);
    }
  }

  Future<void> _receive(GoogleSignInAccount account) async {
    if (_busy || !widget.enabled) return;
    _busy = true;
    try {
      final token = (await account.authentication).idToken;
      if (token == null) throw StateError('Token ausente');
      if (mounted) await widget.onToken(token);
    } catch (_) {
      if (mounted) {
        widget.onError(
            'Não foi possível entrar com Google. Tente novamente ou use e-mail e senha.');
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _signIn() async {
    try {
      final account = await _google.signIn();
      if (account != null) await _receive(account);
    } catch (_) {
      if (mounted) {
        widget.onError(
            'Não foi possível abrir o Google. Confira sua conexão e tente novamente.');
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => kIsWeb
      ? IgnorePointer(
          ignoring: !widget.enabled, child: Center(child: googleWebButton()))
      : OutlinedButton.icon(
          onPressed: widget.enabled ? _signIn : null,
          icon: const Icon(Icons.account_circle_outlined),
          label: const Text('Entrar com o Google'));
}
