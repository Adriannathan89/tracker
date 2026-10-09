import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import '../ui/widgets.dart';
import '../ui/motion.dart';
import '../ui/theme.dart';

class AddDebtSheet extends StatefulWidget {
  const AddDebtSheet({
    super.key,
    required this.controller,
    required this.friend,
  });
  final AppController controller;
  final Friend friend;
  @override
  State<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<AddDebtSheet> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(),
      _description = TextEditingController();
  bool _busy = false;
  String? _error;
  int _failures = 0;
  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
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
        'debt/create',
        body: {
          'amount': parseAmount(_amount.text),
          'description': _description.text.trim(),
          'debtorId': widget.friend.id,
        },
      );
      if (mounted) {
        Navigator.pop(context);
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
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: ShakeFeedback(
          trigger: _failures,
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CATAT HUTANG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: WebPalette.of(context).muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Piutang ke ${widget.friend.username}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: WebPalette.of(context).elevated,
                    border: Border.all(color: WebPalette.of(context).border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Nominal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: WebPalette.of(context).muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ValueListenableBuilder(
                        valueListenable: _amount,
                        builder: (context, value, _) => FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            rupiah(parseAmount(value.text) ?? 0),
                            style: monoStyle(size: 40, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final amount in [
                            10000,
                            25000,
                            50000,
                            100000,
                            250000,
                            500000,
                          ])
                            OutlinedButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      final next =
                                          (parseAmount(_amount.text) ?? 0) +
                                          amount;
                                      if (next < 1e15) {
                                        _amount.text = next.toStringAsFixed(
                                          next % 1 == 0 ? 0 : 2,
                                        );
                                      }
                                    },
                              child: Text(
                                '+${amount ~/ 1000}rb',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          TextButton(
                            onPressed: _busy ? null : _amount.clear,
                            child: Text(
                              'Hapus',
                              style: TextStyle(
                                color: WebPalette.of(context).red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _amount,
                  enabled: !_busy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah piutang (Rp)',
                  ),
                  validator: (v) => parseAmount(v ?? '') == null
                      ? 'Jumlah harus positif, maksimal 2 desimal (tanpa pemisah ribuan).'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  enabled: !_busy,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Untuk apa?'),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Deskripsi wajib diisi.'
                      : utf8.encode(v!).length > 4000
                      ? 'Deskripsi maksimal 4000 byte.'
                      : null,
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
                  label: 'Simpan piutang',
                  onPressed: _save,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
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
