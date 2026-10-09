import '../ui/web_icon.dart';
import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../ui/motion.dart';
import '../ui/frontend_widgets.dart';

Future<void> openRecord(
  BuildContext context,
  AppController controller,
  TrackerRecord record,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  sheetAnimationStyle: AnimationStyle(
    duration: TrackerMotion.duration(context, TrackerMotion.entrance),
    reverseDuration: TrackerMotion.duration(context, TrackerMotion.quick),
  ),
  builder: (context) => RecordDetail(controller: controller, record: record),
);

class RecordDetail extends StatefulWidget {
  const RecordDetail({
    super.key,
    required this.controller,
    required this.record,
  });
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
    _primary = categories.containsKey(widget.record.primary)
        ? widget.record.primary
        : 'makanan';
    _secondary = categories[_primary]!.contains(widget.record.secondary)
        ? widget.record.secondary
        : categories[_primary]!.first;
  }

  Future<void> _commit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.mutate(
        'PUT',
        'user/record/commit',
        body: {
          'recordId': widget.record.id,
          'category': _primary,
          'secondaryCategory': _secondary,
        },
      );
      if (mounted) {
        Navigator.pop(context);
        toast(context, 'Catatan berhasil dikonfirmasi.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete() async {
    if (!await confirm(
      context,
      'Hapus draft?',
      'Catatan ini akan dihapus permanen.',
    )) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.mutate(
        'DELETE',
        'user/record/${widget.record.id}',
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record, p = WebPalette.of(context);
    final income = ['gaji', 'hadiah'].contains(_primary);
    return PopScope(
      canPop: !_busy,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.isCommitted ? 'Detail catatan' : 'Konfirmasi kategori',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const WebIcon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: p.elevated,
                  border: Border.all(color: p.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!r.isCommitted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: p.amberSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Draft',
                          style: TextStyle(
                            color: p.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      r.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          rupiah(r.amount),
                          style: monoStyle(
                            size: 22,
                            color: r.type == 'income' ? p.green : p.red,
                          ),
                        ),
                        Text(
                          dateLabel(r.date),
                          style: TextStyle(fontSize: 12, color: p.muted),
                        ),
                      ],
                    ),
                    if (r.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          r.description,
                          style: TextStyle(fontSize: 12, color: p.muted),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (r.isCommitted) ...[
                Text(
                  '${r.primary} · ${r.secondary}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('Catatan sudah dikonfirmasi dan masuk ke saldo.'),
              ] else ...[
                Text(
                  'Saran AI dapat kamu ubah sebelum konfirmasi.',
                  style: TextStyle(fontSize: 12, color: p.muted),
                ),
                const SizedBox(height: 20),
                Text(
                  'Kategori transaksi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.88,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: 10),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    mainAxisExtent:
                        72 *
                        (MediaQuery.textScalerOf(context).scale(18) / 18).clamp(
                          1.0,
                          4.0,
                        ),
                  ),
                  children: categories.keys.map((c) {
                    final colors = webCategoryColors(p, c),
                        selected = _primary == c;
                    return Tooltip(
                      message: 'Kategori $c',
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _primary = c;
                                _secondary = categories[c]!.first;
                              }),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected
                              ? colors.background
                              : p.elevated,
                          side: BorderSide(
                            color: selected ? colors.foreground : p.border,
                            width: selected ? 2 : 1.5,
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              categoryEmoji[c]!,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              c,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: p.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kategori detail',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories[_primary]!
                      .map(
                        (c) => ChoiceChip(
                          label: Text(c.replaceAll('_', ' ')),
                          selected: _secondary == c,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: _secondary == c ? p.onInk : p.secondary,
                          ),
                          onSelected: _busy
                              ? null
                              : (_) => setState(() => _secondary = c),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: income ? p.greenSoft : p.redSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    income ? '＋ Pemasukan' : '− Pengeluaran',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: income ? p.green : p.red,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                BusyButton(
                  busy: _busy,
                  label: 'Konfirmasi catatan',
                  onPressed: _commit,
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _delete,
                  style: TextButton.styleFrom(foregroundColor: p.red),
                  icon: const WebIcon(Icons.delete_outline, size: 16),
                  label: const Text('Hapus draft'),
                ),
              ],
              if (_error != null) Text(_error!, style: TextStyle(color: p.red)),
            ],
          ),
        ),
      ),
    );
  }
}
