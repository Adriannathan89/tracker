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
  final _username = TextEditingController(), _password = TextEditingController(), _confirmation = TextEditingController();
  bool _register = false, _busy = false, _obscure = true;
  String? _error;
  int _failures = 0;
  @override
  void dispose() { _username.dispose(); _password.dispose(); _confirmation.dispose(); super.dispose(); }
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) { setState(() => _failures++); return; }
    setState(() { _busy = true; _error = null; });
    try {
      await widget.controller.authenticate(_username.text.trim(), _password.text, register: _register);
      if (mounted) { _password.clear(); _confirmation.clear(); }
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _failures++; }); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: ListView(children: [
    Container(color: ink, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset('assets/tracker-mark.png', width: 38, height: 38), const SizedBox(width: 10),
          const Text('tracker', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ]), const SizedBox(height: 24),
        const Text('Kelola uang & utang\ntanpa yang ribet.', textAlign: TextAlign.center,
          style: TextStyle(color: lime, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2)),
        const SizedBox(height: 12), const Text('Catat transaksi. Lacak saldo. Tagih teman.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
      ])),
    MotionEntrance(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(padding: const EdgeInsets.all(24), child: AutofillGroup(child: ShakeFeedback(trigger: _failures, child: Form(key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Masuk')),
            ButtonSegment(value: true, label: Text('Daftar'))], selected: {_register},
            onSelectionChanged: _busy ? null : (s) => setState(() { _register = s.first; _error = null; })),
          const SizedBox(height: 28), AnimatedSwitcher(duration: TrackerMotion.duration(context, TrackerMotion.quick),
            child: Text(_register ? 'Buat akun baru' : 'Halo lagi 👋', key: ValueKey(_register),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
          const SizedBox(height: 8), Text(_register ? 'Mulai kelola keuanganmu hari ini.' : 'Masukkan detail akunmu untuk lanjut.'),
          const SizedBox(height: 24),
          TextFormField(controller: _username, enabled: !_busy, decoration: const InputDecoration(labelText: 'Username'),
            autofillHints: const [AutofillHints.username], textInputAction: TextInputAction.next,
            validator: (v) => _register ? validateUsername(v) : (v?.trim().isEmpty ?? true) ? 'Masukkan username.' : null),
          const SizedBox(height: 16), TextFormField(controller: _password, enabled: !_busy, obscureText: _obscure,
            autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
            decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(
              tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan password',
              onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
            validator: (v) => validatePassword(v, register: _register),
            onFieldSubmitted: (_) { if (!_busy && !_register) _submit(); }),
          AnimatedSize(duration: TrackerMotion.duration(context, TrackerMotion.quick),
            curve: Curves.easeOutCubic, alignment: Alignment.topCenter,
            child: _register ? Padding(padding: const EdgeInsets.only(top: 16),
              child: TextFormField(controller: _confirmation, obscureText: true,
                enabled: !_busy, decoration: const InputDecoration(labelText: 'Konfirmasi password'),
                validator: (v) => v != _password.text ? 'Password tidak cocok.' : null)) : const SizedBox(width: double.infinity)),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 16),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 24), BusyButton(busy: _busy, label: _register ? 'Daftar & masuk' : 'Masuk', onPressed: _submit),
        ])))))))),
  ])));
}
