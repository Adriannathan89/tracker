import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../ui/motion.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}
class _AddRecordScreenState extends State<AddRecordScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(), _title = TextEditingController(), _description = TextEditingController();
  var _date = DateTime.now();
  bool _details = false, _busy = false;
  String? _error;
  int _failures = 0;
  @override
  void dispose() { _amount.dispose(); _title.dispose(); _description.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (!_form.currentState!.validate() || parseAmount(_amount.text) == null) {
      setState(() => _failures++); return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await widget.controller.mutate('POST', 'user/record', body: {
        'title': _title.text.trim(), 'description': _description.text,
        'amount': parseAmount(_amount.text), 'date': DateFormat('yyyy-MM-dd').format(_date),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _failures++; }); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_busy, child: Scaffold(
    appBar: AppBar(title: Text(_details ? 'Detail catatan' : 'Tambah catatan')),
    body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
      child: ListView(padding: const EdgeInsets.all(24), children: [
        Container(decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('JUMLAH TRANSAKSI', style: TextStyle(color: Colors.white60, letterSpacing: 1)),
            const SizedBox(height: 14), Text(_details ? rupiah(parseAmount(_amount.text) ?? 0) : 'Berapa jumlahnya?',
              style: const TextStyle(color: lime, fontSize: 28, fontWeight: FontWeight.w800)),
          ])), const SizedBox(height: 24),
        MotionEntrance(replayKey: _details, duration: TrackerMotion.quick,
          child: ShakeFeedback(trigger: _failures, child: Column(children: [
        if (!_details) ...[
          TextFormField(controller: _amount, autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
            decoration: const InputDecoration(labelText: 'Jumlah (Rp)', hintText: 'Misalnya 12500'),
            onChanged: (_) => setState(() => _error = null)),
          const SizedBox(height: 12), const Text('Gunakan koma untuk desimal, tanpa pemisah ribuan.'),
          const SizedBox(height: 28), BusyButton(busy: false, label: 'Lanjutkan', onPressed: () {
            if (parseAmount(_amount.text) == null) {
              setState(() { _error = 'Masukkan jumlah positif dengan maksimal 2 angka desimal.'; _failures++; }); return;
            }
            FocusScope.of(context).unfocus(); setState(() { _details = true; _error = null; });
          }),
        ] else Form(key: _form, child: Column(children: [
          TextButton.icon(onPressed: _busy ? null : () => setState(() => _details = false),
            icon: const Icon(Icons.edit_outlined), label: const Text('Ubah jumlah')),
          TextFormField(controller: _title, enabled: !_busy, maxLength: 200,
            decoration: const InputDecoration(labelText: 'Judul', hintText: 'Misalnya beli nasi goreng'),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Judul wajib diisi.' : null),
          const SizedBox(height: 16), TextFormField(controller: _description, enabled: !_busy, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
            validator: (v) => utf8.encode(v ?? '').length > 4000 ? 'Deskripsi maksimal 4000 byte.' : null),
          const SizedBox(height: 16), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Tanggal transaksi'), subtitle: Text(dateLabel(_date)),
            trailing: const Icon(Icons.chevron_right), onTap: _busy ? null : () async {
              final result = await showDatePicker(context: context, initialDate: _date,
                firstDate: DateTime(2000), lastDate: DateTime(DateTime.now().year + 5, 12, 31));
              if (result != null && mounted) setState(() => _date = result);
            }), const SizedBox(height: 20),
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('AI akan menyarankan kategori. Setelah disimpan, periksa dan konfirmasi catatan agar masuk ke saldo.'))),
          const SizedBox(height: 24), BusyButton(busy: _busy, label: 'Simpan catatan', onPressed: _save),
        ])),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 16),
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ]))),
      ]))))));
}
