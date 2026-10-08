import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

Future<void> openRecord(BuildContext context, AppController controller, TrackerRecord record) =>
  showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true,
    builder: (context) => RecordDetail(controller: controller, record: record));
class RecordDetail extends StatefulWidget {
  const RecordDetail({super.key, required this.controller, required this.record});
  final AppController controller;
  final TrackerRecord record;
  @override
  State<RecordDetail> createState() => _RecordDetailState();
}
class _RecordDetailState extends State<RecordDetail> {
  late String _primary, _secondary;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _primary = categories.containsKey(widget.record.primary) ? widget.record.primary : 'makanan';
    _secondary = categories[_primary]!.contains(widget.record.secondary) ? widget.record.secondary : categories[_primary]!.first;
  }
  Future<void> _commit() async {
    setState(() { _busy = true; _error = null; });
    try {
      await widget.controller.mutate('PUT', 'user/record/commit', body: {
        'recordId': widget.record.id, 'category': _primary, 'secondaryCategory': _secondary,
      });
      if (mounted) { Navigator.pop(context); toast(context, 'Catatan berhasil dikonfirmasi.'); }
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _delete() async {
    if (!await confirm(context, 'Hapus draft?', 'Catatan ini akan dihapus permanen.')) return;
    if (!mounted) return;
    setState(() { _busy = true; _error = null; });
    try {
      await widget.controller.mutate('DELETE', 'user/record/${widget.record.id}');
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return PopScope(canPop: !_busy, child: Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.85,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Row(children: [Expanded(child: Text(r.isCommitted ? 'Detail catatan' : 'Konfirmasi kategori',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            IconButton(tooltip: 'Tutup', onPressed: _busy ? null : () => Navigator.pop(context), icon: const Icon(Icons.close))]),
          const SizedBox(height: 16), Text(r.title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8), Text(rupiah(r.amount), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
            color: r.type == 'income' ? incomeColor : expenseColor)),
          const SizedBox(height: 8), Text(dateLabel(r.date)),
          if (r.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(r.description)),
          const SizedBox(height: 24),
          if (r.isCommitted) ...[Text('${r.primary} · ${r.secondary}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12), const Text('Catatan sudah dikonfirmasi dan masuk ke saldo.')]
          else ...[
            const Text('Saran AI dapat kamu ubah sebelum konfirmasi.'), const SizedBox(height: 20),
            const Text('Kategori transaksi', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: categories.keys.map((c) => ChoiceChip(
              label: Text('${categoryEmoji[c]} $c'), selected: _primary == c,
              onSelected: _busy ? null : (_) => setState(() { _primary = c; _secondary = categories[c]!.first; }))).toList()),
            const SizedBox(height: 20), const Text('Kategori detail', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: categories[_primary]!.map((c) => ChoiceChip(
              label: Text(c.replaceAll('_', ' ')), selected: _secondary == c,
              onSelected: _busy ? null : (_) => setState(() => _secondary = c))).toList()),
            const SizedBox(height: 20), Text(['gaji', 'hadiah'].contains(_primary) ? '＋ Pemasukan' : '− Pengeluaran',
              style: TextStyle(fontWeight: FontWeight.w700, color: ['gaji', 'hadiah'].contains(_primary) ? incomeColor : expenseColor)),
            const SizedBox(height: 24), BusyButton(busy: _busy, label: 'Konfirmasi catatan', onPressed: _commit),
            TextButton.icon(onPressed: _busy ? null : _delete, icon: const Icon(Icons.delete_outline), label: const Text('Hapus draft')),
          ],
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ]))));
  }
}
