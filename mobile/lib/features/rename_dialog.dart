import 'package:flutter/material.dart';
import '../core/models.dart';
import '../ui/motion.dart';

class RenameDialog extends StatefulWidget {
  const RenameDialog({super.key, required this.username});
  final String username;
  @override
  State<RenameDialog> createState() => _RenameDialogState();
}
class _RenameDialogState extends State<RenameDialog> {
  final _form = GlobalKey<FormState>();
  late final _field = TextEditingController(text: widget.username);
  int _failures = 0;
  @override
  void dispose() { _field.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Ubah username'),
    content: ShakeFeedback(trigger: _failures, child: Form(key: _form, child: TextFormField(controller: _field, autofocus: true,
      maxLength: 50, validator: validateUsername, decoration: const InputDecoration(labelText: 'Username')))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
      FilledButton(onPressed: () {
        if (_form.currentState!.validate()) { Navigator.pop(context, _field.text); }
        else { setState(() => _failures++); }
      }, child: const Text('Simpan')),
    ]);
}
