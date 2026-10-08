import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import '../ui/widgets.dart';
import '../ui/motion.dart';

class AddDebtSheet extends StatefulWidget {
  const AddDebtSheet({super.key, required this.controller, required this.friend});
  final AppController controller;
  final Friend friend;
  @override
  State<AddDebtSheet> createState() => _AddDebtSheetState();
}
class _AddDebtSheetState extends State<AddDebtSheet> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(), _description = TextEditingController();
  bool _busy = false;
  String? _error;
  int _failures = 0;
  @override
  void dispose() { _amount.dispose(); _description.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (!_form.currentState!.validate()) { setState(() => _failures++); return; }
    setState(() { _busy = true; _error = null; });
    try {
      await widget.controller.mutate('POST', 'debt/create', body: {
        'amount': parseAmount(_amount.text), 'description': _description.text.trim(), 'debtorId': widget.friend.id,
      });
      if (mounted) { Navigator.pop(context); }
    } catch (e) { if (mounted) { setState(() { _error = e.toString(); _failures++; }); } }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_busy, child: Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom), child: SingleChildScrollView(
      padding: const EdgeInsets.all(24), child: ShakeFeedback(trigger: _failures, child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Piutang ke ${widget.friend.username}', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12), const Text('Kamu memberikan pinjaman. Uang tunai berpindah dari akunmu ke akun teman.'),
          const SizedBox(height: 24), TextFormField(controller: _amount, enabled: !_busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
            decoration: const InputDecoration(labelText: 'Jumlah piutang (Rp)'),
            validator: (v) => parseAmount(v ?? '') == null ? 'Jumlah harus positif, maksimal 2 desimal (tanpa pemisah ribuan).' : null),
          const SizedBox(height: 16), TextFormField(controller: _description, enabled: !_busy, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Untuk apa?'), validator: (v) => (v?.trim().isEmpty ?? true)
              ? 'Deskripsi wajib diisi.' : utf8.encode(v!).length > 4000 ? 'Deskripsi maksimal 4000 byte.' : null),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 16),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 24), BusyButton(busy: _busy, label: 'Simpan piutang', onPressed: _save),
          const SizedBox(height: 8), Center(child: TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Batal'))),
        ]))))));
}
