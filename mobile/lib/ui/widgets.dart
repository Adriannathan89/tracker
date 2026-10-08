import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import 'theme.dart';
import 'motion.dart';

final _rupiahFormatter = NumberFormat('#,##0.##', 'id_ID');
String rupiah(num value) => 'Rp ${_rupiahFormatter.format(value)}';
String dateLabel(DateTime date) => DateFormat('d MMM yyyy', 'id_ID').format(date);
String monthLabel(DateTime date) => DateFormat('MMMM yyyy', 'id_ID').format(date);
void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
Future<bool> confirm(BuildContext context, String title, String message) async =>
  await showDialog<bool>(context: context, builder: (context) => AlertDialog(
    title: Text(title), content: Text(message), actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lanjutkan')),
    ],
  )) ?? false;
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.controller, required this.children});
  final AppController controller;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: controller.reload,
    child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      physics: const AlwaysScrollableScrollPhysics(), children: [
        if (controller.loading) const Padding(key: ValueKey('loading'), padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator()),
        if (controller.error != null) ErrorCard(key: const ValueKey('error'), message: controller.error!, onRetry: controller.reload),
        for (var i = 0; i < children.length; i++)
          KeyedSubtree(key: ValueKey('content-$i'), child: children[i]),
      ]),
  );
}
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16),
    child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
      ]))));
}
class EmptyCard extends StatelessWidget {
  const EmptyCard({super.key, required this.title, required this.message, this.icon = Icons.receipt_long_outlined});
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(28),
    child: Column(children: [Icon(icon, size: 36), const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6), Text(message, textAlign: TextAlign.center),
    ])));
}
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
      if (action != null) action!]));
}
class StatCard extends StatelessWidget {
  const StatCard(this.label, this.value, {super.key, this.color});
  final String label;
  final double value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 8),
      AnimatedAmount(value: value, format: rupiah,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
    ])));
}
class RecordTile extends StatelessWidget {
  const RecordTile(this.record, {super.key, this.onTap});
  final TrackerRecord record;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Card(child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42, alignment: Alignment.center,
          decoration: BoxDecoration(color: lime.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Text(categoryEmoji[record.primary] ?? '📒', style: const TextStyle(fontSize: 22))),
        const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(record.title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4),
          Text('${dateLabel(record.date)} · ${record.primary}', style: Theme.of(context).textTheme.bodySmall),
          if (!record.isCommitted) const Padding(padding: EdgeInsets.only(top: 4),
            child: Text('Menunggu konfirmasi', style: TextStyle(color: Color(0xFFB28000), fontSize: 11))),
          const SizedBox(height: 6), Text('${record.type == 'income' ? '+' : '−'}${rupiah(record.amount)}',
              style: TextStyle(fontWeight: FontWeight.w800, color: record.type == 'income' ? incomeColor : expenseColor)),
        ])), const Icon(Icons.chevron_right, size: 20),
      ])))));
}
class BusyButton extends StatelessWidget {
  const BusyButton({super.key, required this.busy, required this.label, required this.onPressed});
  final bool busy;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity,
    child: FilledButton(onPressed: busy ? null : onPressed,
      child: AnimatedSwitcher(duration: TrackerMotion.duration(context, TrackerMotion.quick),
        child: busy ? const SizedBox(key: ValueKey('busy'), width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2)) : Text(label, key: ValueKey(label)))));
}
