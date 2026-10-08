import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import '../ui/widgets.dart';
import 'record_detail.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}
class _RecordsScreenState extends State<RecordsScreen> {
  final _search = TextEditingController();
  String? _type;
  DateTime? _month;
  bool _drafts = false;
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final records = widget.controller.overview?.records ?? [];
    final filtered = filterRecords(records, query: _search.text, type: _type, month: _month, draftsOnly: _drafts);
    final months = records.map((r) => DateTime(r.date.year, r.date.month)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    if (_month != null && !months.contains(_month)) { months.add(_month!); }
    final draftCount = records.where((r) => !r.isCommitted).length;
    return PageBody(controller: widget.controller, children: [
      const Text('Semua catatan keuanganmu.', style: TextStyle(fontSize: 15)), const SizedBox(height: 18),
      TextField(controller: _search, onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(hintText: 'Cari catatan atau kategori', prefixIcon: Icon(Icons.search))),
      const SizedBox(height: 12), DropdownButtonFormField<DateTime>(initialValue: _month, isExpanded: true,
        decoration: const InputDecoration(labelText: 'Periode'), items: [
          const DropdownMenuItem<DateTime>(value: null, child: Text('Semua waktu')),
          ...months.map((m) => DropdownMenuItem(value: m, child: Text(monthLabel(m)))),
        ], onChanged: (m) => setState(() => _month = m)),
      const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 6, children: [
        ChoiceChip(label: const Text('Semua'), selected: _type == null, onSelected: (_) => setState(() => _type = null)),
        ChoiceChip(label: const Text('Pengeluaran'), selected: _type == 'expense', onSelected: (_) => setState(() => _type = 'expense')),
        ChoiceChip(label: const Text('Pemasukan'), selected: _type == 'income', onSelected: (_) => setState(() => _type = 'income')),
        FilterChip(label: Text('Draft ($draftCount)'), selected: _drafts, onSelected: (s) => setState(() => _drafts = s)),
      ]),
      SectionTitle('${filtered.length} catatan'),
      if (filtered.isEmpty) const EmptyCard(title: 'Tidak ada catatan', message: 'Ubah filter atau tambahkan transaksi baru.')
      else ..._grouped(context, filtered),
    ]);
  }
  List<Widget> _grouped(BuildContext context, List<TrackerRecord> records) {
    final result = <Widget>[];
    String? previous;
    for (final record in records) {
      final date = dateLabel(record.date);
      if (date != previous) {
        result.add(Padding(padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
          child: Text(date, style: const TextStyle(fontWeight: FontWeight.w700))));
        previous = date;
      }
      result.add(RecordTile(record, onTap: () => openRecord(context, widget.controller, record)));
    }
    return result;
  }
}
