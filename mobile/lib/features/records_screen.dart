import '../ui/web_icon.dart';
import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import '../ui/widgets.dart';
import 'record_detail.dart';
import '../ui/theme.dart';
import '../ui/frontend_widgets.dart';
import 'package:intl/intl.dart';

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
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = widget.controller.overview?.records ?? [];
    final filtered = filterRecords(
      records,
      query: _search.text,
      type: _type,
      month: _month,
      draftsOnly: _drafts,
    );
    final months =
        records.map((r) => DateTime(r.date.year, r.date.month)).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    if (_month != null && !months.contains(_month)) {
      months.add(_month!);
    }
    final draftCount = records.where((r) => !r.isCommitted).length;
    final p = WebPalette.of(context), month = _month ?? DateTime.now();
    return PageBody(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Cari transaksi...',
            prefixIcon: WebIcon(Icons.search, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filter('Semua', null),
              const SizedBox(width: 8),
              _filter('Pengeluaran', 'expense'),
              const SizedBox(width: 8),
              _filter('Pemasukan', 'income'),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Draft ($draftCount)'),
                selected: _drafts,
                labelStyle: TextStyle(
                  color: _drafts ? p.onInk : p.secondary,
                  fontSize: 12,
                ),
                onSelected: (s) => setState(() => _drafts = s),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<DateTime>(
                tooltip: 'Periode',
                onSelected: (m) =>
                    setState(() => _month = m.year == 1 ? null : m),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: DateTime(1),
                    child: const Text('Semua waktu'),
                  ),
                  ...months.map(
                    (m) => PopupMenuItem(value: m, child: Text(monthLabel(m))),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface,
                    border: Border.all(color: p.border),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      WebIcon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: p.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _month == null
                            ? 'Periode'
                            : DateFormat('MMM yyyy', 'id_ID').format(_month!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        WebStatStrip(
          items: [
            (
              label: 'Pengeluaran',
              amount:
                  widget.controller.overview?.total('expense', month: month) ??
                  0.0,
              color: p.red,
            ),
            (
              label: 'Pemasukan',
              amount:
                  widget.controller.overview?.total('income', month: month) ??
                  0.0,
              color: p.green,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const EmptyCard(
            title: 'Tidak ada transaksi',
            message: 'Ubah filter atau tambahkan transaksi baru.',
          )
        else
          ..._grouped(context, filtered),
      ],
    );
  }

  Widget _filter(String label, String? type) {
    final p = WebPalette.of(context), selected = _type == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? p.onInk : p.secondary,
      ),
      onSelected: (_) => setState(() => _type = type),
    );
  }

  List<Widget> _grouped(BuildContext context, List<TrackerRecord> records) {
    final groups = <DateTime, List<TrackerRecord>>{};
    for (final record in records) {
      final d = record.date;
      groups
          .putIfAbsent(DateTime(d.year, d.month, d.day), () => [])
          .add(record);
    }
    final p = WebPalette.of(context), now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return groups.entries.map((entry) {
      final date = entry.key, items = entry.value;
      final prefix = date == today
          ? 'Hari ini · '
          : date == today.subtract(const Duration(days: 1))
          ? 'Kemarin · '
          : '';
      final total = items
          .where((r) => r.isCommitted)
          .fold(
            0.0,
            (sum, r) => sum + (r.type == 'income' ? r.amount : -r.amount),
          );
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: p.elevated,
                  border: Border(bottom: BorderSide(color: p.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$prefix${DateFormat('EEEE, d MMMM', 'id_ID').format(date)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${total < 0 ? '−' : '+'}${rupiah(total.abs())}',
                      style: monoStyle(
                        size: 11,
                        color: total < 0 ? p.red : p.green,
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(),
                WebRecordRow(
                  record: items[i],
                  onTap: () => openRecord(context, widget.controller, items[i]),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }
}
