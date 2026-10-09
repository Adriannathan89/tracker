import 'dart:convert';
import 'package:flutter/material.dart';
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
  final _title = TextEditingController(),
      _description = TextEditingController();
  final _amountFormatter = NumberFormat('#,##0', 'id_ID');
  String _amount = '0';
  var _date = DateTime.now();
  bool _details = false, _busy = false;
  String? _error;
  int _failures = 0;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  String get _formattedAmount {
    final parts = _amount.split(',');
    final whole = _amountFormatter.format(int.parse(parts.first));
    return 'Rp $whole${parts.length == 2 ? ',${parts.last}' : ''}';
  }

  void _pressAmount(String key) {
    var next = _amount;
    if (key == 'del') {
      next = next.length > 1 ? next.substring(0, next.length - 1) : '0';
    } else if (key == ',') {
      if (next.contains(',')) {
        return;
      }
      next += ',';
    } else {
      next = '$next$key'.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    }
    if (!RegExp(r'^\d{1,15}(,\d{0,2})?$').hasMatch(next)) {
      return;
    }
    setState(() {
      _amount = next;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || parseAmount(_amount) == null) {
      setState(() => _failures++);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.mutate(
        'POST',
        'user/record',
        body: {
          'title': _title.text.trim(),
          'description': _description.text,
          'amount': parseAmount(_amount),
          'date': DateFormat('yyyy-MM-dd').format(_date),
        },
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
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
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(_details ? 'Detail catatan' : 'Tambah catatan'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'JUMLAH TRANSAKSI',
                        style: TextStyle(
                          color: Colors.white60,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        liveRegion: true,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formattedAmount,
                            style: const TextStyle(
                              color: lime,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                MotionEntrance(
                  replayKey: _details,
                  duration: TrackerMotion.quick,
                  child: ShakeFeedback(
                    trigger: _failures,
                    child: Column(
                      children: [
                        if (!_details) ...[
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            mainAxisExtent: 60,
                            children: [
                              for (final key in [
                                '1',
                                '2',
                                '3',
                                '4',
                                '5',
                                '6',
                                '7',
                                '8',
                                '9',
                                '000',
                                '0',
                                'del',
                              ])
                                _amountKey(key),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton(
                              onPressed: () => _pressAmount(','),
                              child: const Text(','),
                            ),
                          ),
                          const SizedBox(height: 16),
                          BusyButton(
                            busy: false,
                            label: 'Lanjutkan',
                            onPressed: () {
                              if (parseAmount(_amount) == null) {
                                setState(() {
                                  _error =
                                      'Masukkan jumlah positif dengan maksimal 2 angka desimal.';
                                  _failures++;
                                });
                                return;
                              }
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _details = true;
                                _error = null;
                              });
                            },
                          ),
                        ] else
                          Form(
                            key: _form,
                            child: Column(
                              children: [
                                TextButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () {
                                          FocusScope.of(context).unfocus();
                                          setState(() => _details = false);
                                        },
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Ubah jumlah'),
                                ),
                                TextFormField(
                                  controller: _title,
                                  enabled: !_busy,
                                  maxLength: 200,
                                  decoration: const InputDecoration(
                                    labelText: 'Judul',
                                    hintText: 'Misalnya beli nasi goreng',
                                  ),
                                  validator: (v) => (v?.trim().isEmpty ?? true)
                                      ? 'Judul wajib diisi.'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _description,
                                  enabled: !_busy,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Deskripsi (opsional)',
                                  ),
                                  validator: (v) =>
                                      utf8.encode(v ?? '').length > 4000
                                      ? 'Deskripsi maksimal 4000 byte.'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                  title: const Text('Tanggal transaksi'),
                                  subtitle: Text(dateLabel(_date)),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: _busy
                                      ? null
                                      : () async {
                                          final result = await showDatePicker(
                                            context: context,
                                            initialDate: _date,
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(
                                              DateTime.now().year + 5,
                                              12,
                                              31,
                                            ),
                                          );
                                          if (result != null && mounted) {
                                            setState(() => _date = result);
                                          }
                                        },
                                ),
                                const SizedBox(height: 20),
                                const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'AI akan menyarankan kategori. Setelah disimpan, periksa dan konfirmasi catatan agar masuk ke saldo.',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                BusyButton(
                                  busy: _busy,
                                  label: 'Simpan catatan',
                                  onPressed: _save,
                                ),
                              ],
                            ),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _amountKey(String key) => key == 'del'
      ? Tooltip(
          message: 'Hapus angka',
          child: OutlinedButton(
            onPressed: () => _pressAmount(key),
            child: const Icon(
              Icons.backspace_outlined,
              semanticLabel: 'Hapus angka',
            ),
          ),
        )
      : OutlinedButton(
          onPressed: () => _pressAmount(key),
          style: OutlinedButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(key),
        );
}
