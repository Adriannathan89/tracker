import '../ui/web_icon.dart';
import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../ui/motion.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController(),
      _password = TextEditingController(),
      _confirmation = TextEditingController();
  bool _register = false, _busy = false, _obscure = true;
  String? _error;
  int _failures = 0;
  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      setState(() => _failures++);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.authenticate(
        _username.text.trim(),
        _password.text,
        register: _register,
      );
      if (mounted) {
        _password.clear();
        _confirmation.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _failures++;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        children: [
          Container(
            color: WebPalette.of(context).foreground,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: WebPalette.of(context).accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'B',
                        style: TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'tracker',
                      style: TextStyle(
                        color: WebPalette.of(context).onInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Kelola utang tanpa yang\n',
                        style: TextStyle(color: WebPalette.of(context).onInk),
                      ),
                      TextSpan(
                        text: 'ribet.',
                        style: TextStyle(color: WebPalette.of(context).accent),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.78,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          MotionEntrance(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  child: AutofillGroup(
                    child: ShakeFeedback(
                      trigger: _failures,
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: WebPalette.of(context).elevated,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  for (final tab in [false, true])
                                    Expanded(
                                      child: TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => setState(() {
                                                _register = tab;
                                                _error = null;
                                              }),
                                        style: TextButton.styleFrom(
                                          backgroundColor: _register == tab
                                              ? WebPalette.of(
                                                  context,
                                                ).foreground
                                              : Colors.transparent,
                                          foregroundColor: _register == tab
                                              ? WebPalette.of(context).onInk
                                              : WebPalette.of(context).muted,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(tab ? 'Daftar' : 'Masuk'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            AnimatedSwitcher(
                              duration: TrackerMotion.duration(
                                context,
                                TrackerMotion.quick,
                              ),
                              child: Text(
                                _register ? 'Buat akun baru' : 'Halo lagi 👋',
                                key: ValueKey(_register),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _register
                                  ? 'Mulai kelola keuanganmu hari ini.'
                                  : 'Masukkan detail akunmu untuk lanjut.',
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _username,
                              enabled: !_busy,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                              ),
                              autofillHints: const [AutofillHints.username],
                              textInputAction: TextInputAction.next,
                              validator: (v) => _register
                                  ? validateUsername(v)
                                  : (v?.trim().isEmpty ?? true)
                                  ? 'Masukkan username.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _password,
                              enabled: !_busy,
                              obscureText: _obscure,
                              autofillHints: [
                                _register
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  tooltip: _obscure
                                      ? 'Tampilkan password'
                                      : 'Sembunyikan password',
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: WebIcon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (v) =>
                                  validatePassword(v, register: _register),
                              onFieldSubmitted: (_) {
                                if (!_busy && !_register) {
                                  _submit();
                                }
                              },
                            ),
                            AnimatedSize(
                              duration: TrackerMotion.duration(
                                context,
                                TrackerMotion.quick,
                              ),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: _register
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: TextFormField(
                                        controller: _confirmation,
                                        obscureText: true,
                                        enabled: !_busy,
                                        decoration: const InputDecoration(
                                          labelText: 'Konfirmasi password',
                                        ),
                                        validator: (v) => v != _password.text
                                            ? 'Password tidak cocok.'
                                            : null,
                                      ),
                                    )
                                  : const SizedBox(width: double.infinity),
                            ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            BusyButton(
                              busy: _busy,
                              label: _register ? 'Daftar' : 'Masuk',
                              arrow: true,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
