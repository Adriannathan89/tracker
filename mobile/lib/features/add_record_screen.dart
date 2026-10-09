import '../ui/web_icon.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../ui/motion.dart';
import '../ui/frontend_widgets.dart';

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
  Widget build(BuildContext context) {
    final p = WebPalette.of(context);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: WebPageHeader(
          textScale: MediaQuery.textScalerOf(context).scale(12) / 12,
          title: 'Catat Transaksi',
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: _busy ? null : () => Navigator.pop(context),
            icon: const WebIcon(Icons.arrow_back, size: 20),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  MotionEntrance(
                    replayKey: _details,
                    duration: TrackerMotion.quick,
                    child: ShakeFeedback(
                      trigger: _failures,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_details) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Text(
                                    'Jumlah',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.1,
                                      color: p.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Semantics(
                                    liveRegion: true,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _formattedAmount,
                                        style: monoStyle(
                                          size: 52,
                                          weight: FontWeight.w800,
                                          color: p.foreground,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: GridView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                    ),
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
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton(
                                onPressed: () => _pressAmount(','),
                                child: const Text(','),
                              ),
                            ),
                            const SizedBox(height: 16),
                            BusyButton(
                              busy: false,
                              label: 'Lanjutkan',
                              arrow: true,
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
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.pop(context, 'friends'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: p.amberSoft,
                                foregroundColor: p.secondary,
                                side: BorderSide(color: p.amber),
                                minimumSize: const Size(48, 48),
                              ),
                              icon: const WebIcon(
                                Icons.people_outline,
                                size: 18,
                              ),
                              label: const Text('Catat sebagai hutang/piutang'),
                            ),
                          ] else
                            Form(
                              key: _form,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.elevated,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Jumlah',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: p.muted,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  _formattedAmount,
                                                  style: monoStyle(size: 22),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Tooltip(
                                          message: 'Ubah jumlah',
                                          child: TextButton(
                                            onPressed: _busy
                                                ? null
                                                : () {
                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
                                                    setState(
                                                      () => _details = false,
                                                    );
                                                  },
                                            child: const Text('← Ubah'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _title,
                                    enabled: !_busy,
                                    maxLength: 200,
                                    decoration: const InputDecoration(
                                      labelText: 'Judul',
                                      hintText: 'Contoh: Makan siang',
                                    ),
                                    validator: (v) =>
                                        (v?.trim().isEmpty ?? true)
                                        ? 'Judul wajib diisi.'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  InkWell(
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
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Tanggal',
                                        suffixIcon: WebIcon(
                                          Icons.calendar_today_outlined,
                                          size: 18,
                                        ),
                                      ),
                                      child: Text(dateLabel(_date)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _description,
                                    enabled: !_busy,
                                    decoration: const InputDecoration(
                                      labelText: 'Catatan (opsional)',
                                      hintText: 'Tambahkan catatan…',
                                    ),
                                    validator: (v) =>
                                        utf8.encode(v ?? '').length > 4000
                                        ? 'Deskripsi maksimal 4000 byte.'
                                        : null,
                                  ),
                                  const SizedBox(height: 24),
                                  BusyButton(
                                    busy: _busy,
                                    label: 'Simpan Transaksi',
                                    icon: Icons.check,
                                    onPressed: _save,
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: const Text('Batal'),
                                  ),
                                ],
                              ),
                            ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                _error!,
                                style: TextStyle(color: p.red),
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
  }

  Widget _amountKey(String key) {
    final p = WebPalette.of(context);
    final style = OutlinedButton.styleFrom(
      backgroundColor: key == 'del' ? p.sunken : p.elevated,
      foregroundColor: p.foreground,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: monoStyle(size: 22, weight: FontWeight.w600),
    );
    return key == 'del'
        ? Tooltip(
            message: 'Hapus angka',
            child: OutlinedButton(
              style: style,
              onPressed: () => _pressAmount(key),
              child: const WebIcon(
                Icons.backspace_outlined,
                size: 20,
                semanticLabel: 'Hapus angka',
              ),
            ),
          )
        : OutlinedButton(
            style: style,
            onPressed: () => _pressAmount(key),
            child: Text(key),
          );
  }
}
